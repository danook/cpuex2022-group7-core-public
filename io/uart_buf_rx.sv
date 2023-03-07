`default_nettype none

module uart_buf_rx (
        input wire          clk,
        input wire          rstn,
        input wire          rxd,
        output logic        ready,
        output logic [31:0] buffer
    );

    logic [7:0]     rdata;
    logic           rdata_ready;
    /* verilator lint_off UNUSED */
    logic           ferr;
    /* verilator lint_on UNUSED */
    logic [1:0]     counter;

    uart_rx _uart_rx (
        rdata,
        rdata_ready,
        ferr,
        rxd,
        clk,
        rstn
    );

    always @(posedge clk) begin
        if (~rstn) begin
            ready <= 1'b0;
            buffer <= 0;
            counter <= 2'b0;
        end else begin
            if (rdata_ready) begin
                buffer <= (buffer >> 8) | {rdata, 24'b0};
                if (counter == 2'b11) begin
                    counter <= 2'b00;
                    ready <= 1'b1;
                end else begin
                    counter <= counter + 2'b01;
                end
            end
            
            if (ready == 1'b1) begin
                // readyはすぐ下げる
                ready <= 1'b0;
                buffer <= 0;
            end
        end
    end

endmodule

`default_nettype wire