/*
To run:
iverilog -o resm_l_shifter_tb.vvp tb/datapath_tb/resm_l_shifter_tb.v src/utils/*.v src/datapath/*.v
vvp resm_l_shifter_tb.vvp
*/
`timescale 1 ns / 1 ps
module resm_l_shifter_tb;
    parameter lm = 23, le = 8;
    reg [lm+3:0] resm;
    wire [le-1:0] shamt;
    wire isZero;
    wire [lm+3:0] ls_resm; // left shifted result mantissa

    resm_p_encoder #(
        .le(8), .lm(23)
    ) pe (
        .resm(resm),
        .isZero(isZero),
        .shamt(shamt)
    );

    resm_l_shifter #(
        .le(8),
        .lm(23)
    ) uut (
        .in(resm),
        .shamt(shamt),
        .out(ls_resm)
    );

    task test;
        input [lm+3:0] test_resm;
        begin
            resm = test_resm;
            #10;
            $display("resm = %b, isZero = %b, shamt = %d, ls_resm = %b", resm, isZero, shamt, ls_resm);
        end
    endtask
    initial begin
        // $dumpfile("resm_l_shifter_tb.vcd");
        // $dumpvars(0,resm_l_shifter_tb);
        test(27'b100010001000010100101100010);
        test(27'b010000010001001001000000000);
        test(27'b001000100010000100000000100);
        test(27'b000101001000100010001001100);
        test(27'b000000000000000000000000000);
    end
endmodule