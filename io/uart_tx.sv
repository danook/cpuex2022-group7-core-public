`default_nettype none

module uart_tx #(CLK_PER_HALF_BIT = utils::CLK_PER_HALF_BIT) (
      input wire [7:0] sdata,
      input wire       tx_start,
      output logic     tx_busy,
      output logic     txd,
      input wire       clk,
      input wire       rstn
   );

   // Example of expected behavior (COUNT_MAX=3)
   // timer 0 0 0 0 1 2 3 0 1 2 3
   // entim 0 0 0 1 1 1 1 1 1 1 1
   // start 0 0 1 0 0 0 0 0 0 0 0
   // txd   1 1 1 0 0 0 0 1 1 1 1

   localparam COUNT_MAX = CLK_PER_HALF_BIT * 2 - 1;
   
   enum bit [3:0] {
      IDLE,
      START_BIT,
      BIT0,
      BIT1,
      BIT2,
      BIT3,
      BIT4,
      BIT5,
      BIT6,
      BIT7,
      STOP_BIT
   } state;

   // Count-up timer
   logic [31:0] counter;
   always @(posedge clk) begin
      if (~rstn) begin
         counter <= 0;
      end else begin
         if (state == IDLE) begin
            counter <= 0;
         end else begin
            counter <= counter == COUNT_MAX ? 0 : counter + 1;
         end
      end
   end

   logic [7:0] sendbuf;
   assign txd = 
      state == IDLE        ? 1'b1 :
      state == START_BIT   ? 1'b0 :
      state == STOP_BIT    ? 1'b1 : sendbuf[0];

   always @(posedge clk) begin
      if (~rstn) begin
         state <= IDLE;
         sendbuf <= 8'b0;
         tx_busy <= 1'b0;
      end else begin
         if (tx_start) begin
            state <= START_BIT;
            sendbuf <= sdata;
            tx_busy <= 1'b1;
         end

         if (tx_busy && counter == COUNT_MAX) begin
            if (state == STOP_BIT) begin
               state <= IDLE;
               sendbuf <= 8'b0;
               tx_busy <= 1'b0;
            end else if (state == START_BIT) begin
               state <= state.next();
            end else begin
               state <= state.next();
               sendbuf <= {1'b0, sendbuf[7:1]};
            end
         end
      end
   end
endmodule // uart_tx
`default_nettype wire
