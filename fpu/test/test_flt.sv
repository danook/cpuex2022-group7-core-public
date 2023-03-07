`timescale 1ns / 100ps
`default_nettype none

module test_flt();
   wire [31:0] x1,x2;
   wire       y;
   logic [31:0] x1i,x2i;
   shortreal    fx1,fx2;
   logic  fy;
   int          i,j,k,it,jt;
   bit [22:0]   m1,m2;
   bit [9:0]    dum1,dum2;
   logic        fybit;
   int          s1,s2;
   logic [23:0] dy;
   bit [22:0] tm;

   logic           clk;


   assign x1 = x1i;
   assign x2 = x2i;

   flt u1(x1,x2,y);

   initial begin
      // $dumpfile("test_flt.vcd");
      // $dumpvars(0);

      $display("start of checking module flt");
      $display("difference message format");
      $display("x1 = [input 1(bit)], [exponent 1(decimal)]");
      $display("x2 = [input 2(bit)], [exponent 2(decimal)]");
      $display("ref. : result(float) sign(bit),exponent(decimal),mantissa(bit) overflow(bit)");
      $display("flt : result(float) sign(bit),exponent(decimal),mantissa(bit) overflow(bit)");

      for (i=0; i<255; i++) begin
         for (j=0; j<255; j++) begin
            for (s1=0; s1<2; s1++) begin
               for (s2=0; s2<2; s2++) begin
                  for (it=0; it<10; it++) begin
                     for (jt=0; jt<10; jt++) begin

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

                        case (jt)
                           0 : m2 = 23'b0;
                           1 : m2 = {22'b0,1'b1};
                           2 : m2 = {21'b0,2'b10};
                           3 : m2 = {1'b0,3'b111,19'b0};
                           4 : m2 = {1'b1,22'b0};
                           5 : m2 = {2'b10,{21{1'b1}}};
                           6 : m2 = {23{1'b1}};
                           default : begin
                                 {m2,dum2} = $urandom();
                           end
                        endcase

                        x1i = {s1[0],i[7:0],m1};
                        x2i = {s2[0],j[7:0],m2};

                        fx1 = $bitstoshortreal(x1i);
                        fx2 = $bitstoshortreal(x2i);
                        fy = (fx1 < fx2);

                        #2;

                        if (y !== fy) begin
                           $display("x1 = %b %b %b, %3d",x1[31], x1[30:23], x1[22:0], x1[30:23]);
                           $display("x2 = %b %b %b, %3d",x2[31], x2[30:23], x2[22:0], x2[30:23]);
                           $display("%b\n", fy);
                           $display("%b\n", y);
                        end
                     end
                  end
               end
            end
         end
      end


      for (i=0; i<255; i++) begin
         for (s1=0; s1<2; s1++) begin
            for (s2=0; s2<2; s2++) begin
               for (j=0;j<23;j++) begin
                  repeat(10) begin

                     {m1,dum1} = $urandom();
                     x1i = {s1[0],i[7:0],m1};
                     {m2,dum2} = $urandom();
                     for (k=0;k<j;k++) begin
                        tm[k] = m2[k];
                     end
                     for (k=j;k<23;k++) begin
                        tm[k] = m1[k];
                     end
                     x2i = {s2[0],i[7:0],tm};

                     fx1 = $bitstoshortreal(x1i);
                     fx2 = $bitstoshortreal(x2i);
                     fy = (fx1 < fx2);

                     #2;

                     if (y !== fy) begin
                        $display("x1 = %b %b %b, %3d",x1[31], x1[30:23], x1[22:0], x1[30:23]);
                        $display("x2 = %b %b %b, %3d",x2[31], x2[30:23], x2[22:0], x2[30:23]);
                        $display("%b\n", fy);
                        $display("%b\n", y);
                     end
                  end
               end
            end
         end
      end
      $display("end of checking module flt");
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
