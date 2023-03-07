`default_nettype none

module bram #(
        parameter INIT_FILE = "D:/cpuex/core/memory_init.txt",
        parameter WIDTH     = 32,
        parameter MEMSIZE   = 128
    ) (
        input wire                  clk,
        input wire                  rstn,
        input utils::bram_wreq_t    mem_wreq,   // NOTE: Address is word-addressing
        /* verilator lint_off UNUSED */
        input wire [31:0]           read_addr,
        /* verilator lint_on UNUSED */
        output logic [WIDTH - 1:0]  read_data
    );

    integer i;
    (* ram_style = "block" *) logic [WIDTH - 1:0] RAM[0:MEMSIZE - 1];

    // 読み出しと書き込みが同一アドレスに同時に行われた場合、読み出しデータは最新のものではないので、
    // これを立てて、wdata_regで代用する
    logic [WIDTH - 1:0] rdata_reg;
    logic read_data_is_outdated;
    logic [WIDTH - 1:0] wdata_reg;

    assign read_data = read_data_is_outdated ? wdata_reg : rdata_reg;

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
            rdata_reg <= RAM[read_addr];
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            read_data_is_outdated <= 1'b0;
            wdata_reg <= '0;
        end else begin
            read_data_is_outdated <= mem_wreq.wenable & (mem_wreq.waddr == read_addr);
            wdata_reg <= mem_wreq.wdata[WIDTH - 1:0];
        end
    end
endmodule

`default_nettype wire