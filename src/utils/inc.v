// Ripple carry incrementer
module inc #(
   parameter W = 8
)(
    input cin,
    input [W-1:0] in,
    output [W-1:0] out,
    output cout
);
    wire [W-1:0] c;
    genvar i;
    generate
        for(i = 0; i < W; i = i + 1) begin: inc_loop
            if (i == 0)
            begin
                assign out[i] = in[i] ^ cin; // LSB is inverted
                assign c[i] = in[i] & cin; // carry is generated if LSB is 1
            end
            else
            begin
                assign out[i] = in[i] ^ c[i-1]; // other bits are XOR of input and carry
                assign c[i] = in[i] & c[i-1]; // carry generation
            end
        end
    endgenerate
    assign cout = c[W-1]; // carry out is the last carry
endmodule