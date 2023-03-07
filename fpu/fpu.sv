`default_nettype none
module fpu (
        input wire          clk,
        input wire          rstn,
        input wire [31:0]   fsrc1,
        input wire [31:0]   fsrc2,
        /* verilator lint_off UNUSED */
        input wire [31:0]   fsrc3,
        /* verilator lint_on UNUSED */
        input wire [31:0]   src1,
        input wire [4:0]    funct5_EX,
        input wire [2:0]    funct3_EX,
        input wire          fpu_enable,
        output logic        stall,
        output logic [31:0] result_reg,
        output logic        branch_result
    );

    localparam FADD     = 5'b00000;
    localparam FSUB     = 5'b00001;
    localparam FMUL     = 5'b00010;
    localparam FDIV     = 5'b00011;
    localparam FSQRT    = 5'b00100;
    localparam FHALF    = 5'b00101;
    localparam FSGNJ    = 5'b00110;
    localparam FSGNJN   = 5'b00111;
    localparam FSGNJX   = 5'b01000;
    localparam FFLOOR   = 5'b01001;
    localparam FINV     = 5'b01011;
    // localparam FFRAC    = 5'b01100;
    localparam FTOI     = 5'b10001;
    localparam ITOF     = 5'b11001;
    localparam FCOMP    = 5'b10100;

    // stallする段数 (=パイプラインの段数 - 1)。0のものは定義していない
    localparam FADD_CYCLES = 4;
    localparam FSUB_CYCLES = 4;
    localparam FMUL_CYCLES = 1;
    localparam FDIV_CYCLES = 10;
    localparam FSQRT_CYCLES = 7;
    localparam FHALF_CYCLES = 1;
    localparam FINV_CYCLES = 7;
    localparam FFLOOR_CYCLES = 7;
    localparam FTOI_CYCLES = 1;
    localparam ITOF_CYCLES = 3;
    localparam FMADD_CYCLES = 6;

    logic [3:0] fpu_cycles;

    /* verilator lint_off UNUSED */
    logic fadd_ovf;
    logic fsub_ovf;
    logic fmul_ovf;
    logic fdiv_ovf;
    logic fsqrt_ovf;
    /* verilator lint_on UNUSED */

    logic [31:0] fadd_result;
    logic [31:0] fsub_result;
    logic [31:0] fmul_result;
    logic [31:0] fdiv_result;
    logic [31:0] fsqrt_result;
    logic [31:0] fhalf_result;
    logic [31:0] finv_result;
    logic [31:0] ffloor_result;
    logic [31:0] fmadd_result;
    logic [31:0] fmsub_result;
    logic [31:0] ftoi_result;
    logic [31:0] itof_result;
    logic        flt_result;
    logic        fge_result;
    logic        fnez_result;
    logic        feqz_result;
    logic        fgtz_result;
    logic        fltz_result;

    // FPUの結果が用意できるまでのカウントダウン
    logic [3:0] counter;

    wire [31:0] result;
    always @(posedge clk) begin
        result_reg <= result;
    end

    assign fpu_cycles =
        funct3_EX != 3'b000 && funct5_EX[4] == 1'b0 ? FMADD_CYCLES :
        funct5_EX == FADD ? FADD_CYCLES :
        funct5_EX == FSUB ? FSUB_CYCLES :
        funct5_EX == FMUL ? FMUL_CYCLES :
        funct5_EX == FDIV ? FDIV_CYCLES :
        funct5_EX == FSQRT ? FSQRT_CYCLES :
        funct5_EX == FFLOOR ? FFLOOR_CYCLES :
        funct5_EX == ITOF ? ITOF_CYCLES :
        funct5_EX == FTOI ? FTOI_CYCLES :
        funct5_EX == FHALF ? FHALF_CYCLES :
        funct5_EX == FINV ? FINV_CYCLES : 4'b0;

    assign result =
        funct3_EX != 3'b000 ? (
            funct5_EX[4] == 1'b1 ? {31'b0, branch_result} :
            // 複合命令
            funct3_EX == 3'b001 ? fmadd_result :
            funct3_EX == 3'b010 ? fmsub_result :
            funct3_EX == 3'b101 ? {~fmsub_result[31], fmsub_result[30:0]} :     // fnmadd
            /* funct3_EX == 3'b110 */ {~fmadd_result[31], fmadd_result[30:0]}   // fnmsub
        ) :
        funct5_EX == FADD      ? fadd_result :
        funct5_EX == FSUB      ? fsub_result :
        funct5_EX == FMUL      ? fmul_result :
        funct5_EX == FDIV      ? fdiv_result :
        funct5_EX == FSQRT     ? fsqrt_result :
        funct5_EX == FHALF     ? fhalf_result :
        funct5_EX == FINV      ? finv_result :
        funct5_EX == FFLOOR    ? ffloor_result :
        funct5_EX == FTOI      ? ftoi_result :
        funct5_EX == ITOF      ? itof_result :
        funct5_EX == FSGNJ     ? {fsrc2[31], fsrc1[30:0]} :
        funct5_EX == FSGNJN    ? {~fsrc2[31], fsrc1[30:0]} :
        /* funct5_EX == FSGNJX */ {fsrc1[31] ^ fsrc2[31], fsrc1[30:0]};

    assign branch_result =
        funct3_EX == 3'b001 ? flt_result :
        funct3_EX == 3'b010 ? fge_result :
        funct3_EX == 3'b111 ? fnez_result :
        funct3_EX == 3'b100 ? feqz_result :
        funct3_EX == 3'b101 ? fgtz_result :
        // funct3_EX == 3'b110
                              fltz_result;

    assign stall = counter != 4'b0 || (fpu_enable == 1'b1 && fpu_cycles != 0) ? 1'b1 : 1'b0;

    fadd _fadd (
        fsrc1,
        fsrc2,
        fadd_result,
        clk
    );

    fsub _fsub (
        fsrc1,
        fsrc2,
        fsub_result,
        clk
    );

    fmul _fmul (
        fsrc1,
        fsrc2,
        fmul_result,
        clk
    );

    fdiv _fdiv (
        fsrc1,
        fsrc2,
        fdiv_result,
        clk
    );

    fsqrt _fsqrt (
        fsrc1,
        fsqrt_result,
        clk
    );

    fhalf _fhalf (
        fsrc1,
        fhalf_result
    );

    finv _finv (
        fsrc1,
        finv_result,
        clk
    );

    ffloor _ffloor (
        fsrc1,
        ffloor_result,
        clk
    );

    fmadd _fmadd (
        fsrc1,
        fsrc2,
        fsrc3,
        fmadd_result,
        clk
    );

    fmsub _fmsub (
        fsrc1,
        fsrc2,
        fsrc3,
        fmsub_result,
        clk
    );

    fcvtws _ftoi (
        fsrc1,
        ftoi_result,
        clk
    );

    fcvtsw _itof (
        src1,
        itof_result,
        clk
    );

    flt _flt (
        fsrc1,
        fsrc2,
        flt_result
    );

    fge _fge (
        fsrc1,
        fsrc2,
        fge_result
    );

    fnez _fnez (
        fsrc1,
        fnez_result
    );

    feqz _feqz (
        fsrc1,
        feqz_result
    );

    fgtz _fgtz (
        fsrc1,
        fgtz_result
    );

    fltz _fltz (
        fsrc1,
        fltz_result
    );

    always @(posedge clk) begin
        if (~rstn) begin
            counter <= 4'b0;
        end else begin
            if (fpu_enable) begin
                counter <= fpu_cycles == 0 ? 0 : fpu_cycles - 1;
            end
            if (counter > 0) begin
                counter <= counter - 1;
            end
        end
    end
endmodule

`default_nettype wire
