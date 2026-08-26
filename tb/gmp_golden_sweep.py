#!/usr/bin/env python3
"""
Exhaustive (or sampled) functional verification of the `fpadd` DUT against a
GMP/MPFR-backed golden model, for ANY (lm, le) bit-width -- not just fp32.

Unlike tb/real2hex.c (which is hardwired to the host's native `float`, i.e.
fp32 only), this script builds the golden reference arithmetically using
gmpy2 (the Python wrapper around GMP/MPFR), by constructing an MPFR context
whose (precision, emin, emax) exactly reproduce the target (lm, le) format's
rounding, overflow-to-infinity and gradual-underflow-to-subnormal behaviour.
That lets it generate correctly-rounded IEEE-754-style references for any
custom (lm, le), including exhaustive coverage of tiny formats where fp32
golden vectors are meaningless.

It drives the *actual* tb/fpadd_tb.v testbench (which instantiates the
`fpadd` DUT directly) via iverilog/vvp as a subprocess, overriding its lm/le
parameters at compile time with `-P`. Nothing under tb/ or src/ is modified.

Usage:
    python3 tb/gmp_golden_sweep.py --lm 3 --le 4                 # exhaustive
    python3 tb/gmp_golden_sweep.py --lm 23 --le 8 --sample 200000 # fp32, sampled
    python3 tb/gmp_golden_sweep.py --lm 2 --le 3 --selftest       # sanity check only

Vector count for a full sweep of (a, b) over all 2**(2*(lm+le+1)) combinations,
times 2 for op in {0,1}. Exhaustive sweeps are only tractable for small custom
formats (roughly lm+le+1 <= 12-14 bits); use --sample for anything larger.
"""

import argparse
import itertools
import random
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

import gmpy2

REPO_ROOT = Path(__file__).resolve().parent.parent
TB_FILE = REPO_ROOT / "tb" / "fpadd_tb.v"
SRC_GLOBS = ["src/*.v", "src/utils/*.v", "src/datapath/*.v"]
LOG_DIR = REPO_ROOT / "docs" / "logs"


# --------------------------------------------------------------------------
# Golden model: bit pattern <-> gmpy2.mpfr, under a context matching (lm, le)
# --------------------------------------------------------------------------

def make_context(lm, le):
    """MPFR context reproducing an IEEE-754-style (1 sign, le exp, lm mantissa)
    format: correct round-to-nearest-even, overflow -> inf, gradual underflow
    -> subnormal. Formula verified against gmpy2.ieee(16/32/64)."""
    bias = (1 << (le - 1)) - 1
    emax = bias + 1
    emin = -(bias + lm - 2)
    return gmpy2.context(
        precision=lm + 1, emin=emin, emax=emax,
        subnormalize=True, round=gmpy2.RoundToNearest,
        trap_underflow=False, trap_overflow=False, trap_inexact=False,
        trap_invalid=False, trap_erange=False, trap_divzero=False,
    )


def decode_bits(bits, lm, le):
    """Exact decode of an (lm, le)-format bit pattern to an mpfr value.
    Caller must have set the matching context already (for precision)."""
    bias = (1 << (le - 1)) - 1
    exp_all1 = (1 << le) - 1
    sign = (bits >> (lm + le)) & 1
    exp_field = (bits >> lm) & exp_all1
    mant_field = bits & ((1 << lm) - 1)

    if exp_field == exp_all1:
        if mant_field == 0:
            val = gmpy2.mpfr("inf")
        else:
            val = gmpy2.mpfr("nan")
    elif exp_field == 0:
        if mant_field == 0:
            val = gmpy2.mpfr(0)
        else:
            q = gmpy2.mpq(mant_field) * gmpy2.mpq(2) ** (1 - bias - lm)
            val = gmpy2.mpfr(q)
    else:
        signif = (1 << lm) | mant_field
        e = exp_field - bias - lm
        q = gmpy2.mpq(signif) * gmpy2.mpq(2) ** e
        val = gmpy2.mpfr(q)

    return -val if sign else val


