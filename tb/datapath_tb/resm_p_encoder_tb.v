/*
To run:
iverilog -o resm_p_encoder_tb.vvp tb/datapath_tb/resm_p_encoder_tb.v src/datapath/resm_p_encoder.v src/utils/*.v
vvp resm_p_encoder_tb.vvp
*/
`timescale 1ns / 1ps
module resm_p_encoder_tb;
    parameter lm = 23;
    parameter le = 8;
    reg [lm+3:0] resm;
    wire isZero;
    wire [le-1:0] shamt;
    resm_p_encoder #(.le(8), .lm(23)) uut (
        .resm(resm),
        .isZero(isZero),
        .shamt(shamt)
    );

    task test;
        input [lm+3:0] test_resm;
        begin
            resm = test_resm;
            #10;
            $display("mres = %b, isZero = %b, shamt = %d", resm, isZero, shamt);
        end
    endtask
    integer i;
    initial begin
        // $dumpfile("resm_p_encoder_tb.vcd");
        // $dumpvars(0,resm_p_encoder_tb);
        // for(i = 0;i < le;i = i+1)begin
        //     $dumpvars(0,resm_p_encoder_tb.uut.f[i]);
        // end
        test(27'b100010001000010100101100010);
        test(27'b010000010001001001000000000);
        test(27'b001000100010000100000000100);
        test(27'b000101001000100010001001100);
        test(27'b000000000000000000000000000);
    $finish;
    end
endmodule