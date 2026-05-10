/*
To run:
iverilog -o dec_tb.vvp tb/utils_tb/dec_tb.v src/utils/dec.v
vvp dec_tb.vvp
*/
`timescale 1 ns / 1 ps
module dec_tb;
    parameter W = 8;
    reg [W-1:0] in;
    wire [W-1:0] out;

    dec #(.W(W)) uut (
        .in(in),
        .out(out)
    );
    task test;
        input [W-1:0] test_in;
        begin
            in <= test_in;
            #10.000;
            $display("in = %b, out = %b", in, out);
        end
    endtask
    initial begin
        test(8'b0000_0001);
        test(8'b0000_0010);
        test(8'b0000_0100);
        test(8'b0000_1000);
        test(8'b0001_0000);
        $finish;
    end
endmodule