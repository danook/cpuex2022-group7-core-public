`default_nettype none

module output_controller (
        input wire          clk,
        input wire          rstn,
        input wire          start,
        input wire          mode,       // 0: DMA, 1: 1バイト信号
        input wire [7:0]    sendsig,    // 送信する信号
        output logic        txd,
        input wire          write_output,
        input wire [7:0]    output_data,
        output logic        stall       // バッファがfullのとき
    );

    localparam BUFFER_SIZE = 65536;

    logic               busy;
    logic               tx_start;
    logic               tx_busy;
    logic [7:0]         sendbuf;

    utils::bram_wreq_t  mem_wreq;
    logic [7:0]         mem_rdata;
    logic [31:0]        mem_raddr;
    logic               full;

    assign stall = full & write_output;

    uart_tx _uart_tx (
        .sdata(sendbuf),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .txd(txd),
        .clk(clk),
        .rstn(rstn)
    );

    bram #(
        .WIDTH(8),
        .MEMSIZE(BUFFER_SIZE)
    ) _output_buffer (
        clk,
        rstn,
        mem_wreq,
        mem_raddr,
        mem_rdata
    );

    
    wire [31:0] next_raddr, next_waddr;
    assign next_raddr = (mem_raddr == BUFFER_SIZE - 1) ? 0 : mem_raddr + 1;
    assign next_waddr = (mem_wreq.waddr == BUFFER_SIZE - 1) ? 0 : mem_wreq.waddr + 1;
    always @(posedge clk) begin
        if (~rstn) begin
            tx_start    <= 1'b0;
            sendbuf     <= 8'b0;
            busy        <= 1'b0;
            mem_raddr   <= 32'b0;
            mem_wreq.wenable <= 1'b0;
            mem_wreq.wdata   <= 0;
            mem_wreq.waddr   <= 0;
            full             <= 1'b0;
        end else begin
            // コアから書き込まれたデータを順次送信する
            if (mode) begin
                // 結果の出力までには十分時間があるので、busyを立てなくても被ることはないはず
                if (start) begin
                    busy <= 1'b1;
                    tx_start <= 1'b1;
                    sendbuf <= sendsig;
                end
                if (tx_start) begin
                    tx_start <= 1'b0;
                end
                if (busy & ~tx_busy & ~tx_start) begin
                    busy <= 1'b0;
                end
            end else begin
                if (~busy & ((mem_raddr != mem_wreq.waddr) | full)) begin
                    busy <= 1'b1;
                    tx_start <= 1'b1;
                    sendbuf <= mem_rdata;
                    mem_raddr <= next_raddr;
                    full <= 1'b0;
                end
                if (busy & ~tx_busy & ~tx_start) begin
                    if ((mem_raddr != mem_wreq.waddr) | full) begin
                        tx_start <= 1'b1;
                        sendbuf <= mem_rdata;
                        mem_raddr <= next_raddr;
                        full <= 1'b0;
                    end else begin
                        busy <= 1'b0;
                    end
                end
            end
            if (tx_start) begin
                tx_start <= 1'b0;
            end

            // コアから送られてきたデータをメモリに書き込んでいく
            if (write_output & ~full) begin
                mem_wreq.wenable <= 1'b1;
                mem_wreq.wdata <= {24'b0, output_data}; // width adjustment
                if (next_waddr == mem_raddr) begin
                    full <= 1'b1;
                end
            end
            if (mem_wreq.wenable) begin
                if (~write_output | full) begin
                    mem_wreq.wenable <= 1'b0;
                end
                mem_wreq.waddr <= next_waddr;
            end
        end
    end
endmodule

`default_nettype wire