// Author: Ninaad Desai
// Description: Right-logical shift of mantissa using barrel shifters, appended with guard (G), round (R) and sticky (S) bits  
module man_shiftr(
    input [23:0] man,
    input [4:0] shamt,
    output [26:0] res
);
    wire [25:0] man_gr;
    wire [25:0] smask;
    wire [25:0] and1;
    wire [25:0] or1;
    genvar i;

    assign man_gr = {man,2'b00};

    generate
        for(i = 1;i <= 26;i=i+1)
        begin
            mux32 m(
                .in({{(5+i){1'b0}},man_gr[25:(i-1)]}),
                .sel(shamt),
                .out(res[i])
            );
        end
        for(i = 0;i <= 25;i=i+1) // Behavioral smask generation
        begin
            assign smask[i] = (i < shamt) ? 1'b1 : 1'b0; // Builds a comparator for each bit of smask, comparing shamt, the variable input, with the index, which is fixed 
        end
        for(i = 0;i <= 25;i=i+1)
        begin
            if(i == 0)
            begin
                assign or1[i] = and1[i];
            end
            else
            begin
                assign or1[i] = or1[i-1] | and1[i];
            end
        end
    endgenerate
    assign and1 = man_gr&smask;
    assign res[0] = or1[25];
endmodule