def encode_bits(val, lm, le):
    """Exact encode of an mpfr result (already correctly rounded/clamped by
    the (lm, le) context) back to an (lm, le)-format bit pattern.

    Matches this project's deliberate design choices (see special_op.v /
    fpadd.v and docs/logs/running_doc.md):
      - NaN always encodes as the canonical qNaN: sign=0, exp=all-1s,
        mantissa = 1000...0 (regardless of any NaN payload/sign).
      - Any zero result always encodes as +0 (sign forced to 0).
    """
    bias = (1 << (le - 1)) - 1
    exp_all1 = (1 << le) - 1

    if gmpy2.is_nan(val):
        return exp_all1 << lm | (1 << (lm - 1))

    if gmpy2.is_infinite(val):
        sign = 1 if val < 0 else 0
        return (sign << (lm + le)) | (exp_all1 << lm)

    if val == 0:
        return 0  # +0 always, per project convention

    sign = 1 if gmpy2.sign(val) < 0 else 0
    mag = abs(val)
    e, m = gmpy2.frexp(mag)          # mag == m * 2**e, m in [0.5, 1) -- gmpy2 returns (exponent, mantissa)
    signif = int(gmpy2.mul_2exp(m, lm + 1))  # exact integer, lm+1 bits
    true_exp = e - 1                 # mag == 1.xxx * 2**true_exp (signif has implicit leading 1 at bit lm)

    if true_exp < 1 - bias:
        # subnormal: value = mant_field * 2**(1-bias-lm), shift signif down accordingly
        shift = (1 - bias) - true_exp
        mant_field = signif >> shift
        exp_field = 0
    else:
        exp_field = true_exp + bias
        mant_field = signif & ((1 << lm) - 1)

    return (sign << (lm + le)) | (exp_field << lm) | mant_field


def golden_result(a_bits, b_bits, op, lm, le, ctx):
    with gmpy2.context(**ctx_kwargs(ctx)):
        a_val = decode_bits(a_bits, lm, le)
        b_val = decode_bits(b_bits, lm, le)
        if op:
            b_val = -b_val
        c_val = a_val + b_val
        return encode_bits(c_val, lm, le)


def ctx_kwargs(ctx):
    return dict(
        precision=ctx.precision, emin=ctx.emin, emax=ctx.emax,
        subnormalize=ctx.subnormalize, round=ctx.round,
        trap_underflow=False, trap_overflow=False, trap_inexact=False,
        trap_invalid=False, trap_erange=False, trap_divzero=False,
    )


# --------------------------------------------------------------------------
# Self-test: cross-check the golden model against Python's native fp32 add
# --------------------------------------------------------------------------

def selftest(trials=20000):
    import struct
    lm, le = 23, 8
    ctx = make_context(lm, le)
    rng = random.Random(0)
    width = lm + le + 1
    mismatches = 0
    for _ in range(trials):
        a_bits = rng.getrandbits(width)
        b_bits = rng.getrandbits(width)
        op = rng.getrandbits(1)
        got = golden_result(a_bits, b_bits, op, lm, le, ctx)

        a_f = struct.unpack("<f", struct.pack("<I", a_bits))[0]
        b_f = struct.unpack("<f", struct.pack("<I", b_bits))[0]
        ref_f = (a_f - b_f) if op else (a_f + b_f)
        ref_bits = struct.unpack("<I", struct.pack("<f", ref_f))[0]

        # canonicalize NaN payload/sign the same way encode_bits does, since
        # native struct/float NaNs won't match our canonical qNaN bit-for-bit
        import math
        if math.isnan(ref_f):
            ref_bits = (0xFF << 23) | (1 << 22)

        if got != ref_bits:
            mismatches += 1
            if mismatches <= 10:
                print(f"MISMATCH a={a_bits:08x} b={b_bits:08x} op={op} "
                      f"golden={got:08x} native={ref_bits:08x}")
    print(f"selftest: {trials - mismatches}/{trials} matched native fp32 add/sub")
    return mismatches == 0


# --------------------------------------------------------------------------
# Vector generation
# --------------------------------------------------------------------------

def gen_exhaustive(lm, le):
    width = 1 << (lm + le + 1)
    for a_bits, b_bits, op in itertools.product(range(width), range(width), (0, 1)):
        yield a_bits, b_bits, op


def gen_sample(lm, le, n, seed):
    width = lm + le + 1
    rng = random.Random(seed)
    for _ in range(n):
        yield rng.getrandbits(width), rng.getrandbits(width), rng.getrandbits(1)


# --------------------------------------------------------------------------
# Driving the real testbench/DUT via iverilog + vvp
# --------------------------------------------------------------------------

