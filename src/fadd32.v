module fadd32(
    input clk,
    input mode, // 0 - add (a + b), 1 - sub (a - b)
    input [31:0] a,
    input [31:0] b,
    output [31:0] res
);
    wire sa;
    wire sb;
    wire [7:0] expa;
    wire [7:0] expb;
    wire [22:0] mana;
    wire [22:0] manb;

    assign sa = a[31];
    assign sb = b[31];
    assign expa = a[30:23];
    assign expb = b[30:23];
    assign mana = a[22:0];
    assign manb = b[22:0];
endmodule