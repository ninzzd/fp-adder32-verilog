# Rounding
**File(s)**: [`resm_round`][resm_round], `fpadd.v`
## Purpose
- To round the unrounded result mantissa `resm_bround` (mantissa + 3 rounding suffix bits) down to an `lm+1`-bit mantissa, using **round-to-nearest-even**.
- To detect the carry-out produced when the rounding increment overflows an all-ones mantissa, and re-normalize the mantissa by a 1-bit right-shift when this happens.
- To propagate that same carry-out into the result exponent, keeping mantissa and exponent consistent after rounding.
- To resolve the final exponent field for the sub-normal case, undoing the internal sub-normal exponent adjustment where it no longer applies.

## Architectural Decisions
### Format of `resm_bround`
- `resm_bround` is the `lm+4`-bit unrounded result mantissa, produced by `add_sub_resm_mux` in `fpadd.v`. It carries the same `[--mantissa (lm+1 bits)--] | G R S` layout established during [mantissa alignment](./mantissa_alignment.md#rounding-suffix-bits): `resm_bround[lm+3:3]` is the mantissa (with implicit leading bit), and `resm_bround[2:0]` are the Guard, Round and Sticky bits respectively.
- Depending on `maddop`, this is either `maddres_ls` (subtraction path, re-normalized by the leading-zero left-shifter, see [Leading Zero Detection](./leading_zero_detector.md)) or `maddres_rs` (addition path, right-shifted by 1 with sticky-preserving OR-merge if the mantissa adder overflowed, `maddcout = 1`). Both paths converge on the same `G R S` convention before rounding.

### Round-to-Nearest-Even Decision
- [`resm_round`][resm_round] computes `round_up` combinatorially:
```verilog
round_up = resm_bround[2] & (resm_bround[1] | resm_bround[0] | resm_bround[3]);
```
- In symbols, with $G$, $R$, $S$ the guard/round/sticky bits and $L$ the mantissa's current LSB (`resm_bround[3]`):
```math
round\_up = G \cdot (R + S + L)
```
- This is the standard round-half-to-even rule:

    | $G$ | $R+S$ | $L$ | `round_up` | Case |
    |:---:|:---:|:---:|:---:|---|
    | 0 | x | x | 0 | Discarded value $< \frac{1}{2}$ ulp $\rightarrow$ truncate |
    | 1 | 1 | x | 1 | Discarded value $> \frac{1}{2}$ ulp $\rightarrow$ round up |
    | 1 | 0 | 0 | 0 | Exactly $\frac{1}{2}$ ulp, mantissa already even $\rightarrow$ truncate |
    | 1 | 0 | 1 | 1 | Exactly $\frac{1}{2}$ ulp, mantissa odd $\rightarrow$ round up to even |

### Rounding Increment and Overflow
- The `lm+1`-bit mantissa `resm_bround[lm+3:3]` (including its implicit leading bit) is fed into an `inc` (see [`inc`][inc]) with `cin = round_up`:
```verilog
inc #(.W(lm+1)) resm_inc (
    .cin(round_up),
    .in(resm_bround[lm+3:3]),
    .out(resm),        // named resm_around in fpadd.v
    .cout(inc_cout)     // named round_cout in fpadd.v
);
```
- Because the incrementer is only `lm+1` bits wide, an all-ones mantissa (e.g. $1.\underbrace{11\ldots1}_{lm}$, the largest representable mantissa below the next power of two) that rounds up wraps to all-zeros with a carry-out. `inc_cout` (`round_cout` / $R_{cout}$ in [nomenclature](./nomenclature.md)) flags exactly this case: the rounded value has silently become $2.\underbrace{00\ldots0}_{lm}$, one bit wider than the mantissa field can hold.

### Renormalization After Rounding Overflow
- `round_resm_mux` in `fpadd.v` resolves the overflow, mirroring the same right-shift-with-sticky-merge pattern used for the mantissa-adder's own overflow (`add_resm_mux`):
```verilog
mux #(.W(lm+1), .N(2)) round_resm_mux (
    .in({{round_cout,resm_around[lm:2],resm_around[1]|resm_around[0]},resm_around}),
    .sel(round_cout),
    .out(resm)
);
```
- When `round_cout = 0`, `resm_around` is passed through unchanged — the rounding increment fit within the existing mantissa width.
- When `round_cout = 1`, the mux instead selects `{round_cout, resm_around[lm:2], resm_around[1]|resm_around[0]}`: the mantissa is shifted right by 1, and the carry-out itself becomes the new implicit leading bit. The two bits shifted out are OR-merged into the new LSB for sticky-preservation consistency, though in practice they are always `0` here — an all-ones mantissa rounding up produces exact zeros below the carry, so no precision is actually lost.
- `c[lm-1:0] = resm[lm-1:0]` — the final `lm` stored mantissa bits are read off this corrected result, with the implicit leading bit (`resm[lm]`) dropped as usual.

### Exponent Adjustment for Rounding Overflow
- Since a rounding overflow effectively multiplies the mantissa's scale by 2 (the same effect as a 1-bit right-shift during renormalization), the result exponent must be incremented in lock-step:
```verilog
inc #(.W(le)) ince_round (
    .in(rese_bround),
    .cin(round_cout),
    .out(rese_around)
);
```
- `rese_bround` is the pre-rounding result exponent (from `add_sub_rese_mux`, following the add/sub exponent logic). Feeding `round_cout` directly into the increment's `cin` means the exponent only moves when the mantissa actually overflowed during rounding — otherwise `rese_around = rese_bround`.

### Sub-normal Result Detection and Exponent Field Masking
- Whether the final result is sub-normal is derived directly from the two rounding signals, without any further arithmetic:
```verilog
assign resm_isSubnormal = ~round_cout & ~resm[lm];
```
- If `round_cout = 1`, the mantissa unambiguously overflowed into a new leading bit — the result is normal regardless of anything else.
- If `round_cout = 0`, the result is normal only if `resm[lm]` (the mantissa's implicit leading bit, post-rounding) is already `1`; otherwise no leading `1` was ever produced and the result is sub-normal.
- Sub-normal input operands have their extracted exponents pre-incremented by 1 during subnormal adjustment (`ae_inc_sbnrm`/`be_inc_sbnrm` in `fpadd.v`), so the internal exponent datapath can treat them uniformly with normalized operands (an internal exponent of $1$ stands in for the true sub-normal exponent field of $0$). This means that whenever the true result stays sub-normal, `rese_around` still carries that stray `+1` and reads as $0\ldots01$ rather than the correct stored field of all-zeros.
- The final exponent field masks this off:
```verilog
assign c[lm+le-1:lm] = {rese_around[le-1:1], rese_around[0]&~resm_isSubnormal};
```
- Forcing bit 0 to `0` when `resm_isSubnormal` is sufficient to correct `rese_around` back to an all-zero stored exponent, because the stray adjustment only ever shows up in that LSB for this range of results — not a general-purpose subtraction. This is flagged directly in `fpadd.v` as a known simplification (*"may not be most optimal logic, can substitute for round_cout and resm[lm] directly if needed"*), kept here for documentation completeness rather than as a claim of optimality.

## Architectural Diagram
Refer to the *Round-Off*, *RS-1* (right-shift-by-1) and the bottom-most exponent `INC`/masking blocks of the [microarchitectural diagram](../README.md#architecture), which correspond respectively to `resm_round`, the overflow-correcting `round_resm_mux`, and the `ince_round`/`resm_isSubnormal` exponent-field logic described above.

[resm_round]: ../src/datapath/resm_round.v
[inc]: ../src/utils/inc.v