def run_dut(lm, le, vectors, work_dir):
    """Writes test_vectors.csv, compiles fpadd_tb.v (DUT included) with lm/le
    overridden via -P, runs it under vvp, and returns (stdout_text, n_run)."""
    csv_path = work_dir / "test_vectors.csv"
    rows = []
    n = 0
    for a_bits, b_bits, op, exp_bits in vectors:
        rows.append(f"{a_bits:0{(lm+le+1+3)//4}x},{b_bits:0{(lm+le+1+3)//4}x},{op},{exp_bits:0{(lm+le+1+3)//4}x}")
        n += 1
    with open(csv_path, "w") as f:
        f.write(f"{n}\n")
        f.write("\n".join(rows) + "\n")

    vvp_path = work_dir / "fpadd_tb.vvp"
    src_files = []
    for pattern in SRC_GLOBS:
        src_files.extend(str(p) for p in sorted(REPO_ROOT.glob(pattern)))

    compile_cmd = [
        "iverilog", "-o", str(vvp_path),
        f"-Pfpadd_tb.lm={lm}", f"-Pfpadd_tb.le={le}",
        str(TB_FILE), *src_files,
    ]
    proc = subprocess.run(compile_cmd, cwd=REPO_ROOT, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"iverilog compile failed:\n{proc.stdout}\n{proc.stderr}")

    # tb reads "./test_vectors.csv" and writes "./docs/logs/fail_log.log"
    # relative to cwd, so run from REPO_ROOT and stage the csv there.
    staged_csv = REPO_ROOT / "test_vectors.csv"
    shutil.copyfile(csv_path, staged_csv)
    try:
        proc = subprocess.run(["vvp", str(vvp_path)], cwd=REPO_ROOT,
                               capture_output=True, text=True, timeout=None)
    finally:
        staged_csv.unlink(missing_ok=True)

    return proc.stdout, n


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def fmt_real(bits, lm, le):
    ctx = make_context(lm, le)
    with gmpy2.context(**ctx_kwargs(ctx)):
        val = decode_bits(bits, lm, le)
        return str(val)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--lm", type=int, help="mantissa bits")
    ap.add_argument("--le", type=int, help="exponent bits")
    ap.add_argument("--sample", type=int, default=None,
                     help="run a random sample of N vectors instead of the exhaustive sweep")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--force", action="store_true",
                     help="allow exhaustive sweeps that would exceed the safety cap")
    ap.add_argument("--max-vectors", type=int, default=5_000_000,
                     help="safety cap on exhaustive-sweep vector count (default 5,000,000)")
    ap.add_argument("--selftest", action="store_true",
                     help="cross-check the golden model against native fp32 arithmetic and exit")
    args = ap.parse_args()

    if args.selftest:
        ok = selftest()
        sys.exit(0 if ok else 1)

    if args.lm is None or args.le is None:
        ap.error("--lm and --le are required (unless --selftest)")

    lm, le = args.lm, args.le
    ctx = make_context(lm, le)

    if shutil.which("iverilog") is None or shutil.which("vvp") is None:
        sys.exit("iverilog/vvp not found on PATH")

    if args.sample is not None:
        vec_iter = gen_sample(lm, le, args.sample, args.seed)
        total = args.sample
        mode = f"sampled ({args.sample} vectors, seed={args.seed})"
    else:
        pair_count = (1 << (2 * (lm + le + 1)))
        total = pair_count * 2  # x2 for op in {0,1}
        if total > args.max_vectors and not args.force:
            sys.exit(
                f"Exhaustive sweep for lm={lm}, le={le} is 2^{2*(lm+le+1)} = {pair_count} "
                f"(a,b) pairs x 2 op values = {total} vectors, exceeding "
                f"--max-vectors={args.max_vectors}.\n"
                f"Use --sample N for a random subset, or --force to proceed anyway."
            )
        vec_iter = gen_exhaustive(lm, le)
        mode = f"exhaustive (2^{2*(lm+le+1)} pairs x 2 ops = {total} vectors)"

    print(f"[gmp_golden_sweep] lm={lm} le={le}, mode: {mode}")

    def with_golden():
        for a_bits, b_bits, op in vec_iter:
            exp_bits = golden_result(a_bits, b_bits, op, lm, le, ctx)
            yield a_bits, b_bits, op, exp_bits

    with tempfile.TemporaryDirectory(dir=REPO_ROOT / "docs" / "logs") as tmp:
        work_dir = Path(tmp)
        stdout, n_run = run_dut(lm, le, with_golden(), work_dir)

    fails = [line for line in stdout.splitlines() if line.startswith("FAIL:")]

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_path = LOG_DIR / f"gmpsweep-lm{lm}-le{le}-{ts}.log"
    with open(log_path, "w") as f:
        f.write(f"gmp_golden_sweep: lm={lm} le={le}\n")
        f.write(f"mode: {mode}\n")
        f.write(f"vectors run: {n_run}\n")
        f.write(f"failures: {len(fails)}\n")
        f.write("-" * 60 + "\n")
        for line in fails:
            f.write(line + "\n")
            # augment with decoded real values for debugging
            try:
                parts = dict(kv.split("=") for kv in line[len("FAIL: "):].split())
                a_r = fmt_real(int(parts["a"], 16), lm, le)
                b_r = fmt_real(int(parts["b"], 16), lm, le)
                exp_r = fmt_real(int(parts["expected"], 16), lm, le)
                got_r = fmt_real(int(parts["got"], 16), lm, le)
                f.write(f"    a={a_r} b={b_r} op={parts['op']} "
                        f"expected={exp_r} got={got_r}\n")
            except Exception:
                pass

    print(f"[gmp_golden_sweep] {n_run} vectors run, {len(fails)} failures")
    print(f"[gmp_golden_sweep] log written to {log_path.relative_to(REPO_ROOT)}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
