`default_nettype none

module fhalf  (input wire  [31:0] x,
               output wire [31:0] y,
               input wire clk);

//1.
   wire s;
   wire [7:0] e;
   wire [22:0] m;
   assign {s,e,m} = x;

   assign y = (e=='0) ? '0 : {s,e-8'b1,m};

endmodule

`default_nettype wire
