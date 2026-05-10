/*
To run:
iverilog -o fpadd_tb.vvp tb/fpadd_tb.v src/*.v src/utils/*.v src/datapath/*.v
vvp fpadd_tb.vvp
gtkwave fpadd_tb.vcd
*/
module fpadd_tb;
    parameter lm = 23, le = 8;
    integer file;
    integer fail_log;
    integer n;
    integer nflag;
    integer vecflag;
    integer i;
    integer fail_count;
    reg  [lm+le:0] a;
    reg  [lm+le:0] b;
    reg            op;
    reg  [lm+le:0] exp_res;
    wire [lm+le:0] c;
    wire err;

    fpadd #(
        .le(le),
        .lm(lm)
    ) uut (
        .a(a),
        .b(b),
        .op(op),
        .c(c)
    );

    assign err = (c != exp_res);

    initial begin
        $dumpfile("fpadd_tb.vcd");
        $dumpvars(0, fpadd_tb);
        file = $fopen("./test_vectors.csv","r");
        fail_count = 0;
        if(file == 0) begin
            $display("Error opening file");
            $finish;
        end
        // read number of test vectors
        nflag = $fscanf(file,"%d\n", n);
        if(nflag != 1) begin
            $display("Failed to read test vector count");
            $finish;
        end
        $display("Running %0d test vectors", n);
        for(i = 0; i < n; i = i + 1) begin
            vecflag = $fscanf(file,"%h,%h,%d,%h\n", a, b, op, exp_res);
            if(vecflag != 4) begin
                $display("Error reading vector %0d", i);
                $finish;
            end
            #10;
            if(err) begin
                $display("FAIL: a=%h b=%h op=%0d expected=%h got=%h",
                        a, b, op, exp_res, c);
                if(fail_count == 0) begin
                    fail_log = $fopen("./docs/logs/fail_log.log","w");
                    if(fail_log == 0)begin
                        $display("Error in creating log file for failed cases. Ending simulation...");
                        $finish;
                    end
                end
                $fdisplay(fail_log,"FAIL: a=%h b=%h op=%0d expected=%h got=%h",
                        a, b, op, exp_res, c);
                fail_count = fail_count + 1;
            end
            else begin
                $display("PASS: a=%h b=%h op=%0d result=%h",
                        a, b, op, c);
            end
        end
        $display("Simulation complete");
        $fclose(file);
        $finish;
    end
endmodule