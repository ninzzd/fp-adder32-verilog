### Test 1
**Date:** 06-03-2026
**File:** [t1](/docs/logs/t1-060326.png)
I generated 32-bit tests vectors for input operands using the C code realtohex. Here were the cases I tested for:
1. 0.1 + 0.2 ->  Expected real result = 0.3, Obtained real result = 0.2375
   
2. 0.5 - 0.5 ->  Expected real result = 0.0, Obtained real result = 0.0 (Currently inspecting)
    <u>Issues</u>
   - Exponent of the result is non-zero. Both number have same exp (exp = 0111 1110b = 7Eh = 126d (biased) = -1 (unbiased)). The mantissa bits are 0 (Only leading 1 after decimal point is significant => 1.0 x 2^(-1) = 0.5)
   - Result exponent is = 0110 0100b = 64h = 100d = -27, still not subnormal. Mantissa bits are all zero =>  result = 1.0 x 2^(-27) which is approx 0
   - Clearly some exponent shifting problem
  
    <u> Observations </u>
   - I was using **reduction NOR** for obtaining leading 1. It should be **reduction OR**. Noticed that mantissa, even after adding leading bit after decimal-point, was showing to be 0.  (***resolved***)
3. Other 3 test vectors were also giving erroneaous results

### Test 2
**Date:** 07-03-2026
**File:** [t2](/docs/logs/t2-070326.png)
Same vectors as previous test, resolved only the reduction NOR to OR for the MSB (one's bit after decimal point)
<u> Observations </u>
1. All test vectors with non-zero expected results are correct (matching perfectly)
2. For zero results, exponent is still non-zero
3. In 2nd vector, a = 0.5, b = 0.5, op = 1(sub), result_exp = 0110_0100b = 64h = 100d = -27d (unbiased)
    Likely cause: Due to this resm_p_encoder outputting isZero=1 and shamt=26. isZero is not being used (***resolved***)

### Test 4
**Date:** 17-03-2026
**File:** [t4](/docs/logs/t4-170326.png)
Test cases were wrongly interpreted. Case of inputs a = 10, b = 80000008, and sub is resulting in the wrong value
Exp_res = cc989680, Res = 4c989680 (MSB is wrong =>  sign-bit error?)
TODO: Recheck output sign logic (***resolved***)
This was resolved by flipping (XOR) originally conceptualized sign logic when op=1 (when subtracting) and ageb=0 (when b is larger, due to which obviously a0 = b, b0 = a, but flipping operands for mantissa sub must also flip sign)

### Test 5
**Date:** 17-03-2026
**File:** [t5](/docs/logs/t5-170326.png)
*Erroneous cases:*
(a) FAIL: a=00000001 b=00000002 op=0 expected=00000003 got=00800003
(b) FAIL: a=80000001 b=00000001 op=0 expected=00000000 got=80000000
*Possible issues:*
(a) exp is incremented by 1 for mantissa denormalization at the beginning, must subtract 1 if result exponent is 1 and mantissa does not have leading 1 (result is subnormal)
(b) +0 and -0 error, both are same, must enforce +0 always
*TODO*: Resolve (a) and (b)
(b) has been resolved (I think). A decrementer is required for (a), in the case where both inputs are sub-normal and the result is also sub-normal
*Fixes:*
(a) was resolved by gating the result exponent after rounding. For both sub-normal operands, if the result is sub-normal, exponent must be 8'h01 (add 1 initially, before exp_comparator stage, to adjust for sub-normal numbers). No need for decrementer or subtracter. In fact, just gate LSB, make it 0 when sub-normal, else it will be normal or it will be incremented during rounding anyways. It is guaranteed all other exp bits will be 0 when checking for resm_isSubnormal from result mantissa.
(b) was resolved by gating sign-bit with maddres_isZero (mantissa-add-result-is-zero), obtained by shifting priority encoder

### Test 6
**Date:** 17-03-2026
**File:** [t6](/docs/logs/t6-fail-170326.log)
1.  FAIL: a=3f800000 b=0da24260 op=0 expected=3f800000 got=3f8a2426
    **Potential causes**:
    - exp_b is 100 less than exp_a, mantissa_right shifter should result in all 0 bits.
  
    **Observations**:
    - Noticed that shamt after clipping, is coming to be 4, input shamt was 64. It should be pass 23 as shamt gets clipped for all values >= 23. 
    - In the code, the min module is outputting the minimum of shamt[\$clog2(lm+4)-1:0] and lm_add_3. In this case, shamt[le-1:0] entrely represents 64, while shamt[\$clog2(lm+4)-1:0] = shamt[4:0] = 5'b00100 = 4 (observed shift amount). I was comparing only the lower bits that were the smallest number of bits sufficient to represent lm+3. But higher bits of shamt[le-1:0] easily makes shamt larger than lm+3 = 26. Hence, not considering upper bits is incorrect. Instead, represent lm+3 = 26 in le-number of bits (8-bit instead of 5-bit) and then compare.
 
    **Fixes and Post-Fix Observations:**
    - Except test case 3 from t6, every other failed test was resolved. All other test cases also incuded the same mantissa related errors caused by shamt clipping in the lower-mantissa right-shifter.
    - t7 logs basically contains test case 3 from t6 and nothing else, good stuff.

[Not going to represent other cases as they were fixed by (1). Test case 3 will be handled in t7]

### Test 7
**Date:** 18-03-2026
**File:** [t7](/docs/logs/t6-fail-170326.log)
1. FAIL: a=00000001 b=80800000 op=0 expected=807fffff got=807ffffe
   **Observations**:
   - I analyzed the GTKwave output. Both inputs are sub-normal, the output is also supposed to be sub-normal
   - subnormal numbers are represented with mantissas that have MSB to be 0 instead of 1, and biased exp is always 1 (forcibly incremented)
   - after result mantissa is computed, leading zeros are checked for (result = 3FFFFF8) => priority encoder outputs 1 as shamt
   - 1 is compared with current exponent of A0 (operand with exp greater than or equal to other), which is also 1 cuz of the second point
   - final shamt is 1, which is not correct, it is supposed to be zero (***resolved***)
  
   **Thoughts**
   - I need to handle shamt for sub-normal inputs and if the result is sub-normal, A0 will always be 1 in this case. Irrespective of number of leading zeros in the subnormal result, you'll always have a shamt of 1 because shamt = min(exp_a0,pe_out), unless pe_out is 0, in which case result had a leading one, which is normal, not sub-normal
   - => when both a and b are sub-normal, if mantissa result is also sub-normal, mantissa will always be shifted by 1
   - exp_a0 should be checked if its 1 or not, and if so, result mantissa should be checked if it is sub-normal
   - note: rounding does not face any issue because g,r and s bits will always be 0 with both sub-normal operands, you will always round down, truncate grs
   - in this case, one input is subnormal, the other input is the smallest possible normal number, and are being subtracted, resulting in a sub-normal number
   - irrespective of sub-normal addition or normals being subtracted, there may be cases wherein, after left-shifting mantissa by a certain amount, adjusted exponent could be 1, and there still may not be a leading zero. The result is already sub-normal in such cases, but the current left shifter and priority encoder try to shift till there exists a leading 1 or till exp_a0 becomes 0. But in the true representation of sub-normal numbers, exp is 1 always, with no leading 1. this not being accounted to by the leading-zeros left shift logic: sub-normal domain doesn't start at exp=0, it starts at exp=1. pe_out (maddres_lshamt) should not be clipped to exp_ao (a0e), it should be clipped to a0e-1, such that a0e - clipped(maddres_lshamt) >= 1
   - this won't affect the case of normal results, maddres_lshamt will mostly if not always be the minimum, and not a0e
   - circuit for sub-normal representation of output is ready.
   - one thing is left to be checked: if I declare result to be sub-normal during leading zero shift, is it possible for mantissa increment while rounding to result in a leading 1 (sub-normal becomes normal after rounding)
   - the rounding part should still be fine: round_cout cannot be 1 (MSB is already 0 due to subnormal). if MSB of resm_around is 0, resm_isSubnormal is triggered, rese_bround (output of a0e - clipped(maddres_lshamt)) will be made 0. If MSB of resm_around is 1, rounding produces normal result, for which rese_bround is already decimal 1, resm_isSubnormal is not triggered, so result must be still valid
   - Finally: change min(a0e, maddres_lshamt) to min(a0e-1,maddres_lshamt) before the subtraction to get rese_bround : build dedicated decrementer circuit
  
Case (1) has been ***resolved***

### Test 9
**Date:** *18-08-2026*
**File:** *[t9-fail-180826.log](t9-fail-180826.log)*

1.  FAIL: a=7f800000 b=ff800000 op=0 expected=7fc00000 got=ff800000
    Observations:
    - a  = `inf`, b = `-inf`, op = `+`
    - expected ans = `inf - inf` = `NaN`
    - obtained ans = `-inf`

    Cause:
    - The previous condition for handling `inf` operands was wrong
    - First, check if an operand is `NaN`, if true, output is also NaN
    - Else, check if an operand is `inf`, if true, output is also `inf` (*incorrect condtion, only holds when exactly one of the operands is inf or both are inf and signs after adjusting op, are the same*)
    - Previous assigment ternary condition:
    ```verilog
        assign out = a_is_nan | b_is_nan ? 2'b10 : a_is_inf | b_is_inf ? 2'b01 : 2'b00;
    ```

    Fix:
    ```verilog
        assign maddop = a[lm+le] ^ b[lm+le] ^ op;
        assign out = a_is_nan | b_is_nan ? 2'b10 : a_is_inf & b_is_inf & maddop ? 2'b10 : a_is_inf | b_is_inf ? 2'b01 : 2'b00;
    ```
    - `*_is_inf` checks only the exponent, not the sign
    - `madopp` or *mantissa-adder-operation* being 1, already acounts for $S_a$, $S_b$ and `op`

    **Note: Fail cases (2) is also caused by the same issue, other issues remain unsolved and appear in Test 10.

### Test 10
**Date:** *18-08-2026*
**File:** *[t10-fail-180826.log](t10-fail-180826.log)*

1. FAIL: a=7f800000 b=00000001 op=1 expected=7f800000 got=ff800000

    Observations:
    - a = `+inf`, b = `2^(-149)` (smallest non-zero positive number in fp32), op = `-`
    - Expected ans = `+inf`
    - Observed ans = `-inf`

    Causes:
    - The output sign is determined by the result of the this mux:
    ```verilog
    mux #(
        .W(1),
        .N(2)
    ) res_sign_mux (
        .in({maddop&~sop_out[1],res_sign}), // Design choice: output canonical qNaN always, with sign bit 0
        .sel(sop_out_or),
        .out(c[lm+le])
    );
    ```
    - When `sop_out[1]` is `1'b1`, the output must be qNaN, which by convention assumed in this project, must be positive ($S_c$ = 0), which is enforced by the the AND gate feeding input line 1.
    - But when `sop_out[1]` is `1'b0`, the other input of the AND gate, `maddop`, is passed. This case always corresponds to `sop_out[0]` is `1'b0`
    - In this failure case, `maddop` is clearly `-`, or `1'b1`, which is not representative of the expected sign.

    Fix:
    - Either change the entire $S_c$ mux (seems fairly redundant) and use only `res_sign` and not `maddop`, or pass a special `sop_sign` bit from the *special_op* module.
    - Why not take `res_sign` for `inf` sign determination? `res_sign` is obtained deep in the main datapath, after mantissa addition, leading zero detection, mantissa normalization and exponent adjustment, which may cause 
    ```verilog
    assign flag = ~maddcout&maddop; // if the result is negative, we need to take 2's complement
    assign res_sign = (a0s ^ flag ^ (op&~ageb));
    ```
    - Seems like `res_sign` should hold for `inf` operands too. *(explain in detail below)*
    - New sign assignment:
    ```verilog
    assign c[lm+le] = res_sign & ~sop_out[1];
    ```


2. FAIL: a=80000000 b=80000000 op=0 expected=80000000 got=00000000

    Observations:
    - a = `-0`, b = `-0`, op = `+`
    - Expected ans = `-0`
    - Observed ans = `+0`

    Causes:
    - My design used to enforce `+0` strictly due to `..&~maddress_isZero` in the following line in *[fpadd](../../src/fpadd.v)*:
    ```verilog
        assign res_sign = (a0s ^ flag ^ (op&~ageb))&~maddres_isZero;
    ```

    Fix:
    - Omit that ANG-gating entirely:
    ```verilog
        assign res_sign = (a0s ^ flag ^ (op&~ageb));
    ```
*Fail cases (1) and (2) were successfully resolved using the suggested fixes*

### Test 11
**Date:** *27-08-2026*
**File:** *[t11-fail-270826.log](t11-fail-270826.log)*

*Same vectors as Test 10 and 9, contains remaining errors not solved in fixes for Test 10 and 9*
1. FAIL: a=7f7fffff b=73000000 op=0 expected=7f800000 got=7f7fffff
    Observations:
    - a = `(2 - 2^(-23))*2^(127)` (largest non-`inf` posiive number), b = `2^(103)` (shamt = 24), op = `+`
    - Expected ans = `+inf`
    - Observed ans = a

    Causes:
    - Shamt = 24 is very specific
    - b is normal, hence has a leading 1
    - b < a, which means that after manstissa shifting of b, leading 1 should appear in G bit (hence, specfic shamt value)
    - However, in *[lm_r_shifter](../../src/datapath/lm_r_shifter.v)*:
    ```verilog
        mux #(
        .N(lm+1),
        .W(1)
    ) g_mux ( // selecter for ground bit
        .in({in[lm-1:0],1'b0}),
        .sel(shamt_[$clog2(lm+1)-1:0]),
        .out(out[2])
    );
    ```
    - G mux must be (lm+2):1 mux, not (lm+1):1 mux *(I most likely forgot about leading bit and considered mantissa size as lmmmmm, not lm+1)*
    - Also, input line starts from `in[lm-1]`, ignoring `in[lm]`, basically ignoring leading bit
    - Not an issue if leading bit is 0 (subnormal), but will always be missed if 1 (for all normal numbers)
    - Similar issue with R mux:
    ```verilog
    mux #(
        .N(lm+2),
        .W(1)
    ) r_mux ( // selecter for round bit
        .in({in[lm-1:0],2'b00}),
        .sel(shamt_[$clog2(lm+3)-1:0]),
        .out(out[1])
    );
    ```

    Fix:
    - Increase N by 1 for both muxes
    - Start input lines from `in[lm]` instead of `in[lm-1]`

*(Ran the same test vectors again, no fail cases, hence fail cases (2) and (3) were different instances of documented fail case (1))*

### Test 12
**Date:** *28-08-2026*
**File:** *[gmpsweep-lm23-le8-20260828-213842.log](/docs/logs/gmpsweep-lm23-le8-20260828-213842.log)*

*This issue had been fixed (see [gmpsweep-lm7-le8-20260828-181427.log](/docs/logs/gmpsweep-lm7-le8-20260828-181427.log)), I reproduced the issue to document the original issue and the fix*

1. FAIL: a=8c6e9037 b=ffda0336 op=1 expected=7fc00000 got=7f800000
    
    Observation:
    - a=-1.83782511e-31 b=nan op=1 expected=nan got=inf
    - All other fail cases are similar to this
    
    Causes:
    - At least one of the operands is a NaN
    - Old code could handle sNaN and **canonical** qNaNs only:
    ```verilog
        assign a_is_snan = &(a[lm+le-1:lm]) & ~a[lm-1] & |(a[lm-2:0]);
        assign b_is_snan = &(b[lm+le-1:lm]) & ~b[lm-1] & |(b[lm-2:0]);
        assign a_is_qnan = &(a[lm+le-1:lm]) & a[lm-1] & ~|(a[lm-2:0]);
        assign b_is_qnan = &(b[lm+le-1:lm]) & b[lm-1] & ~|(b[lm-2:0]);
        // a_is_qnan = 1 if a = x|1...1|10...0
        // b_is_qnan = 1 if b = x|1...1|10...0
        // the reduce NOR - ~|(a[lm-2:0]) is responsible
        // Non-canonical qNaNs: x|1...1|1x...x, not caught
        // For eg. a = 1|1...1|101001...0
        // a is still a qNaN, slips detection

    ```
    - Non-canonical qNaNs would pass both sNaN and erroneous qNaN checks

    Fix:
    - Changed the qNaN assign statement:
    ```verilog
        assign a_is_snan = &(a[lm+le-1:lm]) & ~a[lm-1] & |(a[lm-2:0]);
        assign b_is_snan = &(b[lm+le-1:lm]) & ~b[lm-1] & |(b[lm-2:0]);
        assign a_is_qnan = &(a[lm+le-1:lm]) & a[lm-1];
        assign b_is_qnan = &(b[lm+le-1:lm]) & b[lm-1];
        // reduction is required only for sNaN to distinguish it from infs
    ```

### Test 13
**Date:** *28-08-2026*
**File:** *[gmpsweep-lm7-le8-20260828-181427.log](/docs/logs/gmpsweep-lm7-le8-20260828-181427.log)*

1. FAIL: a=d82c b=629f op=1 expected=e29f got=e2ca
    Observations:
    - a=-7.565e+14 b=1.467e+21 op=1 expected=-1.467e+21 got=-1.863e+21

    Causes:
    - bf16 is particularly special
    - lm = 7 => clog2(lm) = clog2(lm+1) = 3
    - But clog2(lm+2) = clog2(lm+3) = clog2(lm+4) = 4
    - For non-trivial shifts (without flushing out all mantissa bits), shamt can take on the values: $[0,lm+3]$
    - Hence: shamt_ = clip(shamt,lm+3)
    - But shamt_ is also an le-bit vector
    - Only the first (lm+4) values of shamt_ are meaningful for shifting, hence when passing shamt_ to the select inputs of the muxes, shamt_ should be truncated to clog2(lm+4) bits or `shamt_[$clog2(lm+4)-1:0]`
    - This was being done only for the S bit mux
    - For all output significand bits, the truncation used earlier was: `shamt_[$clog2(lm+1)-1:0]`, as I had assumed that there are only lm+1 meaningful input lines to worry about.
    - G mux sel was set as `shamt_[$clog2(lm+2)-1:0]`, R mux sel was set as `shamt_[$clog2(lm+3)-1:0]`, which work only in this case because values lm+2 and lm+3 require an extra bit to represent.
    - However, this inherently truncates the bit 4 of shamt_, which not only makes it impossible to represent shamt values of 8, 9 and 10 correctly, but also, the passed truncated bits would have values 0, 1 and 2 respectively (shamt mod 7)
    - Hence all significand bits were wrongly shifted by 0, 1 or 2 right-shifts instead of 8, 9 or 10 right-shifts, proving that truncating based on number of leading input-mantissa bits is inaccurate

    Fix:
    - Change truncation bit-width for the select line of all muxes to be (lm+4), let all muxes, including G and R, to be (lm+4):1 muxes
    - Adjust for the additional bits by appending (i+3) 0-bits to the left of `in[lm:i]` for output-significand muxes, in the input lines.
    - For G and R muxes, append `2'b00` and `1'b0` to the left of `in[lm:0]`, respectively, in the input lines.

*This fixed the error and bf16 was verified over 200000 randomized input vectors (see [gmpsweep-lm7-le8-20260828-231445.log](/docs/logs/gmpsweep-lm7-le8-20260828-231445.log))*

### Test 14
**Date:** *28-08-2026*
**File:** *[gmpsweep-lm3-le4-20260828-233750.log](/docs/logs/gmpsweep-lm3-le4-20260828-233750.log)*

*This was an exhaustive test of the 8-bit E4M3 precision*

*First, gmpy2 tester is also faulty. It asserts all zero-outputs to have positive sign, hence zero-results are always +0.0*

*However, the design is bugged too. It is outputting -0.0 in many cases which should actually be +0.0*

1. FAIL: a=80 b=00 op=0 expected=00 got=80
    Observations:
    - a=-0.0 b=0.0 op=0 expected=0.0 got=-0.0 (case (v))
    - (-0.0) + (+0.0) must be +0.0

    Causes :
    - Cases in which result can be -0.0:
      - (i) (-0.0) + (-0.0) -> maddop = 0, sign_a = 1
      - (ii) (-0.0) - (+0.0) -> maddop = 1, sign_a = 1
    - Cases in which result must be +0.0:
      - (iii) (+0.0) + (+0.0)
      - (iv) (+0.0) - (-0.0)
      - (v) (-0.0) + (+0.0)
      - (vi) (-0.0) - (-0.0)
      - (vii) (+0.0) - (+0.0)
      - (viii) (+0.0) + (-0.0)
      - (ix) (+a) + (-a) (for non-zero a)
      - (x) (+a) - (+a)
      - (xi) (-a) + (+a)
      - (xii) (-a) - (-a) 
    - This fail case violates case (v)

    Fix:
    - In all cases, `ageb` = 1 (same magnitudes, either cancel or add and have zero-magnitude)
    - This means: $A_0 = A$ and $B_0 = B$
    - $\implies S_C = S_A \oplus (\overline{maddcout}.maddop)$
    - When `maddop` is 0 (add), you get: $S_C = S_A$ which is correct, and implements cases (i, ii, iii, iv) correctly
    - When `maddop` is 1 (sub), since $M_A = M_B$,`maddcout` is always 1 (sub(a,b) = $2^n$ + a - b = $2^n$ => carry)
    - Hence, you still get: $S_C = S_A$, which is clearly not true, and it needs to enforced to 0.
    - The issue arises only when `maddop` is 1, and `maddres` is `(lm+4)'b0`, OR `maddres_isZero` is 1.
    - Hence, just gate `res_sign` as:
    ```verilog
        assign res_sign = (a0s ^ flag ^ (op&~ageb)) & ~(maddop & maddres_isZero);
    ```

### Test 15
**Date:** *01-09-2026*
**File:** *[gmpsweep-lm3-le4-20260901-010534.log](./gmpsweep-lm3-le4-20260901-010534.log)*

1. FAIL: a=80 b=00 op=1 expected=00 got=80
2. FAIL: a=80 b=80 op=0 expected=00 got=80

    Observations:
    - in 1 - a=-0.0 b=0.0 op=1 expected=0.0 got=-0.0
    - in 2 - a=-0.0 b=-0.0 op=0 expected=0.0 got=-0.0

    Causes:
    - Design is correct, gmp golden model is forcing strict positive-zero

    Fix:
    - Edit golden reference, design is correct