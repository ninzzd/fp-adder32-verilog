`timescale 1 ns / 1 ps
/*
To run:
iverilog -o e_comparator_tb.vvp tb/datapath_tb/e_comparator_tb.v src/datapath/e_comparator.v src/utils/*.v
vvp e_comparator_tb.vvp
*/
module e_comparator_tb;
    parameter le = 8;
    reg [le-1:0] a;
    reg [le-1:0] b;
    wire a_ge_b;
    wire [le-1:0] m_shamt;
    wire [le-1:0] a0e;

    e_comparator #(.le(le)) uut (
        .a(a),
        .b(b),
        .a_ge_b(a_ge_b),
        .m_shamt(m_shamt),
        .a0e(a0e)
    );

    initial begin
        $monitor("a = %d, b = %d, a_ge_b = %b, m_shamt = %d, a0e = %d", a, b, a_ge_b, m_shamt, a0e);
        a = 8'b00000000; b = 8'b00000000; #10;
        a = 8'b00000001; b = 8'b00000000; #10;
        a = 8'b00000000; b = 8'b00000001; #10;
        a = 8'b11111111; b = 8'b00000000; #10;
        a = 8'b00000000; b = 8'b11111111; #10;
        a = 8'b10101010; b = 8'b01010101; #10;
        a = 8'b01010101; b = 8'b10101010; #10;
    end
endmodule