// Author: Ninaad Desai
// Description: 24-bit barrel logical right shifter with even rounding-off  
module man_shiftr(
    input [23:0] man,
    input [4:0] shamt,
    output [26:0] res
);
    wire [26:0] man_grs;
    wire [25:0] smask;
    genvar i;
    generate
        for(i = 1;i <= 26;i=i+1)
        begin
            mux32 m(
                .in({{(5+i){1'b0}},man_grs[26:i]}),
                .sel(shamt),
                .out(reslt[i])
            );
        end
        for(i = 1;i <= 26;i=i+1)
        begin
            
        end
    endgenerate
endmodule