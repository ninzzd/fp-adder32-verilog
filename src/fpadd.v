// Floating-Point Adder/Subtractor
module fpadd #(
    parameter le = 8, lm = 23
)(
    input [le+lm:0] a,
    input [le+lm:0] b,
    input op,
    output [le+lm:0] c
);
    wire [1:0] sop_out; // special operand unit output
    wire sop_out_or;
    wire na; // is 'a' normal
    wire nb; // is 'b' normal

    wire [lm:0] am; // complete mantissa of a with leading bit after decimal point
    wire [lm:0] bm; // complete mantissa of b with leading bit after decimal point
    wire [le-1:0] ae_adj; // Adjusted for subnormal case
    wire [le-1:0] be_adj;

    wire [lm:0] a0m;
    wire [le-1:0] a0e;
    wire [le-1:0] a0e_sub_1; // a0e - 1
    wire [lm:0] b0m;
    wire [lm+3:0] b0m_shifted;
    wire a0s;
    wire b0s;

    wire ageb;
    wire [le-1:0] b0_shamt;

    wire maddop;
    wire [lm+3:0] maddres;
    wire [lm+3:0] maddres_2s; // absolute value of maddres
    wire [lm+3:0] maddres_ls;
    wire [lm+3:0] maddres_rs;
    wire [lm+3:0] resm_bround;
    wire [lm:0] resm_around;
    wire [lm:0] resm;
    wire maddres_isZero;
    wire [le-1:0] maddres_lshamt;
    wire [le-1:0] a0e_lshamt_min;
    wire [le-1:0] resesub;
    wire [le-1:0] reseadd;
    wire [le-1:0] rese_bround;
    wire [le-1:0] rese_around;
    wire res_sign; // final result sign from main datapath
    wire res_notinf; // clear if result is inf due to overflow (add or round), set when res is not inf
    wire [le-1:0] res_exp; // final result exp from main datapath
    wire [lm-1:0] res_man; // final result mantissa from main datapath
    wire maddcout;
    wire flag;
    wire round_cout;
    wire resm_isSubnormal;

    special_op #(
        .lm(lm),
        .le(le)
    ) sop_unit(
        .a(a),
        .b(b),
        .op(op),
        .out(sop_out)
    );
    
    assign na = |(a[le+lm-1:lm]); // Reduction OR -> 0 iff all bits are 0 : Case of subnormal numbers ->  1 otherwise : Normal numbers (with NaN and inf being exceptions)
    assign nb = |(b[le+lm-1:lm]); 

    assign am = {na, a[lm-1:0]};
    assign bm = {nb, b[lm-1:0]};

    assign maddop = a[lm+le] ^ b[lm+le] ^ op;

    inc #(
        .W(le)
    ) ae_inc_sbnrm(
        .in(a[lm+le-1:lm]),
        .cin(~na),
        .out(ae_adj)
    );

    inc #(
        .W(le)
    ) be_inc_sbnrm(
        .in(b[lm+le-1:lm]),
        .cin(~nb),
        .out(be_adj)
    );

    mux #(.W(lm+1), .N(2)) a0m_mux (
        .in({am,bm}),
        .sel(ageb),
        .out(a0m)
    );

    mux #(.W(lm+1), .N(2)) b0m_mux (
        .in({bm,am}),
        .sel(ageb),
        .out(b0m)
    );

    mux #(.W(1), .N(2)) a0s_mux (
        .in({a[le+lm],b[le+lm]}),
        .sel(ageb),
        .out(a0s)
    );
    // b0s might be redundant
    mux #(.W(1), .N(2)) b0s_mux (
        .in({b[le+lm],a[le+lm]}),
        .sel(ageb),
        .out(b0s)
    );

    e_comparator #(.le(le)) exp_comp (
        .a(ae_adj),
        .b(be_adj),
        .a_ge_b(ageb),
        .m_shamt(b0_shamt),
        .a0e(a0e)
    );

    lm_r_shifter #(
        .le(le),
        .lm(lm)
    ) 
    b0_shifter (
        .in(b0m),
        .shamt(b0_shamt),
        .out(b0m_shifted)
    );

    add #(
        .W(lm+4)
    ) mantissa_adder (
        .a({a0m,3'b000}),
        .b({(lm+4){maddop}} ^ b0m_shifted), // XOR with maddop, for 1s comp (sub)
        .cin(maddop),
        .s(maddres),
        .cout(maddcout)
    );

    assign flag = ~maddcout&maddop; // if the result is negative, we need to take 2's complement
    
    inc #(
        .W(lm+4)
    ) mantissa_inc (
        .in({(lm+4){flag}} ^ maddres),
        .out(maddres_2s),
        .cin(flag)
    );

    resm_p_encoder #(
        .le(le),
        .lm(lm)
    ) resm_pe (
        .resm(maddres_2s),
        .isZero(maddres_isZero),
        .shamt(maddres_lshamt)
    );

    dec #(
        .W(le)
    ) a0e_dec (
        .in(a0e),
        .out(a0e_sub_1)
    );

    min #(
        .W(le)
    ) a0e_lshamt_cap (
        .a(a0e_sub_1), // intermediate representation of sub-normal requires for exp >= 1, non-zero
        .b(maddres_lshamt),
        .out(a0e_lshamt_min)
    );

    add #(
        .W(le)
    ) rese_sub (
        .a(a0e),
        .b(~a0e_lshamt_min),
        .cin(1'b1),
        .s(resesub),        // Important: 0 handling
        .cout()             // Important: 0 handling
    );

    inc #(
        .W(le)
    ) ince_add(
        .in(a0e),
        .cin(maddcout),
        .out(reseadd),
        .cout()             // Important: inf and NaN handling
    );

    resm_l_shifter #(
        .le(le),
        .lm(lm)
    ) resm_ls (
        .in(maddres_2s),
        .shamt(a0e_lshamt_min),
        .out(maddres_ls)
    );
    assign res_sign = (a0s ^ flag ^ (op&~ageb)) & ~(maddop & maddres_isZero); // sign of the result, IEEE 754 allows +/-0

    mux #(
        .W(lm+4),
        .N(2)
    ) add_resm_mux ( // Mux that handles the cases when mantissas are added (overflow or no overflow)
        .in({{maddcout,maddres_2s[lm+3:2],maddres_2s[1]|maddres_2s[0]},maddres_2s}), // input line for 1: right-shift-by-1 with preserved sticky-ness (S_{new} = R | S)
        .sel(maddcout),
        .out(maddres_rs)
    );

    mux #(
        .W(lm+4),
        .N(2)
    ) add_sub_resm_mux (
        .in({maddres_ls,maddres_rs}),
        .sel(maddop),
        .out(resm_bround) // result mantissa before rounding
    );

    resm_round #(
        .lm(lm)
    ) rrr (
        .resm_bround(resm_bround),
        .resm(resm_around),
        .inc_cout(round_cout)
    );

    mux #(
        .W(lm+1),
        .N(2)
    ) round_resm_mux (
        .in({{round_cout,resm_around[lm:2],resm_around[1]|resm_around[0]},resm_around}),
        .sel(round_cout),
        .out(resm)
    );

    mux #(
        .W(le),
        .N(2)
    ) add_sub_rese_mux (
        .in({resesub&{le{~maddres_isZero}},reseadd}), // Override exponent subtractor result to 0 if result mantissa is 0
        .sel(maddop),
        .out(rese_bround)
    );

    assign resm_isSubnormal = ~round_cout&~resm[lm]; // if round_cout=1, rounding overflow => result is clearly normal, or if round_cout = 0 and resm[lm]=1, result leading 1 exists => result is normal, else subnormal
    // exp has an added extra one when adjusting for sub-normal operands, which must be removed if result is also 
    inc #(
        .W(le)
    ) ince_round (
        .in(rese_bround),
        .cin(round_cout),
        .out(rese_around),
        .cout()
    );

    // main datapath inf handling
    assign res_exp = {rese_around[le-1:1],rese_around[0]&~resm_isSubnormal}; // may not be most optimal logic, can substitute for round_cout and resm[lm] directly if needed
    assign res_notinf = ~&(res_exp);
    assign res_man = resm[lm-1:0] & {lm{res_notinf}}; // rounding result with inf mask

    // special values (inf/nan) handling
    assign sop_out_or = |(sop_out);
    assign c[lm+le] = res_sign & ~sop_out[1];

    assign c[lm+le-1:lm] = res_exp | {le{sop_out_or}};
    
    mux #(
        .W(1),
        .N(2)
    ) manMSB_mux (
        .in({sop_out[1],res_man[lm-1]}),
        .sel(sop_out_or),
        .out(c[lm-1])
    );
    assign c[lm-2:0] = res_man[lm-2:0] & ~{(lm-1){sop_out_or}};
    
endmodule