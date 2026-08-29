# Real2Hex
**File** - `tb/real2hex.c`
## Purpose
- To convert decimal fp32 test vectors (read from `stdin`) into the hex `test_vectors.csv` format consumed by the Verilog testbench.
- To compute the native-`float` add/sub reference result for each vector, using the host's own IEEE-754 fp32 hardware, so `test_vectors.csv` already carries the expected result alongside the inputs.
- Hardwired to the host's native `float`, i.e. fp32 (`lm=23, le=8`) only — unlike `tb/gmp_golden_sweep.py`, which builds golden references arithmetically for any `(lm, le)`.

## Usage
```
./real2hex < input.csv     # writes ./test_vectors.csv
```
- `stdin` format: first line is the vector count `n`, followed by `n` lines of `a,b,mode` (decimal floats `a`, `b`, and `mode` as `0`=add / `1`=sub).
- Output `test_vectors.csv` format: first line is `n`, followed by `n` lines of `a_hex,b_hex,mode,result_hex` (8 hex digits each, fp32 bit patterns).

## `f2b` (union)
- A `float`/`uint32_t` union used to reinterpret an fp32 value's raw bits without any conversion — i.e. type-punning, not casting.
- `.f` is written/read as the IEEE-754 float; `.bin` reads the same 4 bytes back as an unsigned 32-bit bit pattern.

## `main()`
- Opens `test_vectors.csv` for writing, aborting with an error message if it can't.
- Reads the vector count `n` from the first line of `stdin` and writes it straight through as the first line of the output.
- For each of the `n` following lines:
    - Parses `a.f`, `b.f` and `mode` via `sscanf("%f,%f,%u", ...)`, skipping (and logging) any line that doesn't match the expected 3-field format.
    - Computes `res.f = mode ? (a.f - b.f) : (a.f + b.f)` — the native fp32 result, correctly rounded by the host FPU.
    - Writes `a.bin`, `b.bin`, `mode` and `res.bin` as a `%08x,%08x,%u,%08x` row.
- Closes the output file and returns.
