`default_nettype none

module fcvtws (input wire  [31:0] x,
               output wire signed [31:0] y,
               input wire clk);


//0.
   wire s;
   wire [7:0] e;
   wire [22:0] m;
   assign {s,e,m} = x;

//1.
   wire [30:0] me;
   assign me = {1'b1,m,7'b0};

//2.
   wire [7:0] sa; //shift amount
   wire [7:0] sai;
   wire [30:0] mes;
   wire [30:0] mesi;
   assign sa = 8'd157 - e;
   assign sai = sa - 1'b1;
   assign mes = me >> sa;
   assign mesi = me >> sai;


   reg mesi_reg;
   reg [30:0] mes_reg;
   reg s_reg;
   always @(posedge clk) begin
      mesi_reg <= mesi[0];
      mes_reg <= mes;
      s_reg <= s;
   end


//3.
   wire rnd;
   wire [30:0] mesr;
   assign rnd = mesi_reg;
   assign mesr = (rnd==1) ? mes_reg+1'b1 : mes_reg;
   //丸め処理 : ここでは、0捨1入による丸めを行っている
   //IEEE754は最近接丸めなので、それとは異なる

//4.
   wire [31:0] mesrc;
   assign mesrc = ~{1'b0,mesr} + 1'b1;
   assign y = (s_reg==0) ? $signed({1'b0,mesr}) : $signed(mesrc);


endmodule

`default_nettype wire
