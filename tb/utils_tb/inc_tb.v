/*
To run:
iverilog -o inc_tb.vvp tb/utils_tb/inc_tb.v src/utils/inc.v
*/
`timescale 1 ns / 1 ps
module inc_tb;
    reg cin;
    reg [7:0] in;
    wire [7:0] out;
    wire cout;

    inc #(.W(8)) uut (
        .cin(cin),
        .in(in),
        .out(out),
        .cout(cout)
    );

    initial begin
        $monitor("in = %b, out = %b, cout = %b", in, out, cout);
        cin = 1'b0;in = 8'b00000000; #10;
        cin = 1'b1;in = 8'b00000001; #10;
        cin = 1'b1;in = 8'b00001111; #10;
        cin = 1'b1;in = 8'b11111111; #10;
    end
endmodule