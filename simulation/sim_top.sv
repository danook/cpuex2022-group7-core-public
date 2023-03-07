`timescale 1ns / 1ps
`default_nettype none

module io_core_sim ();
    logic clk, rstn, txd, rxd, led;
    
    // DDR2 wires
    wire [12:0] ddr2_addr;
    wire [2:0] ddr2_ba;
    wire ddr2_cas_n;
    wire [0:0] ddr2_ck_n;
    wire [0:0] ddr2_ck_p;
    wire [0:0] ddr2_cke;
    wire ddr2_ras_n;
    wire ddr2_we_n;
    wire [15:0] ddr2_dq;
    wire [1:0] ddr2_dqs_n;
    wire [1:0] ddr2_dqs_p;
    wire [0:0] ddr2_cs_n;
    wire [1:0] ddr2_dm;
    wire [0:0] ddr2_odt;
    
    task gen_clk(); 
        begin
            forever begin
                #5;
                clk = 1'b1;
                #5;
                clk = 1'b0;
            end
        end
    endtask

    io_core_controller _controller (
        .clk(clk),
        .rstn(rstn),
        .txd(txd),
        .rxd(rxd),
        .*
    );

    server _server (
        clk,
        rstn,
        txd,
        rxd
    );

    // DDR2 model
    ddr2 ddr2 (
        .ck(ddr2_ck_p),
        .ck_n(ddr2_ck_n),
        .cke(ddr2_cke),
        .cs_n(ddr2_cs_n),
        .ras_n(ddr2_ras_n),
        .cas_n(ddr2_cas_n),
        .we_n(ddr2_we_n),
        .dm_rdqs(ddr2_dm),
        .ba(ddr2_ba),
        .addr(ddr2_addr),
        .dq(ddr2_dq),
        .dqs(ddr2_dqs_p),
        .dqs_n(ddr2_dqs_n),
        .rdqs_n(),
        .odt(ddr2_odt)
    );

    initial begin
        $dumpfile("test_fib.vcd");
        $display("Start running test_fib ...");

        // Initialization
        rstn <= 1'b0;
        clk <= 1'b0;

        fork
            gen_clk();
        join_none

        #20;
        rstn <= 1'b1;
    end
endmodule

`default_nettype wire