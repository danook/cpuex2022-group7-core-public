`default_nettype none

module alu (
        input wire [31:0]   src1,
        input wire [31:0]   src2,
        input wire [2:0]    funct3,
        output wire [31:0]  result,
        output wire         branch_result
    );

    assign result =
        funct3 == 3'b000 ?  src1 + src2 :
        funct3 == 3'b001 ?  ($signed(src1) < $signed(src2) ? src1 : src2) :
        funct3 == 3'b010 ?  src1 << src2[4:0] :
        funct3 == 3'b011 ?  ($signed(src1) < $signed(src2) ? src2 : src1) :
        /* funct3 == 3'b100 ? */ src1 ^ src2;
    
    assign branch_result =
        funct3 == 3'b000 ?  src1 == src2 :
        funct3 == 3'b001 ?  src1 != src2 :
        funct3 == 3'b010 ?  (src1 != 0) ^ (src2 != 0) :
        funct3 == 3'b011 ?  (src1 != 0) ~^ (src2 != 0) :
        funct3 == 3'b100 ?  $signed(src1) < $signed(src2) :
        funct3 == 3'b101 ?  $signed(src1) >= $signed(src2) :
        funct3 == 3'b110 ?  $signed(src1) > $signed(src2) :
        /* funct3 == 3'b111 ? */ $signed(src1) <= $signed(src2);

endmodule

`default_nettype wire