/*
To run: 
iverilog -o min_tb.vvp tb/utils_tb/min_tb.v src/utils/*.v
vvp min_tb.vvp
*/
`timescale 1ns / 1ps
module min_tb;
    parameter W = 32;
    reg [W-1:0] a;
    reg [W-1:0] b;
    wire [W-1:0] out;

    min #(
        .W(W)    
    )uut(
        .a(a),
        .b(b),
        .out(out)
    );

    initial
    begin
        $dumpfile("min_tb.vcd");
        $dumpvars(0,min_tb);
        a <= 10;
        b <= 20;
        #15.000
        a <= 172;
        b <= 20;
        #15.000
        a <= 5;
        b <= 35;
        #15.000
        a <= 5;
        b <= 63;
        #15.000
        $finish;
    end
endmodule