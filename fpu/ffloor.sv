`default_nettype none

module ffloor (input wire [31:0] x,
              output wire [31:0] y,
              input wire clk);

  wire signed [31:0] xint;
  fcvtws u1(x, xint, clk);

  reg [31:0] x_reg;
  always @(posedge clk) begin
    x_reg <= x;
  end

  wire signed [31:0] xint_dec;
  assign xint_dec = xint - 32'b1;

  reg [31:0] x_reg2;
  reg [31:0] xint_reg, xint_dec_reg;
  always @(posedge clk) begin
    x_reg2 <= x_reg;
    xint_reg <= xint;
    xint_dec_reg <= xint_dec;
  end


  wire [31:0] xfloat;
  wire [31:0] xfloat_dec;
  fcvtsw u2(xint_reg, xfloat, clk);
  fcvtsw u3(xint_dec_reg, xfloat_dec, clk);


  reg [31:0] x_reg3;
  always @(posedge clk) begin
    x_reg3 <= x_reg2;
  end


  reg [31:0] x_reg4;
  always @(posedge clk) begin
    x_reg4 <= x_reg3;
  end

  reg [31:0] x_reg5;
  always @(posedge clk) begin
    x_reg5 <= x_reg4;
  end

  reg [31:0] x_reg6, xfloat_reg, xfloat_dec_reg;
  always @(posedge clk) begin
    x_reg6 <= x_reg5;
    xfloat_reg <= xfloat;
    xfloat_dec_reg <= xfloat_dec;
  end


  wire flag;
  flt u4(x_reg6, xfloat_reg, flag);


  reg flag_reg;
  reg [31:0] x_reg7, xfloat_reg2, xfloat_dec_reg2;
  always @(posedge clk) begin
    flag_reg <= flag;
    x_reg7 <= x_reg6;
    xfloat_reg2 <= xfloat_reg;
    xfloat_dec_reg2 <= xfloat_dec_reg;
  end


  assign y =  (x_reg7[30:23]>8'd157) ? x_reg7 :
              (flag_reg) ? xfloat_dec_reg2 : xfloat_reg2;

endmodule

`default_nettype wire
