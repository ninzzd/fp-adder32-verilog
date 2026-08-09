# Nomenclature
Refer to this file as a legend for various wire names in the [diagram](../README.md#architecture) and the main verilog module [fpadd.v](../src/fpadd.v).

| Symbol | Variable Name | Description |
|---|---|---|
| $S_A$ | `a[le+lm]` | Sign bit of operand `a` |
| $E_A$ | `a[le+lm-1:lm]` | Exponent bits of operand `a` |
| $M_A$ | `a[lm-1:0]` | Raw (stored) mantissa bits of operand `a`, excluding the implicit leading bit |
| $S_B$ | `b[le+lm]` | Sign bit of operand `b` |
| $E_B$ | `b[le+lm-1:lm]` | Exponent bits of operand `b` |
| $M_B$ | `b[lm-1:0]` | Raw (stored) mantissa bits of operand `b`, excluding the implicit leading bit |
| $op$ | `op` | Operation-select input: `0` = add, `1` = subtract |
| $ageb$ | `ageb` | Output of the exponent comparator; 1 if `exp_a >= exp_b`, used to select which operand becomes $A_0$/$B_0$ |
| $E_{A_0}$ | `a0e` | Exponent of $A_0$, i.e. the larger of the two (subnormal-adjusted) exponents |
| $shamt$ | `b0_shamt` | Right-shift amount for $B_0$'s mantissa (absolute exponent difference), from the exponent comparator |
| $MADD_{op}$ | `maddop` | Effective add/sub control fed to the mantissa adder: `sa0 ^ sb0 ^ op` |
| $MADD_c$ | `maddcout` | Carry-out of the mantissa adder |
| $flag$ | `flag` | 1 if the mantissa-adder result is negative and needs 2's-complementing: `maddop & ~maddcout` |
| $shamt'$ | `a0e_sub_1` | $E_{A_0} - 1$; combined with the leading-zero shift amount in a `min` circuit to cap the renormalization left-shift, preventing exponent underflow when the result is sub-normal |
| $isSubNrm$ | `resm_isSubnormal` | 1 if the (unrounded) result mantissa is sub-normal |
| $R_{cout}$ | `round_cout` | Carry-out of the rounding incrementer |
| $S_C$ | `c[le+lm]` | Sign bit of the result |
| $E_C$ | `c[le+lm-1:lm]` | Exponent bits of the result |
| $M_C$ | `c[lm-1:0]` | Mantissa bits of the result |

