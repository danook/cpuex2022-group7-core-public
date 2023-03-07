`default_nettype none

module fltz (
        /* verilator lint_off UNUSED */
        input wire [31:0]   x,
        /* verilator lint_on UNUSED */
        output wire         y
    );

    assign y = x[31] == 1'b1 && x[30:23] != 8'b0;

endmodule

`default_nettype wire