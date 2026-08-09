// Combinatorial decrementer without carry-in
module dec #(
    parameter W = 8
)(
    // no need for optional decrement anywhere, decrement a0e always, cin input not required
    input [W-1:0] in,
    output [W-1:0] out
);
    genvar i;
    generate
        for(i = 0;i < W;i = i+1)
        begin: gen_loop
            if(i == 0)
                assign out[i] = ~in[i];
            else 
                assign out[i] = (~in[i]) ^ (|in[i-1:0]);
        end
    endgenerate

endmodule