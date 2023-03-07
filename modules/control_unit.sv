`default_nettype none

module control_unit (
        input wire [3:0]    opcode,
        input wire [2:0]    funct3,
        input wire [1:0]    funct2,
        output wire [1:0]   pc_src,         // 次のPCにどの値を用いるか
        output wire [2:0]   result_src,     // レジスタにどの結果をwriteするか
        output wire         mem_enable,     // メインメモリにアクセスするか
        output wire         mem_write,      // メインメモリに書き込むか
        output wire         stack_write,    // stackに書き込むか
        output wire [2:0]   alu_control,    // ALUのどの結果を用いるか
        output wire         reg_src1,       // 読みだすレジスタファイルの種類 ハザード対応用
        output wire         reg_src2,       // 読みだすレジスタファイルの種類 ハザード対応用
        output wire         reg_src3,       // 読みだすレジスタファイルの種類 ハザード対応用
        output wire [1:0]   alu_src2,       // ALUの入力
        output wire [1:0]   imm_src,        // 即値のフォーマットの種類
        output wire         reg_write,      // レジスタに書き込むか
        output wire         freg_write,     // fregに書き込むか
        output wire         input_enable,   // 入力を読み進めるか
        output wire         output_enable,  // 出力を書き進めるか
        output wire         use_fpu         // FPUで演算を行うか
    );

    localparam ALU          = 4'b0000;
    localparam FPU          = 4'b0001;
    localparam ALUIMM       = 4'b0010;
    localparam IO           = 4'b0011;
    localparam STORE        = 4'b0100;
    localparam FSTORE       = 4'b0101;
    localparam LOAD         = 4'b0110;
    localparam FLOAD        = 4'b0111;
    localparam BRANCH       = 4'b1000;
    localparam FBRANCH      = 4'b1001;
    localparam BRANCHIMM    = 4'b1100;
    localparam JAL          = 4'b1110;
    localparam JALR         = 4'b1010;
    
    assign pc_src = 
        // 00: no jump, 01: jal, 10: jalr, 11: branch
        opcode == JALR ? 2'b10 :
        opcode == JAL ? 2'b01 :
        opcode == BRANCH || opcode == FBRANCH || opcode == BRANCHIMM ? 2'b11 : 2'b00;

    assign result_src =
        // 000: ALU result, 001: heap read data, 010: next PC, 011: FPU result, 
        // 100: input, 101: stack read data, 110: global read data
        opcode == LOAD || opcode == FLOAD ? (
            // funct3 = 001 -> global, 010 -> heap, 100 -> stack
            // heapかglobalはコンパイル時の判断が難しいので、ここでは同一と扱い、
            // EXステージでアドレスを計算したのち判断する
            funct3 == 3'b100 ? 3'b101 : 3'b001
        ) :
        opcode == JAL || opcode == JALR ? 3'b010 : 
        opcode == FPU || opcode == FBRANCH || opcode == FSTORE  ? 3'b011 : 
        opcode == IO && funct3 != 3'b010 ? 3'b100 : 3'b000;

    assign mem_enable =
        (opcode == LOAD || opcode == STORE ||
        opcode == FLOAD || opcode == FSTORE) && funct3 != 3'b100 ? 1'b1 : 1'b0;

    assign mem_write    = (opcode == STORE || opcode == FSTORE) && funct3 != 3'b100 ? 1'b1 : 1'b0;
    assign stack_write  = (opcode == STORE || opcode == FSTORE) && funct3 == 3'b100 ? 1'b1 : 1'b0;

    assign alu_control = 
        opcode == LOAD || opcode == STORE || 
        opcode == FLOAD || opcode == FSTORE ? 3'b000 : funct3;

    assign reg_src1 =
        // 0: int regfile, 1: float regfile
        (opcode == FPU && funct2 != 2'b11) || opcode == FBRANCH ? 1'b1 : 1'b0;
    assign reg_src2 =
        // 0: int regfile, 1: float regfile
        (opcode == FPU && funct2 != 2'b11) || opcode == FBRANCH || opcode == FSTORE ? 1'b1 : 1'b0;
    assign reg_src3 =
        // 0: unused (to avoid unnecessary hazard stalls), 1: float regfile
        opcode == FPU && funct2[1] == 1'b0 && funct3 != 3'b000 ? 1'b1 : 1'b0;

    assign alu_src2 = 
        // 00: register, 01: imm1, 10: imm2
        opcode == LOAD || opcode == STORE || 
        opcode == FLOAD || opcode == FSTORE || 
        opcode == ALUIMM ? 2'b01 :
        opcode == BRANCHIMM ? 2'b10 : 2'b00;
    
    assign imm_src = 
        // 00: I, 01: S, 10: BP, 11: J
        // 2'b11 when opcode == JALR
        opcode == ALUIMM || opcode == LOAD || opcode == FLOAD || opcode == JALR ? 2'b00 :
        opcode == STORE || opcode == FSTORE                                     ? 2'b01 :
        opcode == BRANCH || opcode == FBRANCH || opcode == BRANCHIMM            ? 2'b10 : 2'b11;

    assign reg_write = 
        opcode == JAL || opcode == JALR ||
        opcode == LOAD || opcode == ALUIMM || opcode == ALU ||
        (opcode == IO && funct3 == 3'b001) || (opcode == FPU && funct2 == 2'b10) ? 1'b1 : 1'b0;
    
    assign freg_write = 
        (opcode == FPU && funct2 != 2'b10) || opcode == FLOAD || 
        (opcode == IO && funct3 == 3'b100) ? 1'b1 : 1'b0;

    assign input_enable = opcode == IO && funct3 != 3'b010 ? 1'b1 : 1'b0;
    assign output_enable = opcode == IO && funct3 == 3'b010 ? 1'b1 : 1'b0;

    assign use_fpu     = opcode == FPU ? 1'b1 : 1'b0;
endmodule

`default_nettype wire