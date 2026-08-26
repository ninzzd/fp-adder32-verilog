// Detects qNaN/sNaN/Inf (special) operands and produces the bypass result + select for the main-datapath mux
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
    wire maddop; // later, remove this wire and input from fpadd module

    assign a_is_inf = &(a[lm+le-1:lm]) & ~|(a[lm-1:0]);
    assign b_is_inf = &(b[lm+le-1:lm]) & ~|(b[lm-1:0]);
    assign a_is_snan = &(a[lm+le-1:lm]) & ~a[lm-1] & |(a[lm-2:0]);
    assign b_is_snan = &(b[lm+le-1:lm]) & ~b[lm-1] & |(b[lm-2:0]);
    assign a_is_qnan = &(a[lm+le-1:lm]) & a[lm-1];
    assign b_is_qnan = &(b[lm+le-1:lm]) & b[lm-1];
    assign a_is_nan = a_is_snan | a_is_qnan;
    assign b_is_nan = b_is_snan | b_is_qnan;

    assign maddop = a[lm+le] ^ b[lm+le] ^ op;

    assign out = a_is_nan | b_is_nan ? 2'b10 : a_is_inf & b_is_inf & maddop ? 2'b10 : a_is_inf | b_is_inf ? 2'b01 : 2'b00; // 3rd condition (when result must ne +/-inf): what about sign?
    

endmodule
