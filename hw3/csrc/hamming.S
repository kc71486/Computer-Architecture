.text

.global HammingDistance
.global _start
.align 2
_start:
# hamming distance function
HammingDistance:

    # get x0(s5 s4) and x1(s7 s6)
    mv t0, a0           # lower part of x0
    mv t1, a1           # higher part of x0
    mv t2, a2           # lower part of x1
    mv t3, a3           # higher part of x1
    
    bgtu t1, t3, 1f     # compare x0 with x1 unsigned, my previous version had bug
    bltu t1, t3, 2f
    bgtu t0, t2, 1f
    j  2f
1:
    mv a0, t0           # a0 : lower part of x0
    mv a1, t1           # a1 : higher part of x0
    j  3f
2:
    mv a0, t2           # a0 : lower part of x1
    mv a1, t3           # a1 : higher part of x1
3:
    # count leading zeros
    beq a1, zero, 4f
    mv a0, a1
    li a1, 32           # if (y != 0) { x = y; y = 32; }
4:
    srli a5, a0, 1
    or a0, a0, a5
    srli a5, a0, 2
    or a0, a0, a5
    srli a5, a0, 4
    or a0, a0, a5
    srli a5, a0, 8
    or a0, a0, a5
    srli a5, a0, 16
    or a0, a0, a5
    li a6, 0x55555555
    and  a6, a5, a6
    sub  a0, a0, a6      # x -= ((x >> 1) & 0x55555555)
    srli a5, a0, 2
    li a6, 0x33333333
    and a4, a5, a6
    and a7, a0, a6
    add a0, a4, a7      # x = ((x >> 2) & 0x33333333) + (x & 0x33333333)
    srli a5, a0, 4
    add a5, a5, a0
    li a6, 0x0f0f0f0f
    and a0, a5, a6      # x = ((x >> 4) + x) & 0x0f0f0f0f
    srli a5, a0, 8
    add a0, a0, a5      # x += (x >> 8);
    srli a5, a0, 16
    add a0, a0, a5      # x += (x >> 16);
    andi a5, a0, 0x7f
    add a1, a1, a5      # return y + (x & 0x7f) --> max_digit
    li a0, 0            # a0: hdist counter
    
    li a3, 32
    bleu a1, a3, 6f
5:
    xor a2, t1, t3
    andi a2, a2, 1
    add a0, a0, a2
    srli t1, t1, 1
    srli t3, t3, 1
    addi a1, a1, -1
    bgtu a1, a3, 5b
6:
    bleu a1, zero, 8f
7:
    xor a2, t0, t2
    andi a2, a2, 1
    add a0, a0, a2
    srli t0, t0, 1
    srli t2, t2, 1
    addi a1, a1, -1
    bgtu a1, zero, 7b
8:
    ret
