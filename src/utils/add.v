// W-bit CLA adder
module add #(
    parameter W = 8
)(
    input [W-1:0] a,
    input [W-1:0] b,
    input cin,
    output [W-1:0] s,
    output cout
);
    wire [W-1:0] c;
    wire [W-1:0] p;
    wire [W-1:0] g;
    
    assign p = a | b; // propagate
    assign g = a & b; // generate
    assign cout = c[W-1];
    assign s[W-1:1] = a[W-1:1] ^ b[W-1:1] ^ c[W-2:0]; // sum bits
    assign s[0] = a[0] ^ b[0] ^ cin; // sum bit 0
    genvar i;
    genvar k;
    genvar j;
    generate
        for(i = 0; i < W; i = i + 1) begin: carry_gen
            wire [i:0] gp;
            for(k = 0; k <= i; k = k + 1) begin: group_gen
                wire gp_red;
                if (k == 0)
                    assign gp_red = 1'b1; // for k = 0, group propagate is 1
                else
                    assign gp_red = &p[i:i-k+1]; // reduction AND for propagate of group
                assign gp[k] = g[i-k] & gp_red; // group generate
            end
            wire p_red;
            assign p_red = &p[i:0];
            assign c[i] = |gp | (p_red & cin); // carry generation using group generate and propagate
        end
    endgenerate
endmodule