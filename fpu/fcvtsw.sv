`default_nettype none

module fcvtsw (input wire signed [31:0] x,
               output wire [31:0] y,
               input wire clk);


//1.
   wire s;
   wire [31:0]  xabs;
   assign s = x[31];
   assign xabs = (s==0) ? x : ~x+32'b1;

   reg s_reg;
   reg [31:0] xabs_reg;
   always @(posedge clk) begin
      s_reg <= s;
      xabs_reg <= xabs;
   end

//2.
   wire [5:0] sa; //shift amount
   assign sa = (xabs_reg[31]) ? 6'd1 :
               (xabs_reg[30]) ? 6'd2 :
               (xabs_reg[29]) ? 6'd3 :
               (xabs_reg[28]) ? 6'd4 :
               (xabs_reg[27]) ? 6'd5 :
               (xabs_reg[26]) ? 6'd6 :
               (xabs_reg[25]) ? 6'd7 :
               (xabs_reg[24]) ? 6'd8 :
               (xabs_reg[23]) ? 6'd9 :
               (xabs_reg[22]) ? 6'd10 :
               (xabs_reg[21]) ? 6'd11 :
               (xabs_reg[20]) ? 6'd12 :
               (xabs_reg[19]) ? 6'd13 :
               (xabs_reg[18]) ? 6'd14 :
               (xabs_reg[17]) ? 6'd15 :
               (xabs_reg[16]) ? 6'd16 :
               (xabs_reg[15]) ? 6'd17 :
               (xabs_reg[14]) ? 6'd18 :
               (xabs_reg[13]) ? 6'd19 :
               (xabs_reg[12]) ? 6'd20 :
               (xabs_reg[11]) ? 6'd21 :
               (xabs_reg[10]) ? 6'd22 :
               (xabs_reg[9]) ? 6'd23 :
               (xabs_reg[8]) ? 6'd24 :
               (xabs_reg[7]) ? 6'd25 :
               (xabs_reg[6]) ? 6'd26 :
               (xabs_reg[5]) ? 6'd27 :
               (xabs_reg[4]) ? 6'd28 :
               (xabs_reg[3]) ? 6'd29 :
               (xabs_reg[2]) ? 6'd30 :
               (xabs_reg[1]) ? 6'd31 :
               (xabs_reg[0]) ? 6'd32 : 6'd0;


   reg s_reg2;
   reg [31:0] xabs_reg2;
   reg [5:0] sa_reg;
   always @(posedge clk) begin
      s_reg2 <= s_reg;
      xabs_reg2 <= xabs_reg;
      sa_reg <= sa;
   end


//3.
   wire [31:0] xs;
   assign xs = xabs_reg2 << sa_reg;

//4.
   wire [22:0] my;
   wire rnd;
   assign rnd = xs[8];
   assign my = xs[31:9] + rnd;


   reg s_reg3;
   reg [5:0] sa_reg2;
   reg [22:0] xs_reg;
   reg rnd_reg;
   reg [22:0] my_reg;
   always @(posedge clk) begin
      s_reg3 <= s_reg2;
      sa_reg2 <= sa_reg;
      xs_reg <= xs[31:9];
      rnd_reg <= rnd;
      my_reg <= my;
   end


//5.
   wire sy;
   wire [7:0]  ey;
   assign sy = s_reg3;
   assign ey = (sa_reg2==8'd0) ? 8'd0 :
               (xs_reg=='1&&rnd_reg) ? 8'd160-{2'b0,sa_reg2} : 8'd159-{2'b0,sa_reg2};

   assign y = {sy,ey,my_reg};


endmodule

`default_nettype wire
