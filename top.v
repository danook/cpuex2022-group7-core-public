`default_nettype none

module top (
        input wire          CLK100MHZ,
        input wire          CPU_RESETN,
        input wire          UART_TXD_IN,
        output wire         UART_RXD_OUT,
        // DDR2
        output wire [12:0]  ddr2_addr,
        output wire [2:0]   ddr2_ba,
        output wire	        ddr2_cas_n,
        output wire [0:0]   ddr2_ck_n,
        output wire [0:0]   ddr2_ck_p,
        output wire [0:0]   ddr2_cke,
        output wire	        ddr2_ras_n,
        output wire	        ddr2_we_n,
        inout wire [15:0]   ddr2_dq,
        inout wire [1:0]    ddr2_dqs_n,
        inout wire [1:0]    ddr2_dqs_p,
        output wire [0:0]   ddr2_cs_n,
        output wire [1:0]   ddr2_dm,
        output wire [0:0]   ddr2_odt
    );

    // DDR2 wires
    // wire [12:0] ddr2_addr;
    // wire [2:0] ddr2_ba;
    // wire ddr2_cas_n;
    // wire [0:0] ddr2_ck_n;
    // wire [0:0] ddr2_ck_p;
    // wire [0:0] ddr2_cke;
    // wire ddr2_ras_n;
    // wire ddr2_we_n;
    // wire [15:0] ddr2_dq;
    // wire [1:0] ddr2_dqs_n;
    // wire [1:0] ddr2_dqs_p;
    // wire [0:0] ddr2_cs_n;
    // wire [1:0] ddr2_dm;
    // wire [0:0] ddr2_odt;

    io_core_controller _controller (
        CLK100MHZ,
        CPU_RESETN,
        UART_TXD_IN,
        UART_RXD_OUT,
        ddr2_addr,
        ddr2_ba,
        ddr2_cas_n,
        ddr2_ck_n,
        ddr2_ck_p,
        ddr2_cke,
        ddr2_ras_n,
        ddr2_we_n,
        ddr2_dq,
        ddr2_dqs_n,
        ddr2_dqs_p,
        ddr2_cs_n,
        ddr2_dm,
        ddr2_odt
    );

endmodule

`default_nettype wire
