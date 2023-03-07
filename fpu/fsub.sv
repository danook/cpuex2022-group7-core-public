`default_nettype none

module fsub
(input wire [31:0] x1,
input wire  [31:0] x2,
output wire [31:0] y,
input wire         clk);

//1.
   wire s1, s2;
   wire [7:0] e1, e2;
   wire [22:0] m1, m2;
   assign {s1,e1,m1} = x1;
   assign {s2,e2,m2} = {~x2[31],x2[30:0]};
//2.
   wire [7:0] e1a, e2a;
   wire [24:0] m1a, m2a; //省略ビットを再生した仮数
   assign {e1a,m1a} = (e1=='0) ? {8'b1,2'b0,m1} : {e1,2'b1,m1};
   assign {e2a,m2a} = (e2=='0) ? {8'b1,2'b0,m2} : {e2,2'b1,m2};
//4.
   wire signed [7:0] e2ai;
   assign e2ai = 8'b11111111 - e2a;
//5.
   wire signed [8:0] te; //指数の差
   assign te = {1'b0,e1a} + {1'b0,e2ai};
//6.
   wire ce; //e1>e2なら0
   wire [7:0] tde; //指数の差の絶対値
   wire signed [7:0] te_plus;
   assign te_plus = te[7:0] + 8'b1;
   assign {ce,tde} = (te[8]) ? {1'b0,te_plus[7:0]} : {1'b1,~te[7:0]};
//7.
   wire [4:0] de; //指数の差の絶対値を下位5bitに制限
   assign de = (|(tde[7:5])) ? 5'b11111 : tde[4:0];
//8.
   wire sel; //指数が等しければ、仮数を比較し、x1が大きければ0
   assign sel = (de=='0) ? ((m1a > m2a) ? 1'b0 : 1'b1) : ce;
//9.絶対値が大きいほうをsに、小さいほうをiにする
   wire [24:0] ms, mi;
   wire [7:0]  es;
   wire ss;
   assign {ms,mi,es,ss} = (sel==1'b0) ? {m1a,m2a,e1a,s1} : {m2a,m1a,e2a,s2};


   reg s1_reg, s2_reg;
   reg [4:0] de_reg;
   reg [24:0] ms_reg, mi_reg;
   reg [7:0] es_reg;
   reg ss_reg;
   always @(posedge clk) begin
      s1_reg <= s1;
      s2_reg <= s2;
      de_reg <= de;
      ms_reg <= ms;
      mi_reg <= mi;
      ss_reg <= ss;
      es_reg <= es;
   end


//10.
   wire [55:0] mie; //小さいほうの値をシフトする準備
   assign mie = {mi_reg,31'b0};
//11.仮数をシフト
   wire [55:0] mia;
   assign mia = mie >> de_reg;
//12.絶対値が小さいほうの値をシフトした結果、0となったらtstckは0
   wire tstck;
   assign tstck = |(mia[28:0]);
//14.
   wire [7:0] esi;
   assign esi = es_reg + 8'd1;
   wire seq;
   assign seq = (s1_reg==s2_reg);
//13.
   wire [26:0] mye;
   assign mye = (seq) ? {ms_reg,2'b0}+mia[55:29] : {ms_reg,2'b0}-mia[55:29];


   reg s1_reg2, s2_reg2;
   reg seq_reg;
   reg ss_reg2;
   reg [7:0] esi_reg, es_reg2;
   reg tstck_reg;
   reg [26:0] mye_reg;
   always @(posedge clk) begin
      s1_reg2 <= s1_reg;
      s2_reg2 <= s2_reg;
      seq_reg <= seq;
      ss_reg2 <= ss_reg;
      esi_reg <= esi;
      es_reg2 <= es_reg;
      tstck_reg <= tstck;
      mye_reg <= mye;
   end

//15.
   wire [7:0] eyd;
   wire [26:0] myd;
   wire stck;
   assign {eyd,myd,stck} = (mye_reg[26]) ? {esi_reg,mye_reg>>1'b1,(tstck_reg||mye_reg[0])} : {es_reg2,mye_reg,tstck_reg};
//16.
   wire [4:0] se; //2分探索？
   assign se = myd[25] ? 5'b00000 :
               myd[24] ? 5'b00001 :
               myd[23] ? 5'b00010 :
               myd[22] ? 5'b00011 :
               myd[21] ? 5'b00100 :
               myd[20] ? 5'b00101 :
               myd[19] ? 5'b00110 :
               myd[18] ? 5'b00111 :
               myd[17] ? 5'b01000 :
               myd[16] ? 5'b01001 :
               myd[15] ? 5'b01010 :
               myd[14] ? 5'b01011 :
               myd[13] ? 5'b01100 :
               myd[12] ? 5'b01101 :
               myd[11] ? 5'b01110 :
               myd[10] ? 5'b01111 :
               myd[9]  ? 5'b10000 :
               myd[8]  ? 5'b10001 :
               myd[7]  ? 5'b10010 :
               myd[6]  ? 5'b10011 :
               myd[5]  ? 5'b10100 :
               myd[4]  ? 5'b10101 :
               myd[3]  ? 5'b10110 :
               myd[2]  ? 5'b10111 :
               myd[1]  ? 5'b11000 :
               myd[0]  ? 5'b11001 : 5'b11010;


   reg s1_reg3, s2_reg3;
   reg seq_reg2;
   reg ss_reg3;
   reg stck_reg;
   reg [7:0]   eyd_reg;
   reg [26:0]  myd_reg;
   reg [4:0]   se_reg;
   always @(posedge clk) begin
      s1_reg3 <= s1_reg2;
      s2_reg3 <= s2_reg2;
      seq_reg2 <= seq_reg;
      ss_reg3 <= ss_reg2;
      stck_reg <= stck;
      eyd_reg <= eyd;
      myd_reg <= myd;
      se_reg <= se;
   end


//17.
   wire signed [8:0] eyf;
   wire              egz;
   assign eyf = {1'b0,eyd_reg} - {4'b0,se_reg};
   assign egz = eyf>9'sb0;
//18.
   wire [7:0] eyr;
   wire [26:0] myf;
   assign {myf,eyr} = (egz) ? {myd_reg<<se_reg,eyf[7:0]} : {myd_reg<<(eyd_reg[4:0]-5'b1),8'b0};


   reg s1_reg4, s2_reg4;
   reg ss_reg4;
   reg [7:0]   eyr_reg;
   reg [26:0]  myf_reg;
   reg stck_reg2;
   reg seq_reg3;
   always @(posedge clk) begin
      s1_reg4 <= s1_reg3;
      s2_reg4 <= s2_reg3;
      ss_reg4 <= ss_reg3;
      eyr_reg <= eyr;
      myf_reg <= myf;
      stck_reg2 <= stck_reg;
      seq_reg3 <= seq_reg2;
   end


//19.
   wire [24:0] myr;
   assign myr = ((myf_reg[2:0]==3'b110&&stck_reg2==1'b0)
               ||(myf_reg[1:0]==2'b10&&seq_reg3&&stck_reg2==1'b1)
               ||(myf_reg[1:0]==2'b11)) ? myf_reg[26:2]+25'b1 : myf_reg[26:2];
//20.
   wire [7:0] eyri;
   assign eyri = eyr_reg + 8'b1;
//21.
   wire sy;
   wire [7:0] ey;
   wire [22:0] my;
   assign {ey,my} = (myr[24]) ? {eyri,23'b0} : (myr[23:0]=='0) ? '0 : {eyr_reg,myr[22:0]};
   assign sy = ({ey,my}=='0) ? s1_reg4&&s2_reg4 : ss_reg4;
//23.
   assign y = {sy,ey,my};

endmodule

`default_nettype wire
