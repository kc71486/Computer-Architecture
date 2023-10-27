.set SYSEXIT, 93

.extern get_instret
.extern get_cycles
.extern HammingDistance_c
.extern printstr
.extern itos
.extern printchar
.extern printint

.global start
.global main

.data
    t1_x0: .word 0x00100000
    t1_y0: .word 0x00130000
    t1_x1: .word 0x000FFFFF
    t1_y1: .word 0x00000000
    t2_x0: .word 0x00000001
    t2_y0: .word 0x00000002
    t2_x1: .word 0x7FFFFFFF
    t2_y1: .word 0xFFFFFFFE
    t3_x0: .word 0x00000002
    t3_y0: .word 0x8370228F
    t3_x1: .word 0x00000002
    t3_y1: .word 0x8370228F
    intbuf: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    cyclestr: .string "Elapse cycle:"
    instrstr: .string "Instruction count:"
    hamstr: .string "Hamming Distance:"

.text
exit:
    li a7, SYSEXIT
    ecall
start:
    call main
    j exit
main:
    add	 sp,sp,-48
    sw  ra,44(sp)
    sw  s0,40(sp)
    add  s0,sp,48
    call  get_instret
    sw  a0,28(sp)
    call  get_cycles
    sw  a0,24(sp)
    la  a0, t1_x0
    lw  a0, 0(a0)
    la  a1, t1_y0
    lw  a1, 0(a1)
    la  a2, t1_x1
    lw  a2, 0(a2)
    la  a3, t1_y1
    lw  a3, 0(a3)
    call  HammingDistance_c
    sw  a0,20(sp)
    la  a0, t2_x0
    lw  a0, 0(a0)
    la  a1, t2_y0
    lw  a1, 0(a1)
    la  a2, t2_x1
    lw  a2, 0(a2)
    la  a3, t2_y1
    lw  a3, 0(a3)
    call  HammingDistance_c
    sw  a0,16(sp)
    la  a0, t3_x0
    lw  a0, 0(a0)
    la  a1, t3_y0
    lw  a1, 0(a1)
    la  a2, t3_x1
    lw  a2, 0(a2)
    la  a3, t3_y1
    lw  a3, 0(a3)
    call  HammingDistance_c
    sw  a0,12(sp)
    call  get_cycles
    sw  a0,8(sp)
    call  get_instret
    sw  a0,4(sp)
    li  a1,13
    la  a0,cyclestr
    call  printstr
    lw  a4,8(sp)
    lw  a5,24(sp)
    li  a2,12
    sub  a0,a4,a5
    la  a1,intbuf
    call  itos
    addi  a1,a0,-1
    la   a0,intbuf
    call  printstr
    li  a0,10
    call  printchar
    la  a0,instrstr
    li  a1,18
    call  printstr
    lw  a4,4(sp)
    lw  a5,28(sp)
    li  a2,12
    sub  a0,a4,a5
    la  a1,intbuf
    call  itos
    addi  a1,a0,-1
    la   a0,intbuf
    call  printstr
    li  a0,10
    call  printchar
    li  a1,17
    la  a0,hamstr
    call  printstr
    lw  a0,20(sp)
    call  printint
    li  a0,10
    call  printchar
    li  a1,17
    la  a0,hamstr
    call  printstr
    lw  a0,16(sp)
    call  printint
    li  a0,10
    call  printchar
    li  a1,17
    la  a0,hamstr
    call  printstr
    lw  a0,12(sp)
    call  printint
    li  a0,10
    call  printchar
    li  a0,0
    lw  ra,44(sp)
    lw  s0,40(sp)
    add  sp,sp,48
    ret
    