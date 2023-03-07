`default_nettype none

module fdiv (input wire  [31:0] x1,
            input wire   [31:0] x2,
            output wire  [31:0] y,
            input wire          clk);

   (* ram_style="block" *) logic [31:0] mem [2047:0];

   initial begin
      $readmemb("D:/cpuex/core/fpu/finv_table.txt", mem);
   end

//1.
   wire s1, s2;
   wire [7:0] e1, e2;
   wire [22:0] m1, m2;
   assign {s1,e1,m1} = x1;
   assign {s2,e2,m2} = x2;

//2.
   wire [9:0] h;
   wire [10:0] addr;
   wire [10:0] addri;
   assign h = m2[22:13];
   assign addr = {h, 1'b0};
   assign addri = {h, 1'b1};

   wire [31:0] m1n;
   wire [31:0] m2n;
   assign m1n = {1'b0, 8'd127, m1};
   assign m2n = {1'b0, 8'd127, m2};


   reg s1_reg, s2_reg;
   reg [7:0]   e1_reg, e2_reg;
   reg [31:0]  m1n_reg, m2n_reg;
   reg [31:0]  grad;
   reg [31:0]  slice;
   always @(posedge clk) begin
      s1_reg <= s1;
      s2_reg <= s2;
      e1_reg <= e1;
      e2_reg <= e2;
      m1n_reg <= m1n;
      m2n_reg <= m2n;
      grad <= mem[addr];
      slice <= mem[addri];
   end


//3.
   logic [31:0] ax;
   fmul u1(grad, m2n_reg, ax, clk);
   wire s;
   wire [8:0] e;
   wire eeqz;
   assign s = s1_reg ^ s2_reg;
   assign e = e1_reg - e2_reg + 8'd127;
   assign eeqz = e[8] || (e1_reg=='0);

   reg         s_reg;
   reg [7:0]   e_reg;
   reg [31:0]  m1n_reg2;
   reg [31:0]  slice2;
   reg eeqz_reg;
   always @(posedge clk) begin
      s_reg <= s;
      e_reg <= e;
      m1n_reg2 <= m1n_reg;
      slice2 <= slice;
      eeqz_reg <= eeqz;
   end

   reg         s_reg2;
   reg [7:0]   e_reg2;
   reg [31:0]  m1n_reg3;
   reg [31:0]  slice3;
   reg [31:0]  ax_reg;
   reg eeqz_reg2;
   always @(posedge clk) begin
      s_reg2 <= s_reg;
      e_reg2 <= e_reg;
      m1n_reg3 <= m1n_reg2;
      slice3 <= slice2;
      ax_reg <= ax;
      eeqz_reg2 <= eeqz_reg;
   end


   logic [31:0] m2inv;
   fsub u2(slice3, ax_reg, m2inv, clk);

   reg         s_reg3;
   reg [7:0]   e_reg3;
   reg [31:0]  m1n_reg4;
   reg eeqz_reg3;
   always @(posedge clk) begin
      s_reg3 <= s_reg2;
      e_reg3 <= e_reg2;
      m1n_reg4 <= m1n_reg3;
      eeqz_reg3 <= eeqz_reg2;
   end

   reg         s_reg4;
   reg [7:0]   e_reg4;
   reg [31:0]  m1n_reg5;
   reg eeqz_reg4;
   always @(posedge clk) begin
      s_reg4 <= s_reg3;
      e_reg4 <= e_reg3;
      m1n_reg5 <= m1n_reg4;
      eeqz_reg4 <= eeqz_reg3;
   end

   reg         s_reg5;
   reg [7:0]   e_reg5;
   reg [31:0]  m1n_reg6;
   reg eeqz_reg5;
   always @(posedge clk) begin
      s_reg5 <= s_reg4;
      e_reg5 <= e_reg4;
      m1n_reg6 <= m1n_reg5;
      eeqz_reg5 <= eeqz_reg4;
   end

   reg         s_reg6;
   reg [7:0]   e_reg6;
   reg [31:0]  m1n_reg7;
   reg eeqz_reg6;
   always @(posedge clk) begin
      s_reg6 <= s_reg5;
      e_reg6 <= e_reg5;
      m1n_reg7 <= m1n_reg6;
      eeqz_reg6 <= eeqz_reg5;
   end

   reg         s_reg10;
   reg [7:0]   e_reg10;
   reg [31:0]  m1n_reg10;
   reg eeqz_reg10;
   reg [31:0]  m2inv_reg;
   always @(posedge clk) begin
      s_reg10 <= s_reg6;
      e_reg10 <= e_reg6;
      m1n_reg10 <= m1n_reg7;
      eeqz_reg10 <= eeqz_reg6;
      m2inv_reg <= m2inv;
   end

//4.
   logic [31:0] mdiv;
   fmul u3(m1n_reg10, m2inv_reg, mdiv, clk);

   reg          s_reg7;
   reg [7:0]    e_reg7;
   reg eeqz_reg7;
   always @(posedge clk) begin
      s_reg7 <= s_reg10;
      e_reg7 <= e_reg10;
      eeqz_reg7 <= eeqz_reg10;
   end

   reg          s_reg8;
   reg [7:0]    e_reg8;
   reg eeqz_reg8;
   reg [31:0]   mdiv_reg;
   always @(posedge clk) begin
      s_reg8 <= s_reg7;
      e_reg8 <= e_reg7;
      eeqz_reg8 <= eeqz_reg7;
      mdiv_reg <= mdiv;
   end

//5.
   wire [8:0]  ediv;
   wire        ovfdiv, udfdiv;
   assign ovfdiv = mdiv_reg[30];
   assign udfdiv = ~mdiv_reg[23];
   assign ediv = e_reg8 + ovfdiv - udfdiv;

//6.
   wire sdiv;
   assign sdiv = s_reg8;

//7.
   assign y = (eeqz_reg8 || ediv[8]) ? '0 : {sdiv,ediv[7:0],mdiv_reg[22:0]};

endmodule

`default_nettype wire
