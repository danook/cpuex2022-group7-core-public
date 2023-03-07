`default_nettype none

module input_controller (
        input wire                  clk,
        input wire                  rstn,
        input wire                  rxd,
        output logic                prog_recv_done,     // プログラムの受信完了 コア開始の合図
        output utils::bram_wreq_t   inst_mem_wreq,      // 命令メモリに書き込む時に使う
        output utils::bram_wreq_t   bram_wreq,        // data sectionを書き込む時に使う
        input wire                  read_input,         // コアからの入力受け取り要求
        input wire                  read_input_done,    // コアが入力を受け取るサイクルで立てる
        output logic                stall,              // コアへのストール要求
        output logic [31:0]         input_buf_rdata
    );
    
    // 注: これらのサイズはword単位
    logic [31:0]    data_sec_size;
    logic [31:0]    text_sec_size;

    logic           uart_ready;
    logic [31:0]    uart_buf;

    utils::bram_wreq_t  input_buf_wreq;
    logic [31:0]        input_buf_raddr;

    enum logic [2:0] {
        PROG_SIZE,
        DATA_SEC_SIZE,
        TEXT_SEC_SIZE,
        PROG_DATA_SEC,
        PROG_TEXT_SEC,
        DATA
    } state;

    uart_buf_rx _buf_rx (
        clk,
        rstn,
        rxd,
        uart_ready,
        uart_buf
    );

    bram #(
        .MEMSIZE(1024)
    ) _input_buf (
        clk,
        rstn,
        input_buf_wreq,
        input_buf_raddr,
        input_buf_rdata
    );
    
    // UARTで受け取ったデータを書き込む
    // 注: プログラムのtext sectionは空ではないと仮定している
    always @(posedge clk) begin
        if (~rstn) begin
            state                   <= PROG_SIZE;
            prog_recv_done          <= 1'b0;
            data_sec_size           <= 0;
            text_sec_size           <= 0;
            inst_mem_wreq.waddr     <= 0;
            inst_mem_wreq.wdata     <= 0;
            inst_mem_wreq.wenable   <= 1'b0;
            input_buf_wreq.waddr    <= 0;
            input_buf_wreq.wdata    <= 0;
            input_buf_wreq.wenable  <= 1'b0;
            bram_wreq.waddr       <= 0;
            bram_wreq.wdata       <= 0;
            bram_wreq.wenable     <= 1'b0;
        end else begin
            if (uart_ready) begin
                case (state)
                    PROG_SIZE:
                    // プログラム全体のバイト数を受け取るが、これはdata_sec_size, text_sec_sizeがあるため不要
                    // プログラムが空かどうかの判定にのみ使用する (空ならデータ受け取りモードへ)
                    if (uart_buf == 0) begin
                        prog_recv_done <= 1'b1;
                        state <= DATA;
                    end else begin
                        state <= DATA_SEC_SIZE;
                    end

                    DATA_SEC_SIZE:
                    begin
                        data_sec_size <= utils::USE_WORD_ADDRESSING ? uart_buf : {2'b0, uart_buf[31:2]};
                        state <= TEXT_SEC_SIZE;
                    end

                    TEXT_SEC_SIZE:
                    begin
                        text_sec_size <= utils::USE_WORD_ADDRESSING ? uart_buf : {2'b0, uart_buf[31:2]};
                        state <= data_sec_size != 0 ? PROG_DATA_SEC : PROG_TEXT_SEC;
                    end

                    PROG_DATA_SEC:
                    begin
                        bram_wreq.wdata <= uart_buf;
                        bram_wreq.wenable <= 1'b1;
                    end

                    PROG_TEXT_SEC:
                    begin
                        inst_mem_wreq.wdata <= uart_buf;
                        inst_mem_wreq.wenable <= 1'b1;
                    end

                    DATA:
                    begin
                        input_buf_wreq.wdata <= uart_buf;
                        input_buf_wreq.wenable <= 1'b1;
                    end

                    default:;
                endcase
            end

            if (bram_wreq.wenable) begin
                bram_wreq.wenable <= 1'b0;
                if (bram_wreq.waddr + 1 == data_sec_size) begin
                    state <= PROG_TEXT_SEC;
                end else begin
                    bram_wreq.waddr <= bram_wreq.waddr + 1;
                end
            end

            if (inst_mem_wreq.wenable) begin
                inst_mem_wreq.wenable <= 1'b0;
                if (inst_mem_wreq.waddr + 1 == text_sec_size) begin
                    prog_recv_done <= 1'b1;
                    state <= DATA;
                end else begin
                    inst_mem_wreq.waddr <= inst_mem_wreq.waddr + 1;
                end
            end

            if (input_buf_wreq.wenable) begin
                input_buf_wreq.wenable <= 1'b0;
                input_buf_wreq.waddr <= input_buf_wreq.waddr + 1;
            end
        end
    end

    // BRAMの特性上、読み出しには1サイクルかかるので、アドレスをincrementした直後はこれを立てておく
    logic input_buf_unready;
    assign stall = read_input & (input_buf_unready | (input_buf_wreq.waddr <= input_buf_raddr));

    // コアから読み出し要求があったら読み出す
    always @(posedge clk) begin
        if (~rstn) begin
            input_buf_raddr <= 0;
            input_buf_unready <= 1'b0;
        end else begin
            if (read_input_done) begin
                input_buf_raddr <= input_buf_raddr + 1;
                input_buf_unready <= 1'b1;
            end
            if (input_buf_unready) begin
                input_buf_unready <= 1'b0;
            end
        end
    end


endmodule

`default_nettype wire