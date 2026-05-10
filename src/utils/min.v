module min
#(
    parameter W = 32
)
(
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] out
);
    genvar k;
    wire [W-1:0] bcmp;
    wire cout; // The output carry of a - b
    wire [W-1:0] p; // propagate
    wire [W-1:0] g; // generate
    wire p_red; // reduced AND of propagate
    wire [W-1:0] gp; // terms with g AND p in cout
    wire sel;

    assign bcmp = ~b;
    assign p = a | bcmp;
    assign g = a & bcmp;
    generate
        for(k = 0; k <= W-1; k = k + 1) begin: group_gen
            wire gp_red; // reduction AND of p terms in each group term
            if (k == 0)
                assign gp_red = 1'b1;
            else
                assign gp_red = &p[W-1:W-k];
            assign gp[k] = g[W-1-k] & gp_red;
        end
    endgenerate
    assign p_red = &p;
    assign cout = (|gp) | p_red; // cin is always 1
    mux #(
        .N(2),
        .W(W)
    ) minmax_mux (
        .in({b, a}),
        .sel(cout),
        .out(out)
    );

endmodule