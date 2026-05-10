module resm_round #(
    parameter lm = 23
)(
    input [lm+3:0] resm_bround,
    output [lm:0] resm,
    output inc_cout
);
    wire round_up;
    assign round_up = resm_bround[2]&(resm_bround[1] | resm_bround[0] | resm_bround[3]); // round-even (to-nearest-even with LSB = 0)

    inc #(
        .W(lm+1)
    ) resm_inc (
        .cin(round_up),
        .in(resm_bround[lm+3:3]),
        .out(resm),
        .cout(inc_cout)
    );
endmodule