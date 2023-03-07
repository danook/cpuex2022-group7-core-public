`timescale 1ns / 100ps
`default_nettype none

module test_fcvtws();
   wire [31:0] x1;
   wire signed [31:0] y;
   logic [31:0] x1i;
   shortreal    fx1;
   int fy;
   int          i,k,it;
   bit [22:0]   m1;
   bit [9:0]    dum1;
   logic [31:0] fybit;
   int          s1;
   logic [23:0] dy;
   bit [22:0] tm;

   logic            clk;


   assign x1 = x1i;

   fcvtws u1(x1,y,clk);

   initial begin
      // $dumpfile("test_fcvtws.vcd");
      // $dumpvars(0);

      $display("start of checking module fcvtws");
      $display("difference message format");
      $display("x1 = [input 1(bit)], [exponent 1(decimal)]");
      $display("ref. : result(float) sign(bit),exponent(decimal),mantissa(bit) overflow(bit)");
      $display("fcvtws : result(float) sign(bit),exponent(decimal),mantissa(bit) overflow(bit)");

      for (i=0; i<158; i++) begin
         for (s1=0; s1<2; s1++) begin
            for (it=0; it<10; it++) begin

               case (it)
                  0 : m1 = 23'b0;
                  1 : m1 = {22'b0,1'b1};
                  2 : m1 = {21'b0,2'b10};
                  3 : m1 = {1'b0,3'b111,19'b0};
                  4 : m1 = {1'b1,22'b0};
                  5 : m1 = {2'b10,{21{1'b1}}};
                  6 : m1 = {23{1'b1}};
                  default : begin
                     if (i==256) begin
                        {m1,dum1} = 0;
                     end else begin
                        {m1,dum1} = $urandom();
                     end
                  end
               endcase

               x1i = {s1[0],i[7:0],m1};

               fx1 = $bitstoshortreal(x1i);
               fy = $rtoi(fx1);

               #4;

               if (fy!==y) begin
                  $display("x1 = %b %b %b, %3d",x1[31], x1[30:23], x1[22:0], x1[30:23]);
                  $display("true  = %d %b", fy, fy);
                  $display("false = %d %b\n", y, y);
               end
            end
         end

      end

      $display("end of checking module fcvtws");
      $finish;
   end

   always begin
         clk = 0;
      #1 clk = 1;
      #1;
   end


endmodule

`default_nettype wire
