/*
To run:
iverilog -o resm_round_tb.vvp tb/datapath_tb/resm_round_tb.v src/datapath/resm_round.v src/utils/*.v
vvp resm_round_tb.vvp
*/
`timescale 1 ns / 1 ps
module resm_round_tb;
    parameter lm = 23;
    reg [lm+3:0] resm_bround;
    wire [lm:0] resm;
    wire inc_cout;
    reg eq;

    resm_round #(
        .lm(lm)
    ) uut (
        .resm_bround(resm_bround),
        .resm(resm),
        .inc_cout(inc_cout)
    );

    task test;
        input [lm+3:0] test_resm_bround;
        input exp_cout;
        input [lm:0] exp_resm;
        begin
            resm_bround = test_resm_bround;
            #10;
            eq = (resm == exp_resm) && (inc_cout == exp_cout);
            $display("exp_cout = %b, cout = %b, err = %b, isCorrect = %b",exp_cout,inc_cout,resm^exp_resm,eq);
            #0.001;
        end
    endtask
    initial begin
        #10;
        test(27'b000000000000000000000000010, 1'b0, 24'b000000000000000000000000);
        test(27'b000000000000000000000000110, 1'b0, 24'b000000000000000000000001);
        test(27'b000000000000000000000000100, 1'b0, 24'b000000000000000000000000);
        test(27'b000000000000000000000001100, 1'b0, 24'b000000000000000000000010);
        test(27'b000000000000000000000000101, 1'b0, 24'b000000000000000000000001);
        test(27'b111111111111111111111111011, 1'b0, 24'b111111111111111111111111);
        test(27'b111111111111111111111111100, 1'b1, 24'b000000000000000000000000);
        test(27'b111111111111111111111111111, 1'b1, 24'b000000000000000000000000);
        test(27'b101010101010101010101010110, 1'b0, 24'b101010101010101010101011);
        test(27'b000000000000000000000000000, 1'b0, 24'b000000000000000000000000);
        $finish;
    end
endmodule