`timescale 1 ns / 1 ps
module comp8 #(parameter T = 0.000)(
    input [7:0] a,
    input [7:0] b,
    output a_lt_b,
    output a_eq_b,
    output a_gt_b,
    output [7:0] abs_diff
);
    wire cout;
    wire ne;
    wire [7:0] s;
    add8 #(.T(T)) adder1(
        .a(a),
        .b(~b),
        .c_1(1'b1),
        .c7(cout),
        .s(s)
    );
    assign #(T) ne = s[7]|s[6]|s[5]|s[4]|s[3]|s[2]|s[1]|s[0];
    assign a_eq_b = ~ne;
    assign #(T) a_gt_b = ne&cout;
    assign #(T) a_lt_b = ne&~cout;
    add8 #(.T(T)) adder2(
        .a(s^{8{a_lt_b}}),
        .b(8'b00000000),
        .c_1(a_lt_b),
        .s(abs_diff)
    );
endmodule
