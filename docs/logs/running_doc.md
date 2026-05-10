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