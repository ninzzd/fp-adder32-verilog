`timescale 1 ns / 1 ps
module fadd32_tb;
    reg[31:0] a;
    reg[31:0] b;
    reg mode;
    wire[31:0] res;
    reg[31:0] exp_res;
    wire eq;
    assign eq = res == exp_res ? 1'b1 : 1'b0;
    fadd32 uut(
        .a(a),
        .b(b),
        .mode(mode),
        .res(res)
    );
    integer test;
    integer n;
    integer i;
    initial
    begin
        $dumpfile("fadd32_tb.vcd");
        $dumpvars(0,fadd32_tb);
        test = $fopen("f.test","r");
        if (test == 0) $finish;
        if($fscanf(test,"%d\n",n) == 1)
        begin
            for(i = 0;i < n;i=i+1)
            begin
                if($fscanf(test,"%h %h %b %h\n",a,b,mode,exp_res) == 4)
                begin
                    #0.001
                    $write("A = %h, B = %h, mode = %b, exp_res = %h, res = %h, eq = %b\n",a,b,mode,exp_res,res,eq);
                    #10.000;
                end
            end
        end
        $finish;
    end
endmodule