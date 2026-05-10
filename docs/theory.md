# Theory on Floating-Point Numbers
A major drawback of fixed-point numbers is the lack of range, i.e fixed-point numbers have fixed precision due ot the fixed bit weights but the highest and lowest weights are limited. To store very large or very small numbers, too many bits would be required in the case of fixed-point representations, and the intermediate bits barely influence the magnitude of the number. In a way, the fixed-point numbers provide fine details at every range, which is unnecessary. Floating-point numbers solve this issue by storing only a fixed number of precision bits (mantissa) around a given value of the exponent. A floating-point binary number can be represented in the following the manner:
```math
A = M_A . 2^{E_A}
```
Where $M_A$ is the mantissa and $E_A$ is the exponent. 
## Mantissa Normalization
Any given number can have **infinite** floating-point representations as $M_A$ can have any number of leading zeros after the decimal point, preceding the first significant/set bit. The IEEE 754 standard fixes this issue by a process of **normalization**, where in $E_A$ is adjusted to let $M_A$ have a range of $[2^{E_A},2^{E_A+1})$, which is possible by setting the bit after the decimal-point to be 1, i.e. 
```math
    M_A = 1.(x_{lm-1})(x_{lm-2})...(x_{0})
```
where $x_i$ represents the i-th most significant mantissa bit, and $lm$ represents the number of mantissa bits. 

If $E_A$ is a positive integer represented by $le$ bits then, by induction, all normalized floating-point numbers take on the range: $R = [2^{0},2^{1})\cup[2^{1},2^{2})\cup...\cup[2^{2^{lm}-2},2^{2^{lm}-1}) = [1,2^{2^{lm}-1})$
The range of floating-point binary numbers, thus, scales **exponentially (double-exponential)** to the number of exponent bits $le$.

However, a noticable flaw in this incomplete representation is that only fractional numbers and integers greater than or equal to 1 can be represented. This implies that normalized numbers with exponents less than 0 must also be represented. This is achieved through exponent biasing.

## Exponent Biasing

## Sub-normal Numbers

# Reference
- [IEEE Standard for Floating-Point Arithmetic](https://drive.google.com/file/d/1d_NoahP3ChJ9Ol-pxoWtLSK2fnfYp0FW/view?usp=sharing) 