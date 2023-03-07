`timescale 1ns / 100ps
`default_nettype none

module test_ffloor_emu();
  wire [31:0] x,y;
  logic [31:0] x_reg;
  logic [31:0] y_emu;
  logic           clk;
  integer fp;

  assign x = x_reg;
  ffloor u1(x,y,clk);

  initial begin
    $display("start of checking ffloor emulator");
    $display("difference message format");
    $display("x = [input (bit)]");
    $display("emu. : result(bit)");
    $display("ffloor : result(bit)");

    fp = $fopen("D:/cpuex/core/fpu/emu_test/ffloor_emu.txt", "r");

    for (int i=0; i<4100; i++) begin
      $fscanf(fp, "%b", x_reg);
      $fscanf(fp, "%b", y_emu);

      #16;

      if (y_emu !== y) begin
        $display("x1 = %b", x);
        $display("emu =  %b", y_emu);
        $display("ffloor = %b\n", y);
      end
      end
      $display("end of checking ffloor emulator");
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
