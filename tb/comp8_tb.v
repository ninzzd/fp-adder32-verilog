`timescale 1 ns / 1 ps
module comp8_tb;
    reg [7:0] a;
    reg [7:0] b;
    wire a_lt_b;
    wire a_eq_b;
    wire a_gt_b;
    wire [7:0] abs_diff;

    comp8 uut(
        .a(a),
        .b(b),
        .a_eq_b(a_eq_b),
        .a_lt_b(a_lt_b),
        .a_gt_b(a_gt_b),
        .abs_diff(abs_diff)
    );

    initial
    begin
        $dumpfile("comp8_tb.vcd");
        $dumpvars(0,comp8_tb);
        a <= 34;
        b <= 27;
        #15.000
        a <= 30;
        b <= 30;
        #15.000
        a <= 0;
        b <= 128;
        #15.000
        $finish;
    end 
endmodule