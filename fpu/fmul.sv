`default_nettype none

module fmul (input wire  [31:0] x1,
            input wire  [31:0] x2,
            output wire [31:0] y,
            input wire         clk);


//1.
   wire s1, s2; //入力の符号
   wire [7:0] e1, e2; //入力の指数
   wire [22:0] m1, m2;  //入力の仮数
   assign {s1,e1,m1} = x1;
   assign {s2,e2,m2} = x2;

   wire [12:0] h1, h2; //仮数の上位部
   wire [10:0] l1, l2; //仮数の下位部
   assign {h1,l1} = {1'b1,m1};
   assign {h2,l2} = {1'b1,m2};

//2.
   (*use_dsp="yes" *) wire [25:0] hh, hl, lh;
   assign hh = h1 * h2;
   assign hl = h1 * l2;
   assign lh = l1 * h2;

//3.
   wire [8:0] es;
   wire [8:0] e1e, e2e;
   assign e1e = {1'b0,e1};
   assign e2e = {1'b0,e2};
   assign es = e1e + e2e + 9'd129; //+129は-127に相当
   wire sy;
   assign sy = s1 ^ s2;

   wire flag1, flag2;
   assign flag1 = (e1==8'b0);
   assign flag2 = (e2==8'b0);
   wire [7:0]  esi; //仮数部の積で桁上げがあれば使う
   assign esi = es[7:0] + 1'b1;

   wire [25:0] hls, lhs;
   assign hls = hl>>11;
   assign lhs = lh>>11;


   reg [25:0] hh_reg, hl_reg, lh_reg;
   reg  flag1_reg, flag2_reg;
   reg [8:0] es_reg;
   reg [7:0] esi_reg;
   reg sy_reg;
   always @(posedge clk) begin
      hh_reg <= hh;
      hl_reg <= hls;
      lh_reg <= lhs;
      flag1_reg <= flag1;
      flag2_reg <= flag2;
      es_reg <= es;
      esi_reg <= esi;
      sy_reg <= sy;
   end

//4.
   (* use_dsp="yes" *) wire [25:0] mm;
   assign mm = hh_reg + hl_reg + lh_reg + 26'b10;

//5.
   wire [7:0] ey;
   assign ey = (flag1_reg || flag2_reg || ~es_reg[8]) ? 8'b0 :
               (mm[25]) ? esi_reg[7:0] : es_reg[7:0];

//6.
   wire [22:0] my;
   assign my = (ey==8'b0) ? 23'b0 :
               (mm[25]) ? mm[24:2] : mm[23:1];
   assign y = {sy_reg,ey,my};

endmodule

`default_nettype wire
