`timescale 1ns / 1ps
`default_nettype none

module server (
        input wire clk,
        input wire rstn,
        input wire rxd,
        output wire txd
    );

    localparam PROG_FILE_LEN    = 132;  // No longer used
    localparam OUTPUT_LEN       = 781;
    localparam PROG_FILE        = "D:/cpuex/test/io/io_long.bin";
    localparam INPUT_FILE       = "D:/cpuex/test/in";
    localparam OUTPUT_FILE      = "D:/cpuex/test/out";

    logic [31:0]    prog_len;
    logic [7:0]     sdata;
    logic           tx_start;
    logic           tx_busy;

    logic [7:0]     rdata;
    logic           rdata_ready;
    logic           ferr;

    integer         i, j;
    

    uart_tx _uart_tx (
        sdata,
        tx_start,
        tx_busy,
        txd,
        clk,
        rstn
    );

    uart_rx _uart_rx (
        rdata,
        rdata_ready,
        ferr,
        rxd,
        clk,
        rstn
    );

    task send_prog_file;
    begin
        int fd;
        fd = $fopen(PROG_FILE, "rb");
        assert (fd) $info("Successfully opened the file: %s", PROG_FILE);
        else $error("Failed to open the file: %s", PROG_FILE);
        
        for (j = 0; j < PROG_FILE_LEN; j++) begin
            tx_start <= 1'b1;
            $fread(sdata, fd);
            #10;
            tx_start <= 1'b0;
            #20;
            while (tx_busy) begin
                #10;
            end
        end

        $fclose(fd);
    end
    endtask

    task send_bin_file;
    begin
        int fd;
        fd = $fopen(INPUT_FILE, "rb");
        assert (fd) $info("Successfully opened the file: %s", INPUT_FILE);
        else $error("Failed to open the file: %s", INPUT_FILE);
        
        while (!$feof(fd)) begin
            tx_start <= 1'b1;
            $fread(sdata, fd);
            #10;
            tx_start <= 1'b0;
            #20;
            while (tx_busy) begin
                #10;
            end
        end

        $fclose(fd);
    end
    endtask

    task receive_bin_file();
    begin
        int fd;
        fd = $fopen(OUTPUT_FILE, "wb");
        assert (fd) $info("Successfully opened the file: %s", OUTPUT_FILE);
        else $error("Failed to open the file: %s", OUTPUT_FILE);
        
        for (j = 0; j < OUTPUT_LEN; j++) begin
            while (!rdata_ready) begin
                #10; // wait
            end
            $fwrite(fd, "%c", rdata);
            #10;
        end

        $fclose(fd);
    end
    endtask

    initial begin
        sdata <= 8'b0;
        tx_start <= 1'b0;
        prog_len <= utils::USE_MEM_INIT_FILE ? 0 : PROG_FILE_LEN;
        #100;
        
        // Wait for 0x99
        while (!rdata_ready) begin
            #10; // wait
        end
        
        // Send program length
        for (i = 0; i < 4; i++) begin
            tx_start <= 1'b1;
            sdata <= prog_len[7:0];
            #10;
            tx_start <= 1'b0;
            prog_len <= prog_len >> 8;
            while (tx_busy) begin
                #10;
            end
        end

        if (!utils::USE_MEM_INIT_FILE) begin
            send_prog_file();
        end

        // Wait for 0xaa
        while (!rdata_ready) begin
            #10; // wait
        end
        
        fork
            send_bin_file();
        join_none
        
        fork
            receive_bin_file();
        join_none
    end
endmodule

`default_nettype wire