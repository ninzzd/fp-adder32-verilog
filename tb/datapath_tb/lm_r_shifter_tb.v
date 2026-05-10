/*
To run:
iverilog -o lm_r_shifter_tb.vvp tb/datapath_tb/lm_r_shifter_tb.v src/datapath/lm_r_shifter.v src/utils/*.v
vvp lm_r_shifter_tb.vvp
*/
`timescale 1ns / 1ps
module lm_r_shifter_tb;
    parameter lm = 23, le = 8;
    reg [lm:0] in;
    reg [le-1:0] shamt;
    wire [lm+3:0] out;

    lm_r_shifter #(
        .lm(lm),
        .le(le)
    )uut(
        .in(in),
        .shamt(shamt),
        .out(out)
    );

    task run_test_case;
        input [lm:0] test_in;
        input [le-1:0] test_shamt;
        begin
            in <= test_in;
            shamt <= test_shamt;
            #15.000;
            $display("Input Mantissa: %b, Shift Amount: %b, Output: %b", in, shamt, out);
        end
    endtask

    initial
    begin
        $dumpfile("lm_r_shifter_tb.vcd");
        $dumpvars(0,lm_r_shifter_tb);

        run_test_case(24'b000000000000000000000001,8'b00000011);
        run_test_case(24'b000000000000000000000010,8'b00000010);
        run_test_case(24'b000000000000000000000100,8'b00000011);
        run_test_case(24'b101010101010101010101010,8'b00000111);
        run_test_case(24'b111111111111111111111111,8'b00001000);
        run_test_case(24'b100000000000000000000000,8'b00010111);
        run_test_case(24'b000000000001000000000000,8'b00001100);
        run_test_case(24'b000100100011010001010110,8'b00010111);
        run_test_case(24'b000100100011010001010110,8'b00011000);
        run_test_case(24'b000100100011010001010110,8'b00011111);

        $finish;
    end
endmodule