`default_nettype none

module fmsub
(input wire [31:0] x1,
input wire  [31:0] x2,
input wire  [31:0] x3,
output wire [31:0] y,
input wire         clk);

   wire [31:0] y1;
   fmul u1(x1,x2,y1,clk);

   reg [31:0] x3_reg;
   always @(posedge clk) begin
      x3_reg <= x3;
   end

   reg [31:0] x3_reg2;
   reg [31:0] y1_reg;
   always @(posedge clk) begin
      x3_reg2 <= x3_reg;
      y1_reg <= y1;
   end

   fsub u2(y1_reg,x3_reg2,y,clk);


endmodule

`default_nettype wire
