// General multiple-input single-output (MISO) priority encoder 
module p_encoder
#(
    parameter N = 4
)
(
    input [N-1:0] in,
    input [N-1:0] f, // output bits corresponding to each priority level
    output out
);
    wire [N-1:0] t;
    genvar i;
    generate
        for(i = 1;i <= N;i = i + 1) begin: func_gen
            if(i == N)
                assign t[i-1] = in[i-1] & f[i-1];
            else
                assign t[i-1] = &(~in[N-1:i]) & in[i-1] & f[i-1];
        end
    endgenerate
    assign out = |t;
endmodule