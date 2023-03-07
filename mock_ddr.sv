`default_nettype none

module mock_ddr #(
        parameter INIT_FILE = "D:/cpuex/core/memory_init.txt",
        parameter MEMSIZE   = utils::HEAP_SIZE
    ) (
        input wire              clk,
        input wire              rstn,
        input utils::mem_req_t  mem_req,    // NOTE: Address is byte-addressing
        output utils::mem_res_t mem_res
    );

    (* ram_style = "block" *) logic [31:0] RAM[0:MEMSIZE - 1];

    localparam CYCLES = 2;

    logic [2:0]     counter;
    /* verilator lint_off UNUSED */
    logic [31:0]    mem_req_addr_reg;
    /* verilator lint_on UNUSED */
    logic [31:0]    mem_req_data_reg;
    logic           mem_req_rw_reg;

    initial begin
        // 実際のメモリの挙動を再現するため、あえて0初期化はしないでおく
        if (utils::USE_MEM_INIT_FILE) begin
            $readmemh(INIT_FILE, RAM);
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            counter <= 0;
        end else begin
            if (counter > 0) begin
                counter <= counter - 1;
                // counter == 2でreadyを上げ、counter == 1でコアがそれを認知し、
                // counter == 0でvalidを下げる
                if (counter == 2) begin
                    if (mem_req_rw_reg) begin
                        RAM[mem_req_addr_reg] <= mem_req_data_reg;
                    end else begin
                        mem_res.data <= RAM[mem_req_addr_reg];
                    end
                    mem_res.ready <= 1'b1;
                end
            end else if (mem_req.valid) begin
                mem_req_addr_reg <= {2'b0, mem_req.addr[31:2]}; // mem_req is byte-addressing
                mem_req_data_reg <= mem_req.data;
                mem_req_rw_reg <= mem_req.rw;
                counter <= CYCLES;
            end

            if (mem_res.ready) begin
                // すぐ下ろす
                mem_res.ready <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire