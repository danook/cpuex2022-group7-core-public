`default_nettype none

module inst_mem #(
        parameter INIT_FILE = "D:/cpuex/core/memory_init.txt",
        parameter WIDTH     = 32,
        parameter MEMSIZE   = 128
    ) (
        input wire                  clk,
        input wire                  rstn,
        input utils::bram_wreq_t    mem_wreq,   // NOTE: Address is word-addressing
        // これが立った時以外は新たに読み出さずに前の結果を保持する
        input wire                  read_enable,
        /* verilator lint_off UNUSED */
        input wire [31:0]           read_addr,
        /* verilator lint_on UNUSED */
        output logic [WIDTH - 1:0]  read_data
    );

    integer i;
    logic [WIDTH - 1:0] rdata_reg;
    (* ram_style = "block" *) logic [WIDTH - 1:0] RAM[0:MEMSIZE - 1];

    assign read_data = rdata_reg;

    initial begin
        if (utils::USE_MEM_INIT_FILE) begin
            $readmemh(INIT_FILE, RAM);
        end else begin
            for (i = 0; i < MEMSIZE; i++) begin
                RAM[i] = 0;
            end
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            rdata_reg <= '0;
        end else begin
            if (mem_wreq.wenable) begin
                RAM[mem_wreq.waddr] <= mem_wreq.wdata[WIDTH - 1:0];
            end
            if (read_enable) begin
                rdata_reg <= RAM[read_addr];
            end
        end
    end
endmodule

`default_nettype wire