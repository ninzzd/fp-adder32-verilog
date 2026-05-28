# Mantissa Adder Operation Logic and Output Sign
**File(s)** - `add.v`,`fpadd.v`
## Purpose
- To facilitate the addition or subtraction of `lm+le+1`-bit floating-point numbers, with each input operand being positive or negative.
- To determine the sign of the output.
## Architectural Decisions
### Adder
- The `add.v` file constructs an **`N`-bit CLA** using `generate` loops.
- The operand with the lower exponent ($B_0$ in the file) has a mantissa of `lm`-bits, which is extended to `lm+3` after mantissa alignment which generates 3 rounding bits. The other mantissa (that of $A_0$) contains only `lm`-bits, and only requires least-significant zero-padding (or manual right-shifting).
- The adder instantiated in `fpadd.v` is a `lm+3`-bit CLA.
- By default, the mantissa of $B_0$ is passed to the inverting-XOR block for generating its 1's compliment based on bit `maddop`.
- The carry-out bit of the adder is represented as $M_{ADD_{c}}$ in the [diagram](../README.md#Architecture) and as `maddcout` in the file.
- The adder result `maddres` is passed through a 2s compliment module which is triggered by a wire `flag`. The floating-point number can have a sign, but its mantissa must always be positive, hence the following logic:
```
    If op is sub (maddop = 1):
        If maddcout = 0 (negative result mantissa):
            flag = 1 (take 2s compliment)
        Else:
            flag = 0 (keep as it is)
    Else:
        flag = 0 (add, mantissa is always positive)
```
- This implies : `flag = maddop&~maddcout`

### Operation and Output Sign
- The operation add/sub is denoted by the signal (denoted as $M_{ADD_{op}}$ in the [diagram](../README.md#Architecture)) `maddop` ()such that:
    - `maddop = 0` $\rightarrow$ add
    - `maddop = 1` $\rightarrow$ sub
- The addition/subtraction expression is adjusted such that the CLA **always considers the mantissa of $A_0$ as positive**, with `maddop` being adjusted accordingly. `flag` normalizes the sign in case of mantissa subtraction, which is then complemented if $A_0$ was initially negative (shown in the truth table, with a negative sign outside the brackets for the simplified expression).
- `maddop` and output sign $S_c$ can be determined by the following truth table
Let $A_0$ and $B_0$ be the absolute values of the operands, with $A_0$ having a larger exponent than $B_0$.

| $S_{A_0}$ | $op$ | $S_{B_0}$ | Expression |  $M_{ADD_{op}}$ | $S_c$| 
| :---: | :---: | :---: | :---: | :---: | :---: |
|  0    |  0   |   0     |   $(A_0)+(+B_0) = +(A_0+B_0)$ |  0   |  0   |
|  0    |  0   |   1     |   $(A_0)+(-B_0) = +(A_0-B_0)$    |  1   |  0 $\oplus$ `flag`   |
|  0    |  1   |   0     |   $(A_0)-(+B_0) = +(A_0-B_0)$    |  1   |  0 $\oplus$ `flag`   |
|  0    |  1   |   1     |   $(A_0)-(-B_0) = +(A_0+B_0)$    |  0   |  0   |
|  1    |  0   |   0     |   $(-A_0)+(+B_0) = -(A_0-B_0)$    |  1   |  1 $\oplus$ `flag`    |
|  1    |  0   |   1     |   $(-A_0)+(-B_0) = -(A_0+B_0)$    |  0   |  1   |
|  1    |  1   |   0     |   $(-A_0)-(+B_0) = -(A_0+B_0)$    |  0   |  1   |
|  1    |  1   |   1     |   $(-A_0)-(-B_0) = -(A_0-B_0)$    |  1   |  1$\oplus$ `flag`    |

- Hence: `maddop = sa0 ^ sb0 ^ op = sa ^ sb ^ op` and `sc = sa0 ^ flag` , where `sa` and `sb` are the signs of the input operands `a` and `b`, respectively. `sa0` and `sb0` are signs of swapped operands based on exponent comparison

### Handling Zero Result
- Zero can be only obtained by the subtraction of equal operands or addition of zeros (trivial case). 
- In the first case, `flag` will always be 1, and hence output sign could be 0 or 1 depending on the sign of $A_0$. This is not suitable as there would exist two distinct representations of zero: $+0$ and $-0$.
- To avoid this: `sc = (sa0 ^ flag) & ~isZero` (`isZero` is obtained from the priority encoder that checks for leading zeros and accordingly provides the left-shift ammount for renormalization).
