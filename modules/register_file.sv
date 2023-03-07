`default_nettype none

module register_file #(FPU = 0) (
        input wire          clk,
        input wire          rstn,
        input wire          write_enable,
        input wire [5:0]    read_addr1,
        input wire [5:0]    read_addr2,
        input wire [5:0]    read_addr3,
        input wire [5:0]    write_addr,
        input wire [31:0]   write_data,
        output wire [31:0]  read_data1,
        output wire [31:0]  read_data2,
        output wire [31:0]  read_data3
    );

    localparam REGSIZE  = 64;
    localparam ZERO     = 0;
    localparam FT1      = 1;
    localparam SP       = 2;
    localparam GP       = 3;
    localparam HP       = 4;

    localparam FT1_INIT = 'h3f800000;
    localparam SP_INIT  = utils::STACK_SIZE - 1;
    localparam GP_INIT  = 0;
    localparam HP_INIT  = utils::GLOBAL_SIZE;

    logic [31:0] regfile[0:REGSIZE - 1];

    assign read_data1 = regfile[read_addr1];
    assign read_data2 = regfile[read_addr2];
    assign read_data3 = regfile[read_addr3];

    integer i;
    always @(posedge clk) begin
        if (~rstn) begin
            for (i = 0; i < REGSIZE; i++) begin
                if (FPU) begin
                    if (i == FT1) begin
                        regfile[i] <= FT1_INIT;
                    end else begin
                        regfile[i] <= 0;
                    end
                end else begin
                    case (i)
                        SP: regfile[i] <= SP_INIT;
                        GP: regfile[i] <= GP_INIT;
                        HP: regfile[i] <= HP_INIT;
                        default: regfile[i] <= 0;
                    endcase
                end
            end
        end else begin
            // Ignore if rd is x0 (zero register)
            if (write_enable && write_addr != ZERO) begin
                regfile[write_addr] <= write_data;
            end
        end
    end
endmodule

`default_nettype wire