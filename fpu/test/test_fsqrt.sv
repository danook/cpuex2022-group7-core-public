`timescale 1ns / 100ps
`default_nettype none

module test_fsqrt();
   wire [31:0] x1,y;
   logic [31:0] x1i;
   shortreal    fx1,fy;
   int          i,k,it;
   bit [22:0]   m1;
   bit [9:0]    dum1;
   logic [31:0] fybit;
   int          s1;
   logic [23:0] dy;
   bit [22:0] tm;

   logic            clk;


   assign x1 = x1i;

   fsqrt u1(x1,y,clk);

   initial begin
      // $dumpfile("test_fsqrt.vcd");
      // $dumpvars(0);

      $display("start of checking module fsqrt");
      $display("difference message format");
      $display("x1 = [input 1(bit)], [exponent 1(decimal)]");
      $display("ref. : result(float) sign(bit),exponent(decimal),mantissa(bit) overflow(bit)");
      $display("fsqrt : result(float) sign(bit),exponent(decimal),mantissa(bit) overflow(bit)");

      for (i=1; i<254; i++) begin
         for (s1=0; s1<1; s1++) begin
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
                        {m1,dum1} = $urandom();
                  end
               endcase

               x1i = {s1[0],i[7:0],m1};

               fx1 = $bitstoshortreal(x1i);
               fy = $sqrt(fx1);
               fybit = $shortrealtobits(fy);

               #16;

               if ((fybit[30:23]=='0 && y[30:23]!=='0)
                  ||(fybit[30:23]!=='0 && fybit[30:23]!=='1
                     && y!==fybit && y!==fybit+1'b1 && y!==fybit-1'b1)) begin
                  $display("x1 = %b %b %b, %3d",x1[31], x1[30:23], x1[22:0], x1[30:23]);
                  $display("%e %b,%3d,%b", fy,fybit[31], fybit[30:23], fybit[22:0]);
                  $display("%e %b,%3d,%b\n", $bitstoshortreal(y),y[31], y[30:23], y[22:0]);
               end
            end
         end

      end

      $display("end of checking module fsqrt");
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
