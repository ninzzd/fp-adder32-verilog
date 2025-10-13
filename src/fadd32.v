module fadd32(
    input clk,
    input mode, // 0 - add (a + b), 1 - sub (a - b)
    input [31:0] a,
    input [31:0] b,
    output [31:0] res
);
    wire a_isnorm;
    wire b_isnorm;
    wire exp_altb;
    wire exp_aeqb;
    wire exp_agtb;
    wire [7:0] exp_absdiff;
    comp8 exp_comp(
        .a(a[30:23]),
        .b(b[30:23]),
        .a_eq_b(exp_aeqb),
        .a_lt_b(exp_altb),
        .a_gt_b(exp_agtb),
        .abs_diff(exp_absdiff)
    );
    wire [23:0] man1; // mantissa of the number with larger exponent
    wire [23:0] man2; // mantissa of the number with smaller exponent
    assign a_isnorm = a[30]|a[29]|a[28]|a[27]|a[26]|a[25]|a[24]|a[23]; // 0 - a is subnormal, 1 - a is normal
    assign b_isnorm = b[30]|b[29]|b[28]|b[27]|b[26]|b[25]|b[24]|b[23]; // 0 - b is subnormal, 1 - b is normal
    assign man1[22:0] = {23{exp_agtb}}&a[22:0] | {23{~exp_agtb}}&b[22:0];
    assign man1[23] = (exp_agtb)&(a_isnorm) | (~exp_agtb)&(b_isnorm);
    assign man2[22:0] = {23{exp_agtb}}&b[22:0] | {23{~exp_agtb}}&a[22:0];
    assign man2[23] = (exp_agtb)&(b_isnorm) | (~exp_agtb)&(a_isnorm);
endmodule