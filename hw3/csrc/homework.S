.set SYSWRITE, 64
.set STDOUT, 1

.global _start

.data
.align 4
    t1_x0: .word 0x00100000
    t1_y0: .word 0x00130000
    t1_x1: .word 0x000FFFFF
    t1_y1: .word 0x00000000
    t2_x0: .word 0x00000001
    t2_y0: .word 0x00000002
    t2_x1: .word 0x7FFFFFFF
    t2_y1: .word 0xFFFFFFFE
    t3_x0: .word 0x00000002
    t3_y0: .word 0x8770228F
    t3_x1: .word 0x00000002
    t3_y1: .word 0x8370228F
    hamstr: .string "Hamming Distance:"
    ansstr: .string "00"
    newl:   .byte '\n'
    intmap: .string "0001020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364"

.text
.align 4

_start:
_sinit:
    la sp, _sp
    call main
_sexit:
    la t0, _halt        # halt address
    li t1, 0xbabecafe
    sw t1, 0(t0)
dead_loop:
    j dead_loop         # infinite loop
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
1:  mv a0, t0           # a0 : lower part of x0
    mv a1, t1           # a1 : higher part of x0
    j  3f
2:  mv a0, t2           # a0 : lower part of x1
    mv a1, t3           # a1 : higher part of x1
3:  beq a1, zero, 4f    # count leading zeros
    mv a0, a1
    li a1, 32           # if (y != 0) { x = y; y = 32; }
4:  srli a5, a0, 1
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
5:  xor a2, t1, t3
    andi a2, a2, 1
    add a0, a0, a2
    srli t1, t1, 1
    srli t3, t3, 1
    addi a1, a1, -1
    bgtu a1, a3, 5b
6:  bleu a1, zero, 8f
7:  xor a2, t0, t2
    andi a2, a2, 1
    add a0, a0, a2
    srli t0, t0, 1
    srli t2, t2, 1
    addi a1, a1, -1
    bgtu a1, zero, 7b
8:  ret
printstr:
    mv a2, a1           # length of input string
    mv a1, a0           # input string
    li a0, STDOUT       # write to stdout
    li a7, SYSWRITE     # "write" syscall
    ecall               # invoke syscall to print the string
    ret
printint:
    addi sp, sp, -4
    sw   ra, 0(sp)
    slli a0, a0, 1
    la   a1, intmap
    add  a1, a1, a0       # get int string
    li   a0, STDOUT       # write to stdout
    li   a2, 2            # length = 2
    li   a7, SYSWRITE
    ecall                 # invoke syscall
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
newline:
    li   a0, STDOUT       # write to stdout
    la   a1, newl         # get '\n'
    la   a2, 1            # length = 1
    li   a7, SYSWRITE
    ecall               # invoke syscall
    ret
main:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)
    li   s0, 0x0004
    la   a0, t1_x0
    lw   a0, 0(a0)
    la   a1, t1_y0
    lw   a1, 0(a1)
    la   a2, t1_x1
    lw   a2, 0(a2)
    la   a3, t1_y1
    lw   a3, 0(a3)
    call  HammingDistance
    sw   a0, 0(s0)
    la   a0, t2_x0
    lw   a0, 0(a0)
    la   a1, t2_y0
    lw   a1, 0(a1)
    la   a2, t2_x1
    lw   a2, 0(a2)
    la   a3, t2_y1
    lw   a3, 0(a3)
    call  HammingDistance
    sw   a0, 4(s0)
    la   a0, t3_x0
    lw   a0, 0(a0)
    la   a1, t3_y0
    lw   a1, 0(a1)
    la   a2, t3_x1
    lw   a2, 0(a2)
    la   a3, t3_y1
    lw   a3, 0(a3)
    call  HammingDistance
    sw   a0, 8(s0)
    la   a0, hamstr
    li   a1, 17
    call  printstr
    lw   a0, 0(s0)
    call  printint
    call  newline
    la   a0, hamstr
    li   a1, 17
    call  printstr
    lw   a0, 4(s0)
    call  printint
    call  newline
    la   a0, hamstr
    li   a1, 17
    call  printstr
    lw   a0, 8(s0)
    call  printint
    call  newline
    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret
    
