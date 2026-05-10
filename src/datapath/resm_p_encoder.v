module resm_p_encoder
#(
    parameter le = 8, lm = 23
)(
    input [lm+3:0] resm,
    output isZero,
    output [le-1:0] shamt
);
    wire [lm+3:0] f [0:le-1]; // le-1 priority functions, each function having lm+4 outputs corresponding to each priority level
    wire [le-1:0] rev_shamt;
    wire [le-1:0] lm_;
    genvar i;
    genvar j;
    generate
        for (i = 0;i < le; i = i + 1) begin : gen_priority
            for(j = 0;j < lm+4;j = j + 1)begin
                wire temp;
                assign temp = j >> i;
                assign f[i][j] = temp; // not real right shifting, precomputing priority functions
            end
            p_encoder #(.N(lm+4)) pe (
                .in(resm),
                .f(f[i]),
                .out(rev_shamt[i])
            );
        end
    endgenerate
    assign isZero = ~|(resm); // reduction NOR of all bits
    assign lm_ = lm[le-1:0]+{{(le-2){1'b0}},3'b11};
    add #(
        .W(le)
    ) shamt_sub(
        .a(lm_),
        .b(~rev_shamt),
        .cin(1'b1),
        .cout(),
        .s(shamt)
    );
endmodule