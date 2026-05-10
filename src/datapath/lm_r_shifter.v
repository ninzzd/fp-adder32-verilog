module lm_r_shifter
#(
    parameter lm = 23, le = 8
)
(
    input [lm:0] in,
    input [le-1:0] shamt,
    output [lm+3:0] out
);
    genvar i;
    wire [le-1:0] shamt_;
    wire s_add_cout;
    wire [$clog2(lm+4)-1:0] shamt_sub_3;
    wire [lm:0] s_in;
    wire [lm-1:0] in_or;
    wire temp_s;
    wire [le-1:0] lm_add_3;
    assign lm_add_3 = lm + 3;

    min #(
        .W(le)
    ) shamt_min (
        .a(shamt),
        .b(lm_add_3),
        .out(shamt_)
    );

    generate
        for(i = 0; i <= lm; i = i + 1) begin: shifter_gen
            if(i == 0)begin
                mux #(
                    .N(lm+1),
                    .W(1)
                ) shifter_mux (
                    .in(in[lm:i]), // shift in zeros
                    .sel(shamt_[$clog2(lm)-1:0]),
                    .out(out[i+3])
                );
            end
            else begin
                mux #(
                    .N(lm+1),
                    .W(1)
                ) shifter_mux (
                    .in({{i{1'b0}},in[lm:i]}), // shift in zeros
                    .sel(shamt_[$clog2(lm)-1:0]),
                    .out(out[i+3])
                );
            end
        end
    endgenerate

    mux #(
        .N(lm+1),
        .W(1)
    ) g_mux ( // selecter for ground bit
        .in({in[lm-1:0],1'b0}),
        .sel(shamt_[$clog2(lm+1)-1:0]),
        .out(out[2])
    );

    mux #(
        .N(lm+2),
        .W(1)
    ) r_mux ( // selecter for round bit
        .in({in[lm-1:0],2'b00}),
        .sel(shamt_[$clog2(lm+2)-1:0]),
        .out(out[1])
    );

    generate // OR ripple, passed as inputs to s_mux
        for(i = 0; i <= lm; i = i + 1) begin: s_in_gen
            if(i == 0)
                assign s_in[i] = in[i];
            else
            begin 
                if(i == 1)
                    assign in_or[i-1] = in[i] | in[i-1]; 
                else
                    assign in_or[i-1] = in[i] | in_or[i-2];
                assign s_in[i] = in_or[i-1];
            end
        end
    endgenerate

    localparam ONEEXT = $clog2(lm+4)-2;
    add #(
        .W($clog2(lm+4))
    ) shamt_sub (
        .a(shamt_[$clog2(lm+4)-1:0]),
        .b({{ONEEXT{1'b1}},2'b01}),
        .cin(1'b0),
        .s(shamt_sub_3),
        .cout(s_add_cout)
    );
    
    mux #(
        .N(lm+1),
        .W(1)
    ) s_mux ( // selecter for sticky bit
        .in({s_in}),
        .sel(shamt_sub_3[$clog2(lm+1)-1:0]),
        .out(temp_s)
    );
    assign out[0] = (temp_s === 1'bX ? 1'b1 : temp_s) & s_add_cout; // only for simulation 
endmodule