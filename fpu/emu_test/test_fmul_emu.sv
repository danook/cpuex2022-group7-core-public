`timescale 1ns / 100ps
`default_nettype none

module test_fmul_emu();
  wire [31:0] x1,x2,y;
  logic [31:0] x1_reg,x2_reg;
  logic [31:0] y_emu;
  logic           clk;
  integer fp;

  assign x1 = x1_reg;
  assign x2 = x2_reg;
  fmul u1(x1,x2,y,clk);

  initial begin
    $display("start of checking fmul emulator");
    $display("difference message format");
    $display("x1 = [input 1(bit)]");
    $display("x2 = [input 2(bit)]");
    $display("emu. : result(bit)");
    $display("fmul : result(bit)");

    fp = $fopen("D:/cpuex/core/fpu/emu_test/fmul_emu.txt", "r");

    for (int i=0; i<5476; i++) begin
      $fscanf(fp, "%b", x1_reg);
      $fscanf(fp, "%b", x2_reg);
      $fscanf(fp, "%b", y_emu);

      #4;

      if (y_emu !== y) begin
        $display("x1 = %b", x1);
        $display("x2 = %b", x2);
        $display("emu =  %b", y_emu);
        $display("fmul = %b\n", y);
      end
      end
      $display("end of checking fmul emulator");
      $fclose(fp);
      $finish;
  end

  always begin
    clk <= 1;
    #1;
    clk <= 0;
    #1;
  end

endmodule

`default_nettype wire
