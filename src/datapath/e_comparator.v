// Exponent comparator
module e_comparator
#( parameter le = 8)
(
    input [le-1:0] a,
    input [le-1:0] b,
    output a_ge_b,
    output [le-1:0] m_shamt,
    output [le-1:0] a0e // the larger exponent
);
    wire [le-1:0] t_shamt;
    add #(.W(le)) adder (
        .a(a),
        .b(~b),
        .cin(1'b1),
        .s(t_shamt),
        .cout(a_ge_b)
    );
    inc #(.W(le)) inc (
        .cin(~a_ge_b),
        .in(t_shamt ^ {le{~a_ge_b}}), // if a >= b, pass a - b, else pass b - a
        .out(m_shamt),
        .cout()
    );
    mux #(
        .W(le),
        .N(2)
    ) a0e_mux(
        .in({a,b}),
        .sel(a_ge_b),
        .out(a0e)
    );
endmodule
