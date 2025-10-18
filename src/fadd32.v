module fadd32(
    input mode, // 0 - add (a + b), 1 - sub (a - b)
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] res
);
    wire a_isnorm;
    wire b_isnorm;
    wire exp_altb;
    wire exp_aeqb;
    wire exp_agtb;
    wire [7:0] exp_absdiff;
    wire [4:0] capped_exp_absdiff;
    comp8 exp_comp(
        .a(a[30:23]),
        .b(b[30:23]),
        .a_eq_b(exp_aeqb),
        .a_lt_b(exp_altb),
        .a_gt_b(exp_agtb),
        .abs_diff(exp_absdiff)
    );
    wire [26:0] man1; // mantissa of the number with larger exponent
    wire [23:0] man2; // mantissa of the number with smaller exponent
    wire [26:0] shifted_man2; 
    wire [26:0] sum;
    reg [26:0] abs_sum;
    wire [4:0] shamt_sum;
    reg [26:0] norm_sum_man;
    wire zero;
    wire cout;
    wire man_sub;
    wire man1_sign;
    wire [7:0] man1_exp;

    assign capped_exp_absdiff = exp_absdiff > 8'b00011000 ? 5'b11000 : exp_absdiff[4:0];
    assign man_sub = a[31]^b[31]^mode;
    assign a_isnorm = a[30]|a[29]|a[28]|a[27]|a[26]|a[25]|a[24]|a[23]; // 0 - a is subnormal, 1 - a is normal
    assign b_isnorm = b[30]|b[29]|b[28]|b[27]|b[26]|b[25]|b[24]|b[23]; // 0 - b is subnormal, 1 - b is normal
    assign man1[2:0] = 3'b000;
    assign man1[25:3] = {23{exp_agtb}}&a[22:0] | {23{~exp_agtb}}&b[22:0];
    assign man1[26] = (exp_agtb)&(a_isnorm) | (~exp_agtb)&(b_isnorm);
    assign man1_sign = (exp_agtb)&a[31] | (exp_altb)&b[31];
    assign man1_exp = (exp_agtb)&a[30:23] | (exp_altb)&b[30:23];
    assign man2[22:0] = {23{exp_agtb}}&b[22:0] | {23{~exp_agtb}}&a[22:0];
    assign man2[23] = (exp_agtb)&(b_isnorm) | (~exp_agtb)&(a_isnorm);
    man_shiftr mshftr1(
        .man(man2),
        .shamt(capped_exp_absdiff),
        .res(shifted_man2)
    );
    pr_enc27 prenc1(
        .in(abs_sum),
        .out(shamt_sum),
        .zero(zero)
    );
    assign {cout,sum} = man_sub == 1'b0 ? man1 + shifted_man2 : man1 - shifted_man2;
    always @(*)
    begin
        if(man_sub == 1'b0 && cout == 1'b1)
        begin
            res[30:23] = a[30:23] + 1'b1;
            res[22:0] = sum[26:4] + (sum[3:0] > 4'b1000 ? 1'b1 : (sum[3:0] == 4'b1000 ? sum[4] : 1'b0));
            res[31] = man1_sign;
        end
        else if(man_sub == 1'b0 && cout == 1'b0)
        begin
            res[30:23] = a[30:23];
            res[22:0] = sum[25:3] + (sum[2:0] > 4'b100 ? 1'b1 : (sum[2:0] == 4'b100 ? sum[3] : 1'b0));
            res[31] = man1_sign;
        end
        else if(man_sub == 1'b1)
        begin
            if(cout == 1'b0)
            begin
                res[31] = ~man1_sign;
                abs_sum = ~sum + 1'b1;
            end
            else
            begin
                res[31] = man1_sign;
                abs_sum = sum;
            end
            if(man1_exp > shamt_sum)    // Result is normal
            begin
                res[30:23] = man1_exp - shamt_sum;
                norm_sum_man = sum << shamt_sum;
            end
            else    // Result is subnormal
            begin
                res[30:23] = 8'h00;
                norm_sum_man = sum << man1_exp;
            end
            res[22:0] = norm_sum_man[25:3] + (norm_sum_man[2:0] > 3'b100 ? 1'b1 : (norm_sum_man[2:0] == 3'b100 ? norm_sum_man[3] : 1'b0));
        end
    end
endmodule