# GMP Golden Sweep
**File** - `tb/gmp_golden_sweep.py`
## Purpose
- To functionally verify the `fpadd` DUT against a GMP/MPFR-backed golden model, for **any** `(lm, le)` bit-width, not just fp32.
- Unlike `tb/real2hex.c` (hardwired to the host's native `float`, i.e. fp32 only), this script builds the golden reference arithmetically using `gmpy2`, by constructing an MPFR context whose `(precision, emin, emax)` exactly reproduce the target `(lm, le)` format's rounding, overflow-to-infinity and gradual-underflow-to-subnormal behaviour.
- To drive the *actual* `tb/fpadd_tb.v` testbench (which instantiates the `fpadd` DUT directly) via `iverilog`/`vvp` as a subprocess, overriding its `lm`/`le` parameters at compile time with `-P`. Nothing under `tb/` or `src/` is modified.

## Usage
```
python3 tb/gmp_golden_sweep.py --lm 3 --le 4                  # exhaustive
python3 tb/gmp_golden_sweep.py --lm 23 --le 8 --sample 200000  # fp32, sampled
python3 tb/gmp_golden_sweep.py --lm 2 --le 3 --selftest        # sanity check only
```
- An exhaustive sweep covers all `2**(2*(lm+le+1))` `(a, b)` pairs, times 2 for `op` in `{0, 1}` (add/sub), and is only tractable for small custom formats (roughly `lm+le+1 <= 12-14` bits); use `--sample` for anything larger.

## Functions

### `make_context(lm, le)`
- Builds the `gmpy2` MPFR context reproducing an IEEE-754-style `(1 sign, le exp, lm mantissa)` format.
- `precision = lm+1` (includes the implicit leading bit), `subnormalize=True` for gradual underflow, `round=RoundToNearest`.
- `emin`/`emax` are derived from the exponent bias so overflow rounds to infinity and underflow rounds gradually to subnormal, matching real IEEE hardware behaviour.
- All traps (`trap_underflow`, `trap_overflow`, `trap_inexact`, `trap_invalid`, `trap_erange`, `trap_divzero`) are disabled, since inexact/underflow/overflow are all expected, routine outcomes here, not error conditions.
- Formula verified against `gmpy2.ieee(16/32/64)`.

### `decode_bits(bits, lm, le)`
- Exact decode of an `(lm, le)`-format bit pattern into an `mpfr` value.
- Splits `bits` into `sign`, `exp_field` and `mant_field` by the standard IEEE bit-layout.
- `exp_field` all-1s $\rightarrow$ infinity (`mant_field=0`) or NaN (`mant_field!=0`).
- `exp_field` all-0s $\rightarrow$ zero (`mant_field=0`) or subnormal (`mant_field!=0`, decoded via `mpq` for exactness).
- Otherwise $\rightarrow$ normal number, with the implicit leading 1 restored before decoding.
- Caller must already have the matching `(lm, le)` context active, so the returned `mpfr` carries the right precision.

### `encode_bits(val, lm, le)`
- Exact encode of an already correctly-rounded/clamped `mpfr` value back into an `(lm, le)`-format bit pattern.
- Matches this project's deliberate design choices (see `special_op.v`/`fpadd.v` and `docs/logs/running_doc.md`):
    - NaN always encodes as the canonical qNaN: `sign=0`, `exp=all-1s`, `mantissa=1000...0`, regardless of any NaN payload/sign.
    - Any zero result always encodes as `+0` (sign forced to 0).
- For finite non-zero values, uses `gmpy2.frexp`/`gmpy2.mul_2exp` to extract an exact `lm+1`-bit significand, then re-derives `true_exp` to decide between normal and subnormal encoding.
- Subnormal case right-shifts the significand by `(1-bias) - true_exp` to align it to the fixed subnormal binary point.

### `golden_result(a_bits, b_bits, op, lm, le, ctx)`
- Ties `decode_bits`/`encode_bits` together to compute one golden result bit pattern for a given vector.
- Decodes `a_bits` and `b_bits` under `ctx`, negates `b_val` if `op=1` (subtraction), adds, and re-encodes the (correctly-rounded-by-MPFR) sum.

### `ctx_kwargs(ctx)`
- Re-packs a `gmpy2.context` object's fields into a plain `dict`, with the same trap-disabling as `make_context`.
- Needed because `golden_result` re-enters a `with gmpy2.context(...)` block per call rather than reusing `ctx` directly.

### `selftest(trials=20000)`
- Cross-checks the golden model against Python's native fp32 `struct`-based add/sub, as a sanity check independent of the DUT.
- Runs `trials` random `(a_bits, b_bits, op)` vectors at `lm=23, le=8` (fp32), comparing `golden_result` against `struct.pack`/`unpack`-based native float arithmetic.
- Native NaN results are canonicalized to the same qNaN bit pattern `encode_bits` produces, since native float NaNs won't match bit-for-bit otherwise.
- Prints up to the first 10 mismatches and a final pass count; returns `True` only if there were zero mismatches.

### `gen_exhaustive(lm, le)`
- Generator yielding every `(a_bits, b_bits, op)` combination for the given `(lm, le)` width, via `itertools.product`.

### `gen_sample(lm, le, n, seed)`
- Generator yielding `n` random `(a_bits, b_bits, op)` vectors, seeded for reproducibility (`random.Random(seed)`, MT19937).

### `format_elapsed(seconds)`
- Formats a duration as exactly two units, coarsening as the value grows so the displayed line never depends on fluctuating digit counts:
    - `< 60s` $\rightarrow$ `Ss MMMms`
    - `< 60min` $\rightarrow$ `Mm SSs`
    - else $\rightarrow$ `Hh MMm`
- Used both for the live progress line and for the `execution time` field written to the output log.

### `print_progress(tag, done, total, start_time, ...)`
- Prints an in-place progress line (overwritten via `\r`, not scrolled), tagged by pipeline stage (e.g. `csv_gen`, `tb_run`).
- Throttled to at most one redraw per `min_interval` seconds (default 0.05s) per tag, so the progress display itself doesn't become the bottleneck.
- Tracks each tag's previous line length in the mutable default `_state` dict, so padding from a longer previous line doesn't bleed into a shorter one, and so multiple tags don't clobber each other's state.

### `run_dut(lm, le, vectors, work_dir, total_hint=None)`
- Writes `test_vectors.csv` (one row per vector: hex `a`, hex `b`, `op`, hex expected result), compiles `fpadd_tb.v` (which includes the DUT) with `lm`/`le` overridden via `-P`, and runs it under `vvp`.
- Golden-reference computation (the slow, per-vector `gmpy2` work) happens lazily as `vectors` is consumed inside this function's own loop, so `csv_gen` progress is reported from here rather than from the generator itself.
- Runs `vvp` with `cwd=work_dir` (a private temp directory unique to this invocation), not `REPO_ROOT`, since the testbench reads/writes `./test_vectors.csv` and `./docs/logs/fail_log.log` as relative paths — this keeps two concurrent invocations of this script from reading/overwriting each other's staged files.
- Returns `(stdout_text, n_run)`.

### `stream_vvp(vvp_path, n_vectors, cwd)`
- Runs `vvp` and reports live progress as each `PASS:`/`FAIL:` `$display` line arrives, instead of blocking until the process exits.
- Prepends `stdbuf -oL` when available, since `vvp`'s stdout is fully-buffered (not line-buffered) when piped rather than attached to a tty — without it, output would only surface in large infrequent chunks and progress would appear to stall.
- Returns the full captured stdout as a single newline-joined string.

### `fmt_real(bits, lm, le)`
- Convenience wrapper around `make_context`/`decode_bits` to turn a raw bit pattern into a human-readable real-number string, for annotating failures in the output log.

### `main()`
- Parses CLI args (`--lm`, `--le`, `--sample`, `--seed`, `--force`, `--max-vectors`, `--selftest`).
- `--selftest` short-circuits straight to `selftest()` and exits.
- Builds the vector generator: `gen_sample` if `--sample` is given, else `gen_exhaustive`, guarded by a `--max-vectors` safety cap (bypassable with `--force`).
- Wraps the vector generator with `golden_result` lazily (`with_golden()`), times the whole `run_dut` call, and writes a timestamped log to `docs/logs/gmpsweep-lm{lm}-le{le}-{ts}.log` containing:
    - `lm`, `le`, mode (exhaustive/sampled), vectors run, failure count, execution time (via `format_elapsed`)
    - each `FAIL:` line from the testbench, annotated with decoded real-number values (`a`, `b`, `op`, `expected`, `got`) via `fmt_real`
- Exits with status `1` if there were any failures, else `0`.
