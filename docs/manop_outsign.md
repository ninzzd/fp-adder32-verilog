# Mantissa Adder Operation Logic and Output Sign
**File(s)** - `add.v`,`fpadd.v`
## Purpose
- To facilitate the addition and subtraction of `lm+le+1`-bit floating-point numbers, with each input operand being positive or negative.
- To determine the sign of the output.
## Architectural Decisions
### Adder
- The `add.v` file constructs an `N`-bit Carry-Lookahead Adder using `generate` loops.
- The operand with the lower exponent ($B_0$ in the file) has a mantissa of `lm`-bits, which is extended to `lm+3` after mantissa alignment which generates 3 rounding bits. The other mantissa (that of $A_0$) contains only `lm`-bits, and only requires least-significant zero-padding (or manual right-shifting)
- The adder instantiated in `fpadd.v` is a `lm+3`-bit CLA
- By default, the mantissa of $B_0$ is passed to the inverting-XOR block for generating its 1's compliment.