# fp-adder32-verilog
Implements a 32-bit floating-point adder based on the IEEE 754 standards, in Verilog HDL

## Commands
```bash
# Comparator testbench
iverilog -o comp8_tb.vvp tb/comp8_tb.v src/add8.v src/comp8.v
vvp comp8_tb.vvp
gtkwave comp8_tb.vcd

# Complete adder testbench
iverilog -o fadd32_tb.vvp tb/fadd32_tb.v src/*.v
vvp fadd32_tb.vvp
gtkwave fadd32_tb.vcd
```