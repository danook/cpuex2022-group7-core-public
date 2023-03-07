`default_nettype none

module fsqrt (input wire  [31:0] x,
              output wire [31:0] y,
              input wire clk);

   (* ram_style="block" *) logic [31:0] mem [2047:0];

initial begin
   $readmemb("D:/cpuex/core/fpu/fsqrt_table.txt", mem);
end

//1.
   wire s;
   wire [7:0] e;
   wire [22:0] m;
   assign {s,e,m} = x;

//2. メモリ読み出し
   wire [9:0] h; //上位10ビット切り出し
   wire [10:0] addr;
   wire [10:0] addri;
   assign h = {~e[0], m[22:14]};
   assign addr = {h, 1'b0};
   assign addri = {h, 1'b1};

   wire [31:0] mn;
   assign mn = (e[0]==1'b0) ? {1'b0, 8'd128, m} : {1'b0, 8'd127, m};

   reg s_reg;
   reg [7:0] e_reg;
   reg [31:0] mn_reg;
   reg [31:0]   grad;
   reg [31:0]   slice;
   always @(posedge clk) begin
      s_reg <= s;
      e_reg <= e;
      mn_reg <= mn;
      grad <= mem[addr];
      slice <= mem[addri];
   end


//3.
   wire [31:0] ax;
   fmul u1(grad, mn_reg, ax, clk);
   wire [7:0]  esqrt;
   assign esqrt = (e_reg-8'd127)/2 + 8'd127;

   reg s_reg2;
   reg [7:0] e_reg2;
   reg [31:0] slice2;
   always @(posedge clk) begin
      s_reg2 <= s_reg;
      e_reg2 <= esqrt;
      slice2 <= slice;
   end

   reg s_reg3;
   reg [7:0] e_reg3;
   reg [31:0] slice3;
   reg [31:0]  ax_reg;
   always @(posedge clk) begin
      s_reg3 <= s_reg2;
      e_reg3 <= e_reg2;
      slice3 <= slice2;
      ax_reg <= ax;
   end


   wire [31:0] msqrt;
   fadd u2(slice3, ax_reg, msqrt, clk);

   reg s_reg4;
   reg [7:0] e_reg4;
   always @(posedge clk) begin
      s_reg4 <= s_reg3;
      e_reg4 <= e_reg3;
   end

   reg s_reg5;
   reg [7:0] e_reg5;
   always @(posedge clk) begin
      s_reg5 <= s_reg4;
      e_reg5 <= e_reg4;
   end

   reg s_reg6;
   reg [7:0] e_reg6;
   always @(posedge clk) begin
      s_reg6 <= s_reg5;
      e_reg6 <= e_reg5;
   end

   reg s_reg7;
   reg [7:0] e_reg7;
   always @(posedge clk) begin
      s_reg7 <= s_reg6;
      e_reg7 <= e_reg6;
   end


//4.
   assign y = {s_reg7,e_reg7,msqrt[22:0]};

endmodule

`default_nettype wire
