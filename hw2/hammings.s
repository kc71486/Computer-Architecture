.text

.globl HammingDistance_s
.align 2
# hamming distance function
HammingDistance_s:
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s2, 12(sp)       # max_digit
    sw s3, 16(sp)       # hdist counter
    sw s4, 20(sp)       # lower part of x0
    sw s5, 24(sp)       # higher part of x0
    sw s6, 28(sp)       # lower part of x1
    sw s7, 32(sp)       # higher part of x1

    # get x0(s5 s4) and x1(s7 s6)
    mv s4, a0
    mv s5, a1
    mv s6, a2
    mv s7, a3
    mv t0, a0
    mv t1, a1
    mv t2, a2
    mv t3, a3
    
    # compare x0 with x1
    bgt s5, s7, 1f
    blt s5, s7, 2f
    bgt s4, s6, 1f
    j  2f
1:
    mv a0, s4           # a0 : lower part of x0
    mv a1, s5           # a1 : higher part of x0
    j  3f
2:
    mv a0, s6           # a0 : lower part of x1
    mv a1, s7           # a1 : higher part of x1
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
    add a0, a1, a5      # return y + (x & 0x7f);
    
    mv a1, a0           # a1 : max_digit (return value saved in a0)
    li a0, 0            # a0: hdist counter
    
    li a3, 32
    ble a1, a3, 6f
5:
    xor a2, s5, s7
    andi a2, a2, 1
    add a0, a0, a2
    srli s5, s5, 1
    srli s7, s7, 1
    addi a1, a1, -1
    bgt a1, a3, 5b
6:
    ble a1, zero, 8f
7:
    xor a2, s4, s6
    andi a2, a2, 1
    add a0, a0, a2
    srli s4, s4, 1
    srli s6, s6, 1
    addi a1, a1, -1
    bgt a1, zero, 7b
8:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36
    ret
