`default_nettype none

module core (
        input wire              clk,
        input wire              rstn,
        input wire              start,
        output wire             inst_mem_renable,
        output wire [31:0]      inst_mem_raddr,
        input wire [31:0]       inst_mem_rdata,
        output utils::mem_req_t ddr_req,
        input utils::mem_res_t  ddr_res,
        output utils::bram_wreq_t   stack_wreq,
        output wire [31:0]          stack_raddr,
        input wire [31:0]           stack_rdata,
        output utils::bram_wreq_t   bram_wreq,
        output wire [31:0]          bram_raddr,
        input wire [31:0]           bram_rdata,
        output logic            read_input,
        output logic            read_input_done,
        input wire              input_stall,
        input wire [31:0]       input_rdata,
        output wire             write_output,
        input wire              output_stall,
        output wire [7:0]       output_data
    );

    // Flush時やstartが立つ前は、命令をnop (= add x0, x0, x0)で置き換える
    localparam NOP = 32'b0;

    // EOF命令が読み込まれたら終了 (最上位bitのみ1)
    localparam EOF = 32'h80000000;

    // プログラム実行中 busy=0のときはひたすらNOPを実行する
    logic           busy;

    // NOTE: pc is word-addressing
    logic [15:0]    pc_IF_reg;
    logic [15:0]    pc_IF, pc_ID, pc_EX, pc_MA;
    logic [15:0]    jump_pc_ID, jump_pc_EX, jump_pc_EX_reg, jump_pc_MA;
    logic [31:0]    inst_ID;
    
    logic           stall;
    logic           non_hazard_stall;
    logic           memory_stall;

    // Instruction dependency handling
    logic           hazard_stall;
    logic           flush_IF, flush_ID;
    // flush_IFはその場でflushするのが困難なので、次のクロックでflushする
    // TODO: flush_IDと統合する
    logic           flush_IF_after;
    logic [1:0]     forward1_ID, forward2_ID, forward3_ID, forward1_EX;

    // Decoded instruction
    logic [3:0]     opcode_ID;
    logic [5:0]     rd_ID, rd_EX, rd_MA, rd_WB;       
    logic [5:0]     rs1_ID, rs2_ID, rs3_ID;
    logic [2:0]     funct3_ID, funct3_EX;
    logic [4:0]     funct5_ID, funct5_EX;   // for FPU
    logic           imm_sign_ID;
    
    // Output of control unit
    logic [1:0]     pc_src_ID,      pc_src_EX,      pc_src_MA;
    logic [2:0]     result_src_ID,  result_src_EX,  result_src_MA,  result_src_WB;
    logic           mem_enable_ID,  mem_enable_EX;
    logic           mem_write_ID,   mem_write_EX;
    logic           ddr_enable_MA;
    logic           ddr_write_MA;
    logic           bram_write_MA;
    logic           stack_write_ID, stack_write_EX, stack_write_MA;
    logic [2:0]     alu_control_ID, alu_control_EX;
    logic           reg_src1_ID,    reg_src2_ID,    reg_src3_ID;
    logic [1:0]     alu_src2_ID,    alu_src2_EX;
    logic [1:0]     imm_src_ID;
    logic           reg_write_ID,   reg_write_EX,   reg_write_MA,   reg_write_WB;
    logic           freg_write_ID,  freg_write_EX,  freg_write_MA,  freg_write_WB;

    logic           read_fpu_MA;

    // アドレスが小さい場合はDDRの代わりにBRAMを用いる
    logic           use_bram_for_mem_EX;

    // Sources
    logic [31:0]    reg_rdata1_ID,  reg_rdata1_EX,  reg_rdata1_MA;
    logic [31:0]    reg_rdata2_ID,  reg_rdata2_EX,  reg_rdata2_MA;
    logic [31:0]    freg_rdata1_ID, freg_rdata1_EX;
    logic [31:0]    freg_rdata2_ID, freg_rdata2_EX, freg_rdata2_MA;
    logic [31:0]    freg_rdata3_ID, freg_rdata3_EX;
    logic [31:0]    imm_ext1_ID,    imm_ext1_EX;
    logic [31:0]    imm_ext2_ID,    imm_ext2_EX;

    logic [31:0]    forwarded_reg_rdata1_ID, forwarded_reg_rdata2_ID;
    logic [31:0]    forwarded_freg_rdata1_ID, forwarded_freg_rdata2_ID, forwarded_freg_rdata3_ID;

    // Results
    logic [31:0]    alu_result_EX,  alu_result_MA;
    logic [31:0]    fpu_result_MA;
    logic [31:0]    result_EX,      result_MA,      result_WB;
    logic [31:0]    result_MA_suppl, result_WB_suppl;

    // Branch results (分岐がtakenかどうか)
    logic           branch_result_EX, branch_result_MA;
    logic           alu_branch_result_EX;
    logic           fpu_branch_result_EX;
    logic           branch_predict_ID, branch_predict_EX, branch_predict_MA;

    // I/O control
    logic           input_enable_ID,  input_enable_EX,  input_enable_MA;
    logic           output_enable_ID, output_enable_EX, output_enable_MA;

    // FPU control
    logic           fpu_stall;
    logic           fpu_enable_ID, fpu_enable_EX;

    // 最後の命令が実行終了したらコアを停止するので、そのための信号
    logic           end_EX, end_MA, end_WB;

    branch_predict _branch_predict (
        .clk(clk),
        .rstn(rstn),
        .stall(stall),
        .pc_IF(pc_IF),
        .pc_EX(pc_EX),
        .branch_predict_ID(branch_predict_ID),
        .branch_EX(pc_src_EX == 2'b11),
        .branch_result_EX(branch_result_EX)
    );

    control_unit _control_unit (
        .opcode(opcode_ID),
        .funct3(funct3_ID),
        .funct2(funct5_ID[4:3]),
        .pc_src(pc_src_ID),
        .result_src(result_src_ID),
        .mem_enable(mem_enable_ID),
        .mem_write(mem_write_ID),
        .stack_write(stack_write_ID),
        .alu_control(alu_control_ID),
        .reg_src1(reg_src1_ID),
        .reg_src2(reg_src2_ID),
        .reg_src3(reg_src3_ID),
        .alu_src2(alu_src2_ID),
        .imm_src(imm_src_ID),
        .reg_write(reg_write_ID),
        .freg_write(freg_write_ID),
        .input_enable(input_enable_ID),
        .output_enable(output_enable_ID),
        .use_fpu(fpu_enable_ID)
    );

    register_file #(.FPU(0)) _register_file (
        // write backされるのは次クロックの立ち上がりでいいのか？
        .clk(clk),
        .rstn(rstn),
        .write_enable(reg_write_WB),
        .read_addr1(rs1_ID),
        .read_addr2(rs2_ID),
        .read_addr3(rs3_ID),
        .write_addr(rd_WB),
        .write_data(result_WB_suppl),
        .read_data1(reg_rdata1_ID),
        .read_data2(reg_rdata2_ID),
        .read_data3()
    );

    register_file #(.FPU(1)) _fpu_register_file (
        .clk(clk),
        .rstn(rstn),
        .write_enable(freg_write_WB),
        .read_addr1(rs1_ID),
        .read_addr2(rs2_ID),
        .read_addr3(rs3_ID),
        .write_addr(rd_WB),
        .write_data(result_WB_suppl),
        .read_data1(freg_rdata1_ID),
        .read_data2(freg_rdata2_ID),
        .read_data3(freg_rdata3_ID)
    );

    imm_extend _imm_extend (
        .imm_sign(imm_sign_ID),
        .imm_frac1(rs3_ID),
        .imm_frac2(rs2_ID),
        .imm_frac3(rs1_ID),
        .imm_frac4(funct3_ID),
        .imm_frac5(rd_ID),
        .imm_src(imm_src_ID),
        .imm_ext1(imm_ext1_ID),
        .imm_ext2(imm_ext2_ID)
    );

    alu _alu (
        .src1(reg_rdata1_EX),
        .src2(alu_src2_EX == 2'b01 ? imm_ext1_EX : alu_src2_EX == 2'b10 ? imm_ext2_EX : reg_rdata2_EX),
        .funct3(alu_control_EX),
        .result(alu_result_EX),
        .branch_result(alu_branch_result_EX)
    );

    fpu _fpu (
        .clk(clk),
        .rstn(rstn),
        .fsrc1(freg_rdata1_EX),
        .fsrc2(freg_rdata2_EX),
        .fsrc3(freg_rdata3_EX),
        .src1(reg_rdata1_EX),
        .funct5_EX(funct5_EX),
        .funct3_EX(funct3_EX),
        .fpu_enable(fpu_enable_EX),
        .stall(fpu_stall),
        .result_reg(fpu_result_MA),
        .branch_result(fpu_branch_result_EX)
    );

    // Program counter
    assign pc_IF =
        (pc_src_MA == 2'b11 && branch_result_MA != branch_predict_MA) ? (
            branch_result_MA ? jump_pc_MA : pc_MA + 16'b1
        ) :
        pc_src_MA == 2'b10  ? jump_pc_MA :
        pc_src_ID == 2'b11 && branch_predict_ID ? jump_pc_ID :
        pc_src_ID == 2'b01  ? jump_pc_ID : pc_IF_reg;

    // Instruction decode
    assign opcode_ID = inst_ID[3:0];
    assign rd_ID     = inst_ID[9:4];
    assign funct3_ID = inst_ID[12:10];
    assign rs1_ID    = inst_ID[18:13];
    assign rs2_ID    = inst_ID[24:19];
    assign rs3_ID    = inst_ID[30:25];
    assign funct5_ID = inst_ID[31:27];
    assign imm_sign_ID = inst_ID[31];

    // Hazard handling
    assign flush_ID = (pc_src_EX == 2'b11 && branch_result_EX != branch_predict_EX) || pc_src_EX == 2'b10;
    assign flush_IF = flush_ID;

    // rd=0のとき、zeroレジスタは書き換えられない保証があるのでデータ依存とはみなさない

    assign hazard_stall =
        ((result_src_EX == 3'b011 || result_src_EX == 3'b001 || result_src_EX == 3'b100 || result_src_EX == 3'b101 || result_src_EX == 3'b110) && 
        (forward1_ID == 2'b01 || forward2_ID == 2'b01 || forward3_ID == 2'b01)) ||
        ((result_src_MA == 3'b101 || result_src_MA == 3'b110) && 
        (forward1_ID == 2'b10 || forward2_ID == 2'b10 || forward3_ID == 2'b10))
        ? 1'b1 : 1'b0;

    // 01: From EX, 10: From MA, 11: From WB, 00: No forwarding
    assign forward1_ID =
        rs1_ID == 6'b0 ? 2'b00 :
        rs1_ID == rd_EX && (reg_src1_ID ? freg_write_EX : reg_write_EX) ? 2'b01 :
        rs1_ID == rd_MA && (reg_src1_ID ? freg_write_MA : reg_write_MA) ? 2'b10 :
        rs1_ID == rd_WB && (reg_src1_ID ? freg_write_WB : reg_write_WB) ? 2'b11 : 2'b00;

    assign forward2_ID =
        rs2_ID == 6'b0 ? 2'b00 :
        rs2_ID == rd_EX && (reg_src2_ID ? freg_write_EX : reg_write_EX) ? 2'b01 :
        rs2_ID == rd_MA && (reg_src2_ID ? freg_write_MA : reg_write_MA) ? 2'b10 :
        rs2_ID == rd_WB && (reg_src2_ID ? freg_write_WB : reg_write_WB) ? 2'b11 : 2'b00;

    assign forward3_ID =
        rs3_ID == 6'b0 || reg_src3_ID == 1'b0 ? 2'b00 :
        rs3_ID == rd_EX && freg_write_EX ? 2'b01 :
        rs3_ID == rd_MA && freg_write_MA ? 2'b10 :
        rs3_ID == rd_WB && freg_write_WB ? 2'b11 : 2'b00;

    // Register read data with forwarding
    assign forwarded_reg_rdata1_ID =
        forward1_ID == 2'b01 ? result_EX : 
        forward1_ID == 2'b10 ? result_MA_suppl : 
        forward1_ID == 2'b11 ? result_WB_suppl : reg_rdata1_ID;
    assign forwarded_reg_rdata2_ID =
        forward2_ID == 2'b01 ? result_EX : 
        forward2_ID == 2'b10 ? result_MA_suppl : 
        forward2_ID == 2'b11 ? result_WB_suppl : reg_rdata2_ID;
    assign forwarded_freg_rdata1_ID =
        forward1_ID == 2'b01 ? result_EX : 
        forward1_ID == 2'b10 ? result_MA_suppl : 
        forward1_ID == 2'b11 ? result_WB_suppl : freg_rdata1_ID;
    assign forwarded_freg_rdata2_ID =
        forward2_ID == 2'b01 ? result_EX : 
        forward2_ID == 2'b10 ? result_MA_suppl : 
        forward2_ID == 2'b11 ? result_WB_suppl : freg_rdata2_ID;
    assign forwarded_freg_rdata3_ID =
        forward3_ID == 2'b01 ? result_EX : 
        forward3_ID == 2'b10 ? result_MA_suppl : 
        forward3_ID == 2'b11 ? result_WB_suppl : freg_rdata3_ID;

    // Jump destination
    assign jump_pc_ID           = pc_src_ID[0] == 1'b1 
        ? pc_ID + imm_ext1_ID[17:2] // jal, branch
        : 0;
    
    assign jump_pc_EX           = pc_src_EX == 2'b10 
        ? reg_rdata1_EX[15:0] + imm_ext1_EX[17:2] // jalr
        : jump_pc_EX_reg;

    // Memory access
    assign inst_mem_renable     = ~stall;   // これがないと、inst_IDがストール時に維持されない
    assign inst_mem_raddr       = {16'b0, pc_IF};
    assign inst_ID              = flush_IF_after ? NOP : busy ? inst_mem_rdata : NOP;

    assign use_bram_for_mem_EX  = alu_result_EX < utils::BRAM_SIZE ? 1'b1 : 1'b0;
    
    assign ddr_req.valid        = ddr_enable_MA;
    assign ddr_req.rw           = ddr_write_MA;
    assign ddr_req.addr         = {alu_result_MA[29:0], 2'b0};
    assign ddr_req.data         = result_src_MA == 3'b011 ? freg_rdata2_MA : reg_rdata2_MA;

    assign stack_raddr          = alu_result_MA;
    assign stack_wreq.waddr     = alu_result_MA;
    assign stack_wreq.wdata     = result_src_MA == 3'b011 ? freg_rdata2_MA : reg_rdata2_MA;
    assign stack_wreq.wenable   = stack_write_MA;

    assign bram_raddr           = alu_result_MA;
    assign bram_wreq.waddr      = alu_result_MA;
    assign bram_wreq.wdata      = result_src_MA == 3'b011 ? freg_rdata2_MA : reg_rdata2_MA;
    assign bram_wreq.wenable    = bram_write_MA;

    assign branch_result_EX     = result_src_EX == 3'b011 ? fpu_branch_result_EX : alu_branch_result_EX;

    assign memory_stall         = ddr_enable_MA & ~ddr_res.ready;
    assign non_hazard_stall     = input_stall | output_stall | memory_stall | fpu_stall;
    assign stall                = hazard_stall | non_hazard_stall;

    assign read_input           = input_enable_MA;
    assign write_output         = output_enable_MA;     // コアとは独立しているので別にどのステージでもよい(が、ストール時の動作を変える必要あり)

    // input命令が連続している場合、input_enableが立ちっぱなしでinput_controllerがその区切り目が分からない
    // ため、入力を読み出すサイクルでread_input_doneを立てて次の入力を読み出す
    assign read_input_done      = input_enable_MA & ~non_hazard_stall;

    assign output_data          = result_MA[7:0];

    // 結果をForwardingで渡すときに必要
    assign result_EX            =
        result_src_EX == 3'b000  ?  alu_result_EX :
        result_src_EX == 3'b010  ?  {16'b0, pc_EX} + 1 :
                                    32'b0;
        
    assign result_MA_suppl      =
        read_fpu_MA ? fpu_result_MA :
        result_src_MA == 3'b100 ? input_rdata :
        result_src_MA == 3'b001 && ddr_res.ready ? ddr_res.data :
        result_MA;

    assign result_WB_suppl      =
        result_src_WB == 3'b101 ? stack_rdata :
        result_src_WB == 3'b110 ? bram_rdata : result_WB;

    always @(posedge clk) begin
        if (~rstn) begin
            busy            <= '0;

            pc_ID           <= '0;
            pc_EX           <= '0;
            pc_MA           <= '0;
            jump_pc_EX_reg  <= '0;

            flush_IF_after  <= '0;

            rd_EX           <= '0;
            rd_MA           <= '0;
            rd_WB           <= '0;
            funct3_EX       <= '0;
            funct5_EX       <= '0;
            forward1_EX     <= '0;

            pc_src_EX       <= '0;
            pc_src_MA       <= '0;
            result_src_EX   <= '0;
            result_src_MA   <= '0;
            result_src_WB   <= '0;
            alu_control_EX  <= '0;
            alu_src2_EX     <= '0;
            reg_write_EX    <= '0;
            reg_write_MA    <= '0;
            reg_write_WB    <= '0;
            reg_rdata1_EX   <= '0;
            reg_rdata1_MA   <= '0;
            reg_rdata2_EX   <= '0;
            reg_rdata2_MA   <= '0;

            mem_enable_EX   <= '0;
            mem_write_EX    <= '0;
            ddr_enable_MA   <= '0;
            ddr_write_MA    <= '0;

            stack_write_EX  <= '0;
            stack_write_MA  <= '0;
            bram_write_MA <= '0;

            freg_write_EX   <= '0;
            freg_write_MA   <= '0;
            freg_write_WB   <= '0;
            freg_rdata1_EX  <= '0;
            freg_rdata2_EX  <= '0;
            freg_rdata2_MA  <= '0;
            freg_rdata3_EX  <= '0;

            imm_ext1_EX     <= '0;
            imm_ext2_EX     <= '0;
            result_MA       <= '0;
            result_WB       <= '0;

            branch_predict_EX   <= '0;
            branch_predict_MA   <= '0;
            branch_result_MA    <= '0;

            input_enable_EX  <= '0;
            input_enable_MA  <= '0;
            output_enable_EX <= '0;
            output_enable_MA <= '0;

            fpu_enable_EX   <= '0;

            end_EX          <= '0;
            end_MA          <= '0;
            end_WB          <= '0;
        end else begin
            if (start) begin
                busy <= 1'b1;
            end
            if (end_WB) begin
                busy <= 1'b0;
            end

            pc_IF_reg       <= stall ? pc_IF_reg : ~busy ? 16'b0 : pc_IF + 16'b1;
            flush_IF_after  <= stall ? flush_IF_after : flush_IF;
            
            // IF -> ID
            pc_ID           <= stall ? pc_ID : pc_IF;

            // ID -> EX
            pc_EX           <= stall ? pc_EX : pc_ID;
            jump_pc_EX_reg  <= stall ? jump_pc_EX : jump_pc_ID;
            rd_EX           <= stall ? rd_EX : rd_ID;
            funct3_EX       <= stall ? funct3_EX : funct3_ID;
            funct5_EX       <= stall ? funct5_EX : funct5_ID;
            result_src_EX   <= stall ? result_src_EX : result_src_ID;
            mem_write_EX    <= stall ? mem_write_EX : mem_write_ID; 
            stack_write_EX  <= stall ? stack_write_EX : stack_write_ID;
            alu_control_EX  <= stall ? alu_control_EX : alu_control_ID;
            alu_src2_EX     <= stall ? alu_src2_EX : alu_src2_ID;
            imm_ext1_EX     <= stall ? imm_ext1_EX : imm_ext1_ID;
            imm_ext2_EX     <= stall ? imm_ext2_EX : imm_ext2_ID;
            branch_predict_EX <= non_hazard_stall ? branch_predict_EX : branch_predict_ID;

            // stallの2サイクル目以降は0にするもの
            fpu_enable_EX   <= stall ? 1'b0 : fpu_enable_ID;
            
            // bubbleとなったとき(flush or hazard)に0にするもの
            pc_src_EX       <= stall ? pc_src_EX : flush_ID ? 2'b00 : pc_src_ID;
            mem_enable_EX   <= non_hazard_stall ? mem_enable_EX :
                               flush_ID || hazard_stall ? 1'b0 : mem_enable_ID;
            reg_write_EX    <= non_hazard_stall ? reg_write_EX :
                               flush_ID || hazard_stall ? 1'b0 : reg_write_ID;
            freg_write_EX   <= non_hazard_stall ? freg_write_EX :
                               flush_ID || hazard_stall ? 1'b0 : freg_write_ID;
            input_enable_EX <= non_hazard_stall ? input_enable_EX : 
                               flush_ID || hazard_stall ? 1'b0 : input_enable_ID;
            output_enable_EX <= non_hazard_stall ? output_enable_EX : 
                               flush_ID || hazard_stall ? 1'b0 : output_enable_ID;
            forward1_EX     <= non_hazard_stall ? forward1_EX : 
                               flush_ID || hazard_stall ? 2'b0 : forward1_ID;

            // forwardingを適用するもの
            reg_rdata1_EX   <= stall ? reg_rdata1_EX : forwarded_reg_rdata1_ID;
            reg_rdata2_EX   <= stall ? reg_rdata2_EX : forwarded_reg_rdata2_ID;
            freg_rdata1_EX  <= stall ? freg_rdata1_EX : forwarded_freg_rdata1_ID;
            freg_rdata2_EX  <= stall ? freg_rdata2_EX : forwarded_freg_rdata2_ID;
            freg_rdata3_EX  <= stall ? freg_rdata3_EX : forwarded_freg_rdata3_ID;

            // Others
            end_EX          <= flush_ID ? 1'b0 : (~stall) & (inst_ID == EOF) ? 1'b1 : 1'b0;

            // EX -> MA
            pc_MA           <= non_hazard_stall ? pc_MA : pc_EX;
            jump_pc_MA      <= non_hazard_stall ? jump_pc_MA : jump_pc_EX;
            rd_MA           <= non_hazard_stall ? rd_MA : rd_EX;
            pc_src_MA       <= non_hazard_stall ? pc_src_MA : pc_src_EX;
            reg_write_MA    <= non_hazard_stall ? reg_write_MA : reg_write_EX;
            reg_rdata1_MA   <= non_hazard_stall ? reg_rdata1_MA : reg_rdata1_EX;     
            reg_rdata2_MA   <= non_hazard_stall ? reg_rdata2_MA : reg_rdata2_EX;
            freg_write_MA   <= non_hazard_stall ? freg_write_MA : freg_write_EX;
            freg_rdata2_MA  <= non_hazard_stall ? freg_rdata2_MA : freg_rdata2_EX;
            alu_result_MA   <= non_hazard_stall ? alu_result_MA : alu_result_EX;
            input_enable_MA <= non_hazard_stall ? input_enable_MA : input_enable_EX;
            result_MA       <= non_hazard_stall ? result_MA_suppl : result_EX;
            branch_predict_MA <= non_hazard_stall ? branch_predict_MA : branch_predict_EX;
            branch_result_MA <= non_hazard_stall ? branch_result_MA : branch_result_EX;
            end_MA          <= non_hazard_stall ? end_MA : end_EX;

            // メインメモリとしてBRAMを用いる場合はresult_srcを変更する必要がある
            result_src_MA   <= non_hazard_stall ? result_src_MA : 
                               use_bram_for_mem_EX && result_src_EX == 3'b001 ? 3'b110 : result_src_EX;

            // stallの2サイクル目以降は0にするもの
            read_fpu_MA     <= non_hazard_stall ? 1'b0 : (result_src_EX == 3'b011);
            stack_write_MA  <= non_hazard_stall ? 1'b0 : stack_write_EX;
            bram_write_MA   <= non_hazard_stall ? 1'b0 : 
                               use_bram_for_mem_EX ? mem_write_EX : 1'b0;

            // stallの2サイクル目以降は0にするが、output_stallの時のみは維持しなくてはならないもの
            output_enable_MA <= output_stall ? output_enable_MA : 
                                non_hazard_stall ? 1'b0 : output_enable_EX;

            // stallの2サイクル目以降は0にするが、memory_stallの時のみは維持しなくてはならないもの
            ddr_enable_MA   <= memory_stall ? ddr_enable_MA : 
                               non_hazard_stall ? 1'b0 : 
                               use_bram_for_mem_EX ? 1'b0 : mem_enable_EX;
            ddr_write_MA    <= memory_stall ? ddr_write_MA : 
                               non_hazard_stall ? 1'b0 : mem_write_EX;

            // MA -> WB
            rd_WB           <= non_hazard_stall ? rd_WB : rd_MA;
            reg_write_WB    <= non_hazard_stall ? 1'b0 : reg_write_MA;
            freg_write_WB   <= non_hazard_stall ? 1'b0 : freg_write_MA;
            result_src_WB   <= non_hazard_stall ? result_src_WB : result_src_MA;
            result_WB       <= non_hazard_stall ? result_WB_suppl : result_MA_suppl;
            end_WB          <= non_hazard_stall ? 1'b0 : end_MA;
        end
    end
endmodule

`default_nettype wire
