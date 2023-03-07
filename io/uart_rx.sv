`default_nettype none

module uart_rx #(CLK_PER_HALF_BIT = utils::CLK_PER_HALF_BIT) (
      output logic [7:0] rdata,
      output logic       rdata_ready,
      output logic       ferr,
      input wire         rxd,
      input wire         clk,
      input wire         rstn
   );

   localparam COUNT_MAX = CLK_PER_HALF_BIT * 2 - 1;
   localparam HALF_COUNT_MAX = CLK_PER_HALF_BIT - 1;

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
         end else if (state == START_BIT) begin
            counter <= counter == HALF_COUNT_MAX ? 0 : counter + 1;
         end else begin
            counter <= counter == COUNT_MAX ? 0 : counter + 1;
         end
      end
   end

   always @(posedge clk) begin
      if (~rstn) begin
         state <= IDLE;
         rdata <= 8'b0;
         rdata_ready <= 1'b0;
      end else begin
         case (state)
            IDLE: begin
               if (rdata_ready) begin
                  rdata_ready <= 1'b0;
               end
               
               if (rxd == 1'b0) begin
                  state <= START_BIT;
               end
            end

            START_BIT:
            if (counter == HALF_COUNT_MAX) begin
               state <= BIT0;
            end

            STOP_BIT:
            if (counter == COUNT_MAX) begin
               state <= IDLE;
               ferr <= ~rxd;
               rdata_ready <= 1'b1;
            end

            default: 
            if (counter == COUNT_MAX) begin
               rdata <= (rdata >> 1) | {rxd, 7'b0};
               state <= state.next();
            end
         endcase
      end
   end
endmodule
`default_nettype wire
