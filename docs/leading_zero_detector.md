# Leading Zero Detection
**File(s)**: [`p_encoder`][p_encoder], [`resm_p_encoder`][resm_p_encoder]
## Purpose
- To detect leading zeros in the result mantissa (after 2s complementing) and produce the left-shift amount for result mantissa renormalization
## Architectural Decisions
### Priority Encoder
- A general N:1 priority encoder implements the following truth table:

    | $a_{N-1}$ | $a_{N-2}$ | ... | $a_0$ | $f$ |
    |---| --- |---|---|---|
    | 1 | x | ... | x | $f_{N-1}$ |
    | 0 | 1 | ... | x | $f_{N-2}$ |
    | 0 | 0 | ... | 1 | $f_{0}$ |
- This truth table can be logically simplified as:
```math
f = a_{N-1} f_{N-1} + \overline{a_{N-1}} a_{N-2} f_{N-2} + \dots + \overline{a_{N-1}} \overline{a_{N-2}} \dots a_0 f_0
```
- This was implemented in [`p_encoder`][p_encoder] using a `generate` loop block for generating the minterms, and a reduction-OR for obtaining the output function.
- A `p_encoder` module inputs an `N`-bit function vector `f`, which generalizes the LUT and implements the above truth table.
- A zero-input vector generates a default output of `1'b0`, which is not handled separately here.
### Leading Zero Detector
- This is implemented in [`resm_p_encoder`][resm_p_encoder] by using $log_2(N)$ parallel N:1 priority encoders, using `generate loops`, with `N` being the parameterized input bit-width.
- Each priority encoder $PE_i$ is fed a function vector $F_i$, which is precomputed using `genvar` variables `i` and `j`, according to the formula:

```math
    F_i[j] = \lfloor\frac{N-1-j}{2^i}\rfloor \pmod 2 = ((N-1-j) >> i)[0]
```
- The second notation represents the LSB of the $N-1-j$ right shifted by $i$, which requires a very simple verilog implementation.
- Zero-input vectors are easily handled by performing a reduction-OR on the input `isZero = |in`.

[p_encoder]: ../src/utils/p_encoder.v
[resm_p_encoder]: ../src/datapath/resm_p_encoder.v