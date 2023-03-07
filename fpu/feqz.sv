`default_nettype none

module feqz (
        /* verilator lint_off UNUSED */
        input wire [31:0]   x,
        /* verilator lint_on UNUSED */
        output wire         y
    );

    assign y = x[30:0] == 31'b0 ? 1'b1 : 1'b0;

endmodule

`default_nettype wire