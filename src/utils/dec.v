// Ripple carry decrementer for exponent (positive operand, does not require 2s complement for negative results)
module dec #(
    parameter W = 8
)(
    // no need for optional decrement anywhere, decrement a0e always, cin input not required
    input [W-1:0] in,
    output [W-1:0] out
);
    wire [W-1:0] c; // intermediate carrys
    genvar i;
    generate
        for(i = 0;i < W;i = i+1)
        begin: gen_loop
            if(i == 0)
            begin
                assign out[i] = ~in[i];
                assign c[i] = in[i];
            end
            else 
            begin
                assign out[i] = ~(in[i] ^ c[i-1]);
                assign c[i] = c[i-1] | in[i];
            end
        end
    endgenerate
endmodule