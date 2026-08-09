// Combinatorial incrementer with carry-in
module inc #(
   parameter W = 8
)(
    input cin,
    input [W-1:0] in,
    output [W-1:0] out,
    output cout
);
    genvar i;
    generate
        for(i = 0; i < W; i = i + 1) begin: inc_loop
            if(i == 0)
                assign out[i] = in[i] ^ cin;
            else
                assign out[i] = in[i] ^ (cin & (&(in[i-1:0])));
        end
    endgenerate
    assign cout = cin & (&in[W-1:0]); // carry out is the last carry
endmodule