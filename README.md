# fp-adder32-verilog
Implements a 32-bit floating-point adder based on the IEEE 754 standards, in Verilog HDL

## Commands
```bash
iverilog -o comp8_tb.vvp tb/comp8_tb.v src/add8.v src/comp8.v
vvp comp8_tb.vvp
gtkwave comp8_tb.vcd
```