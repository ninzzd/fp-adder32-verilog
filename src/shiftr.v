module shiftr(
    input [23:0] oprnd,
    input [4:0] shamt,
    output [23:0] reslt
);

endmodule
module mux #(parameter N = 32)(
    input [N-1:0] in,
    input [$clog2(N)-1:0] sel,
    output out
);
    genvar i;
    generate 
        for(i = 0;i < N;i=i+1)
        begin
            
        end
    endgenerate
endmodule