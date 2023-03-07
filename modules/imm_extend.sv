`default_nettype none

module imm_extend (
        input wire          imm_sign,   // inst[31]
        input wire [5:0]    imm_frac1,  // inst[30:25]
        input wire [5:0]    imm_frac2,  // inst[24:19]
        input wire [5:0]    imm_frac3,  // inst[18:13]
        input wire [2:0]    imm_frac4,  // inst[12:10]
        input wire [5:0]    imm_frac5,  // inst[9:4]
        input wire [1:0]    imm_src,    // 00: I, 01: S, 10: BP, 11: J
        output wire [31:0]  imm_ext1,
        output wire [31:0]  imm_ext2
    );

    assign imm_ext1 = 
        imm_src == 2'b00 ?  {{20{imm_sign}}, imm_frac1, imm_frac2} :
        imm_src == 2'b01 ?  {{20{imm_sign}}, imm_frac1, imm_frac5} :
        imm_src == 2'b10 ?  {{18{imm_sign}}, imm_frac5[1:0], imm_frac1, imm_frac5[5:2], 2'b0} :
                            {{9{imm_sign}}, imm_frac3, imm_frac4, imm_frac2[1:0], imm_frac1, imm_frac2[5:2], 2'b0};
                            
    assign imm_ext2 = {{27{imm_frac2[5]}}, imm_frac2[4:0]};
endmodule

`default_nettype wire