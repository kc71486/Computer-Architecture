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
    
    # compare x0 with x1
    bgt s5, s7, paramx0
    blt s5, s7, paramx1
    bgt s4, s6, paramx0
    j  paramx1
paramx0:
    mv a0, s4           # a0 : lower part of x0
    mv a1, s5           # a1 : higher part of x0
    j  endparam
paramx1:
    mv a0, s6           # a0 : lower part of x1
    mv a1, s7           # a1 : higher part of x1
endparam:
    jal ra, count_leading_zero
    li s2, 64
    sub s2, s2, a0      # s2 : max_digit (return value saved in a0)
    li s3, 0            # s3: hdist counter
    
    li t3, 32
    ble s2, t3, loop1e
loop1s:
    xor t0, s5, s7
    andi t0, t0, 1
    add s3, s3, t0
    srli s5, s5, 1
    srli s7, s7, 1
    addi s2, s2, -1
    bgt s2, t3, loop1s
loop1e:
    ble s2, zero, loop2e
loop2s:
    xor t0, s4, s6
    andi t0, t0, 1
    add s3, s3, t0
    srli s4, s4, 1
    srli s6, s6, 1
    addi s2, s2, -1
    bgt s2, zero, loop2s
loop2e:
    mv a0, s3
    
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

# count leading zeros
count_leading_zero:
    beq a1, zero, 1f
    mv a0, a1
    li a1, 32           # if (y != 0) { x = y; y = 32; }
1:
    srli t0, a0, 1
    or a0, a0, t0
    srli t0, a0, 2
    or a0, a0, t0
    srli t0, a0, 4
    or a0, a0, t0
    srli t0, a0, 8
    or a0, a0, t0
    srli t0, a0, 16
    or a0, a0, t0
    
    # clz
    li t1, 0x55555555
    and  t1, t0, t1
    sub  a0, a0, t1      # x -= ((x >> 1) & 0x55555555)
    srli t0, a0, 2
    li t1, 0x33333333
    and t2, t0, t1
    and t3, a0, t1
    add a0, t2, t3      # x = ((x >> 2) & 0x33333333) + (x & 0x33333333)
    srli t0, a0, 4
    add t0, t0, a0
    li t1, 0x0f0f0f0f
    and a0, t0, t1      # x = ((x >> 4) + x) & 0x0f0f0f0f
    srli t0, a0, 8
    add a0, a0, t0      # x += (x >> 8);
    srli t0, a0, 16
    add a0, a0, t0      # x += (x >> 16);
    li t1, 64
    sub t1, t1, a1
    andi t0, a0, 0x7f
    sub a0, t1, t0      # return 64 - y - (x & 0x7f);
    ret
