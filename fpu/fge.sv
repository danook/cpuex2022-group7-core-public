`default_nettype none

module fge (
        input wire [31:0]   x1,
        input wire [31:0]   x2,
        output wire         y
    );

    //0.
    wire s1, s2;
    wire [7:0] e1, e2;
    wire [22:0] m1, m2;
    assign {s1,e1,m1} = x1;
    assign {s2,e2,m2} = x2;

    //1.
    // zにはfltの結果が入るので、yはその反転
    assign y =  (s1==0&&s2==0) ? ((e1==e2) ? m1 >= m2 : e1 >= e2) :
                (s1==0&&s2==1) ? 1'b1 :
                (s1==1&&s2==0) ? 1'b0 : ((e1==e2) ? m1 <= m2 : e1 <= e2);

endmodule

`default_nettype wire
