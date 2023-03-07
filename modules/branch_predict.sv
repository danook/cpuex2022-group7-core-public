`default_nettype none

module branch_predict (
        input wire          clk,
        input wire          rstn,
        input wire          stall,
        /* verilator lint_off UNUSED */
        input wire [15:0]   pc_IF,
        input wire [15:0]   pc_EX,
        /* verilator lint_on UNUSED */
        output logic        branch_predict_ID,
        input wire          branch_EX,
        input wire          branch_result_EX
    );

    logic [9:0]        ram_waddr;
    logic [1:0]         ram_wdata;
    logic               ram_wenable;
    logic [9:0]        ram_raddr;
    logic [1:0]         ram_rdata;

    logic [1:0]         predict_state_ID, predict_state_EX;
    assign branch_predict_ID    = predict_state_ID[1];
    assign predict_state_ID     = ram_rdata;
    always @(posedge clk) begin
        predict_state_EX <= stall ? predict_state_EX : predict_state_ID;
    end

    assign ram_waddr        = pc_EX[5:0];
    assign ram_wdata        = branch_result_EX ? 
        (predict_state_EX == 2'b11 ? 2'b11 : predict_state_EX + 2'b01) :
        (predict_state_EX == 2'b00 ? 2'b00 : predict_state_EX - 2'b01);
    assign ram_wenable      = branch_EX;
    assign ram_raddr        = pc_IF[5:0];

    // RAM
    integer i;
    logic [1:0] RAM[0:63];
    initial begin
        for (i = 0; i < 64; i++) begin
            RAM[i] = 2'b10;
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            ram_rdata <= '0;
        end else begin
            if (ram_wenable) begin
                RAM[ram_waddr] <= ram_wdata;
            end
            ram_rdata <= RAM[ram_raddr];
        end
    end

endmodule