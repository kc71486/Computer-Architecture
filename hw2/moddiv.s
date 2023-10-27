.global udiv32
.global umod32

.text
.align 2
# copy from gcc
udiv32:
    mv    a2, a1
    mv    a1, a0
    li    a0, -1
    beqz  a2, 5f
    li    a3, 1
    bgeu  a2, a1, 2f
1:
    blez  a2, 2f
    slli  a2, a2, 1
    slli  a3, a3, 1
    bgtu  a1, a2, 1b
2:
    li    a0, 0
3:
    bltu  a1, a2, 4f
    sub   a1, a1, a2
    or    a0, a0, a3
4:
    srli  a3, a3, 1
    srli  a2, a2, 1
    bnez  a3, 3b
5:
    ret

# copy from gcc
umod32:
    mv  t0, ra
    jal  udiv32
    mv  a0, a1
    jr  t0
