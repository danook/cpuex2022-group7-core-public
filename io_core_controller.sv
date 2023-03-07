`default_nettype none

module io_core_controller (
        input wire  clk,
        input wire  rstn,
        input wire  rxd,
        output wire txd,
        // DDR2
        /* verilator lint_off UNDRIVEN */
        output wire [12:0]  ddr2_addr,
        output wire [2:0]   ddr2_ba,
        output wire	        ddr2_cas_n,
        output wire [0:0]   ddr2_ck_n,
        output wire [0:0]   ddr2_ck_p,
        output wire [0:0]   ddr2_cke,
        output wire	        ddr2_ras_n,
        output wire	        ddr2_we_n,
        inout wire [15:0]   ddr2_dq,
        inout wire [1:0]    ddr2_dqs_n,
        inout wire [1:0]    ddr2_dqs_p,
        output wire [0:0]   ddr2_cs_n,
        output wire [1:0]   ddr2_dm,
        output wire [0:0]   ddr2_odt
        /* verilator lint_on UNDRIVEN */
    );

    localparam SIG_SEND_PROG    = 8'h99;
    localparam SIG_SEND_DATA    = 8'haa;

    localparam TX_MODE_SIG      = 1'b1;
    localparam TX_MODE_DMA      = 1'b0;

    enum logic [1:0] {
        INIT,
        PROG_RECV,
        EXECUTE
    } state;

    logic               read_input;
    logic               read_input_done;
    logic               input_stall;
    logic [31:0]        input_rdata;
    logic               write_output;
    logic               output_stall;
    logic [7:0]         output_data;

    utils::bram_wreq_t  inst_mem_wreq;
    logic               inst_mem_renable; 
    logic [31:0]        inst_mem_raddr;
    logic [31:0]        inst_mem_rdata;

    utils::mem_req_t ddr_req;
    utils::mem_res_t ddr_res;

    utils::bram_wreq_t  stack_wreq;
    logic [31:0]        stack_raddr;
    logic [31:0]        stack_rdata;

    utils::bram_wreq_t  bram_wreq_core, bram_wreq_input;
    logic [31:0]        bram_raddr;
    logic [31:0]        bram_rdata;

    logic       prog_recv_done;
    logic       tx_mode;
    logic [7:0] tx_signal;
    logic       tx_start;
    logic       ex_start;

    logic       cpu_clk;
    /* verilator lint_off UNUSED */
    logic       mig_clk;
    /* verilator lint_on UNUSED */
    logic       locked;
    logic	    sys_rstn;

    inst_mem #(
        .INIT_FILE(utils::INST_MEM_INIT_FILE),
        .MEMSIZE(utils::INST_MEM_SIZE)
    ) _inst_memory (
        cpu_clk,
        sys_rstn,
        inst_mem_wreq,
        inst_mem_renable,
        inst_mem_raddr,
        inst_mem_rdata
    );

    generate
    if (utils::USE_MOCK_DDR) begin
        assign cpu_clk  = clk;
        assign mig_clk  = clk;
        assign locked   = 1'b1;
        assign sys_rstn = rstn;

        mock_ddr #(
            .INIT_FILE(utils::DATA_MEM_INIT_FILE),
            .MEMSIZE(utils::HEAP_SIZE)
        ) _data_memory (
            cpu_clk,
            sys_rstn,
            ddr_req,
            ddr_res
        );
    end else begin
        /* verilator lint_off DECLFILENAME */
        clk_wiz_0 clk_gen (
            .clk_in1(clk),
            .clk_out1(mig_clk),
            .clk_out2(cpu_clk),
            .resetn(rstn),
            .locked(locked)
        );

        proc_sys_reset_0 rst_gen (
            .slowest_sync_clk(cpu_clk),
            .ext_reset_in(rstn),
            .dcm_locked(locked),
            .aux_reset_in(1'b1),
            .mb_debug_sys_rst(1'b0),
            .interconnect_aresetn(sys_rstn)
        );

        cache_top _data_memory (
            .*,
            .cpu_req(ddr_req),
            .cpu_res(ddr_res),
            .cpu_clk(cpu_clk),
            .mig_clk(mig_clk),
            .locked(locked),
            .sys_rst(sys_rstn)
        );
        /* verilator lint_on DECLFILENAME */
    end
    endgenerate

    bram #(
        .MEMSIZE(utils::STACK_SIZE)
    ) stack_mem (
        cpu_clk,
        sys_rstn,
        stack_wreq,
        stack_raddr,
        stack_rdata
    );

    bram #(
        .MEMSIZE(utils::BRAM_SIZE)
    ) bram_mem (
        cpu_clk,
        sys_rstn,
        state == PROG_RECV ? bram_wreq_input : bram_wreq_core,
        bram_raddr,
        bram_rdata
    );

    core _core (
        .clk(cpu_clk),
        .rstn(sys_rstn),
        .start(ex_start),
        .inst_mem_renable(inst_mem_renable),
        .inst_mem_raddr(inst_mem_raddr),
        .inst_mem_rdata(inst_mem_rdata),
        .ddr_req(ddr_req),
        .ddr_res(ddr_res),
        .stack_wreq(stack_wreq),
        .stack_raddr(stack_raddr),
        .stack_rdata(stack_rdata),
        .bram_wreq(bram_wreq_core),
        .bram_raddr(bram_raddr),
        .bram_rdata(bram_rdata),
        .read_input(read_input),
        .read_input_done(read_input_done),
        .input_stall(input_stall),
        .input_rdata(input_rdata),
        .write_output(write_output),
        .output_stall(output_stall),
        .output_data(output_data)
    );

    output_controller _output_controller (
        .clk(cpu_clk),
        .rstn(sys_rstn),
        .start(tx_start),
        .mode(tx_mode),
        .sendsig(tx_signal),
        .txd(txd),
        .write_output(write_output),
        .output_data(output_data),
        .stall(output_stall)
    );

    input_controller _input_controller (
        .clk(cpu_clk),
        .rstn(sys_rstn),
        .rxd(rxd),
        .prog_recv_done(prog_recv_done),
        .inst_mem_wreq(inst_mem_wreq),
        .bram_wreq(bram_wreq_input),
        .read_input(read_input),
        .read_input_done(read_input_done),
        .stall(input_stall),
        .input_buf_rdata(input_rdata)
    );

    always @(posedge cpu_clk) begin
        if (~sys_rstn) begin
            state <= INIT;
            tx_start <= 1'b0;
            ex_start <= 1'b0;
            tx_mode <= 1'b0;
            tx_signal <= 8'b0;
        end else begin
            // 有限状態機械で制御を行う
            case (state)
                INIT:
                if (locked) begin
                    tx_mode <= TX_MODE_SIG;
                    tx_start <= 1'b1;
                    tx_signal <= SIG_SEND_PROG;
                    state <= PROG_RECV;
                end

                PROG_RECV:
                if (prog_recv_done) begin
                    tx_mode <= TX_MODE_SIG;
                    tx_start <= 1'b1;
                    tx_signal <= SIG_SEND_DATA;
                    state <= EXECUTE;
                    ex_start <= 1'b1;
                end else if (tx_start == 1'b1) begin
                    tx_start <= 1'b0;
                end

                EXECUTE:
                begin
                    tx_start <= 1'b0;
                    tx_mode  <= TX_MODE_DMA;
                    ex_start <= 1'b0;
                end

                default:;
            endcase
        end
    end
endmodule

`default_nettype wire