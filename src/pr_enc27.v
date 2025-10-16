// Author: Ninaad Desai
// Description: 27-bit reverse order priority encoder with zero flag
module pr_enc27(
    input [26:0] in,
    output [4:0] out,
    output zero
);
    integer i;
    always @(*)
    begin
        if(in[26] == 1'b1)
        begin
            out = 5'b00000;
            zero = 1'b0;        
        end
        else if(in[25] == 1'b1)
        begin
            out = 5'b00001;
            zero = 1'b0; 
        end
        else if(in[24] == 1'b1)
        begin
            out = 5'b00010;
            zero = 1'b0; 
        end
        else if(in[23] == 1'b1)
        begin
            out = 5'b00011;
            zero = 1'b0; 
        end
        else if(in[22] == 1'b1)
        begin
            out = 5'b00100;
            zero = 1'b0; 
        end
        else if(in[21] == 1'b1)
        begin
            out = 5'b00101;
            zero = 1'b0; 
        end
        else if(in[20] == 1'b1)
        begin
            out = 5'b00110;
            zero = 1'b0; 
        end
        else if(in[19] == 1'b1)
        begin
            out = 5'b00111;
            zero = 1'b0; 
        end
        else if(in[18] == 1'b1)
        begin
            out = 5'b01000;
            zero = 1'b0; 
        end
        else if(in[17] == 1'b1)
        begin
            out = 5'b01001;
            zero = 1'b0; 
        end
        else if(in[16] == 1'b1)
        begin
            out = 5'b01010;
            zero = 1'b0; 
        end
        else if(in[15] == 1'b1)
        begin
            out = 5'b01011;
            zero = 1'b0; 
        end
        else if(in[14] == 1'b1)
        begin
            out = 5'b01100;
            zero = 1'b0; 
        end
        else if(in[13] == 1'b1)
        begin
            out = 5'b01101;
            zero = 1'b0; 
        end
        else if(in[12] == 1'b1)
        begin
            out = 5'b01110;
            zero = 1'b0; 
        end
        else if(in[11] == 1'b1)
        begin
            out = 5'b01111;
            zero = 1'b0; 
        end
        else if(in[10] == 1'b1)
        begin
            out = 5'b10000;
            zero = 1'b0; 
        end
        else if(in[9] == 1'b1)
        begin
            out = 5'b10001;
            zero = 1'b0; 
        end
        else if(in[8] == 1'b1)
        begin
            out = 5'b10010;
            zero = 1'b0; 
        end
        else if(in[7] == 1'b1)
        begin
            out = 5'b10011;
            zero = 1'b0; 
        end
        else if(in[6] == 1'b1)
        begin
            out = 5'b10100;
            zero = 1'b0; 
        end
        else if(in[5] == 1'b1)
        begin
            out = 5'b10101;
            zero = 1'b0; 
        end
        else if(in[4] == 1'b1)
        begin
            out = 5'b10110;
            zero = 1'b0; 
        end
        else if(in[3] == 1'b1)
        begin
            out = 5'b10111;
            zero = 1'b0; 
        end
        else if(in[2] == 1'b1)
        begin
            out = 5'b11000;
            zero = 1'b0; 
        end
        else if(in[1] == 1'b1)
        begin
            out = 5'b11001;
            zero = 1'b0; 
        end
        else if(in[0] == 1'b1)
        begin
            out = 5'b11010;
            zero = 1'b0; 
        end
        else
        begin
            zero = 1'b1;
        end
    end
endmodule