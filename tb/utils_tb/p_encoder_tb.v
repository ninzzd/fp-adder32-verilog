/*
To run: 
iverilog -o p_encoder_tb.vvp tb/utils_tb/p_encoder_tb.v src/utils/p_encoder.v
vvp p_encoder_tb.vvp
*/
module p_encoder_tb;
    parameter N = 4;
    integer i;
    reg [N-1:0] in;
    wire [N-1:0] f;
    wire out;

    p_encoder #(
        .N(N)
    ) dut1 (
        .in(in),
        .f(f),
        .out(out)
    );
    assign f = 4'b0101;
    initial begin
        in = 0;
        #10;
        for(i = 1; i < 2**N; i = i + 1) begin
            in = i;
            $display("in: %b, out: %b", in, out);
            #10;
        end
    end
endmodule