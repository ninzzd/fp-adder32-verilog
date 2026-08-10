// Detects qNaN/sNaN/Inf operands and produces the bypass result + select for the main-datapath mux
module special_op #(
    parameter lm = 23, le = 8
)(
    input [lm+le:0] a,
    input [lm+le:0] b,
    input op,

    output [1:0] out // 0 - pass: main datapath rseult, 1 - pass: (a0s) inf. 2 - qNaN
);

    wire a_is_inf, a_is_nan, a_is_snan, a_is_qnan;
    wire b_is_inf, b_is_nan, b_is_snan, b_is_qnan;

    assign a_is_inf = &(a[lm+le-1:lm]) & ~|(a[lm-1:0]);
    assign b_is_inf = &(b[lm+le-1:lm]) & ~|(b[lm-1:0]);
    assign a_is_snan = &(a[lm+le-1:lm]) & ~a[lm-1] & |(a[lm-2:0]);
    assign b_is_snan = &(b[lm+le-1:lm]) & ~b[lm-1] & |(b[lm-2:0]);
    assign a_is_qnan = &(a[lm+le-1:lm]) & a[lm-1] & ~|(a[lm-2:0]);
    assign b_is_qnan = &(b[lm+le-1:lm]) & b[lm-1] & ~|(b[lm-2:0]);

    assign is_nan = a_



    // TODO: a_is_inf  = (exponent of a is all 1s) & (mantissa of a is 0)
    // TODO: a_is_nan  = (exponent of a is all 1s) & (mantissa of a != 0)
    // TODO: a_is_snan = a_is_nan & ~a[lm-1] (mantissa MSB 0 => signaling NaN)
    // TODO: a_is_qnan = a_is_nan & a[lm-1]
    // TODO: mirror the above for b

    // TODO: is_nan        = any operand is NaN (sNaN takes priority per IEEE-754), or an invalid inf op (e.g. inf - inf)
    // TODO: is_inf        = an operand is inf, propagated when the other operand doesn't force a NaN result
    // TODO: res_inf_sign  = sign of the propagated infinity, accounting for `op`
    // TODO: bypass        = is_nan | is_inf

endmodule
