`timescale 1 ns / 1 ps
module man_shiftr_tb;
    reg [23:0] man;
    reg [4:0] shamt;
    wire [26:0] res;
    reg [26:0] exp_res;
    wire eq;

    assign eq = (exp_res == res) ? 1'b1 : 1'b0;
    man_shiftr uut(
        .man(man),
        .shamt(shamt),
        .res(res)
    );
    initial
    begin
        $dumpfile("man_shiftr_tb.vcd");
        $dumpvars(0,man_shiftr_tb);
        man <= 24'b110110011001100110011010;
        shamt <= 5'b00101;
        exp_res <= 27'b000001101100110011001100111;
        #0.001
        $write("Result: %b, Eq: %b\n",res,eq);
        #10.000
        man <= 24'b111101001100001110101101;
        shamt <= 5'b00100;
        exp_res <= 27'b000011110100110000111010111;
        #0.001
        $write("Result: %b, Eq: %b\n",res,eq);
        $finish;
    end
endmodule