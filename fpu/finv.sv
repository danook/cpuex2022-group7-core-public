`default_nettype none

module finv (input wire  [31:0] x,
            output wire [31:0] y,
            input wire clk);

   (* ram_style="block" *) logic [31:0] mem [2047:0];


initial begin
   $readmemb("D:/cpuex/core/fpu/finv_table.txt", mem);
end

//1.
   wire s;
   wire [7:0] e;
   wire [22:0] m;
   assign {s,e,m} = x;

//2.
   wire [9:0] h;
   logic [31:0] mn;
   logic [10:0] addr;
   logic [10:0] addri;
   assign h = m[22:13];
   assign mn = {1'b0, 8'd127, m};
   assign addr = {h, 1'b0};
   assign addri = {h, 1'b1};


   reg [31:0] grad;
   reg [31:0] slice;
   reg s_reg;
   reg [7:0] e_reg;
   reg [31:0] mn_reg;
   always @(posedge clk) begin
      grad <= mem[addr];
      slice <= mem[addri];
      s_reg <= s;
      e_reg <= e;
      mn_reg <= mn;
   end


//3.
   logic [31:0] ax;
   fmul u1(grad, mn_reg, ax, clk);
   wire [7:0] einv;
   assign einv = (8'd253-e_reg);


   reg s_reg2;
   reg [7:0] e_reg2;
   reg [31:0] slice2;
   always @(posedge clk) begin
      s_reg2 <= s_reg;
      e_reg2 <= einv;
      slice2 <= slice;
   end

   reg s_reg3;
   reg [7:0] e_reg3;
   reg [31:0] slice3;
   reg [31:0] ax_reg;
   always @(posedge clk) begin
      s_reg3 <= s_reg2;
      e_reg3 <= e_reg2;
      slice3 <= slice2;
      ax_reg <= ax;
   end


   wire [31:0] minv;
   fsub u2(slice3, ax_reg, minv, clk);


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
   assign y = {s_reg7,e_reg7,minv[22:0]};

endmodule

`default_nettype wire
