.data
    resstr:  .string  "first result:\n"
    .align 4
    aarr:    .word    0x3f63d70a, 0x3e3851ec, 0x3d23d70a, 0x3d8f5c29, 0x3f800000, 0x3e4ccccd, 0x3e051eb8, 0x00000000, 0x3f333333
    amat:    .word    3, 3, aarr
    barr:    .word    0x3ca3d70a, 0x3f8147ae, 0x3e0f5c29, 0x3dcccccd, 0x3e0f5c29, 0x3f7d70a4, 0x3f5eb852, 0x3e4ccccd, 0x3db851ec
    bmat:    .word    3, 3, barr
    heap_top:     .word     0x11000000
.bss
    heapbuf1:.dword   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    heapbuf2:.dword   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    heapbuf3:.dword   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    heapbuf4:.dword   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.text
start:
    j        main              # start from main
highestbit:
    srli     t0,  a0,  1
    or       a0,  a0,  t0      # x |= (x >>> 1)
    srli     t0,  a0,  2
    or       a0,  a0,  t0      # x |= (x >>> 2)
    srli     t0,  a0,  4
    or       a0,  a0,  t0      # x |= (x >>> 4)
    srli     t0,  a0,  8
    or       a0,  a0,  t0      # x |= (x >>> 8)
    srli     t0,  a0,  16
    or       a0,  a0,  t0      # x |= (x >>> 16)
    srli     t0,  a0,  1
    li       t1,  0x55555555
    and      t1,  t0,  t1
    sub      a0,  a0,  t1      # x -= ((x >> 1) & 0x55555555)
    srli     t0,  a0,  2
    li       t1,  0x33333333
    and      t2,  t0,  t1
    and      t3,  a0,  t1
    add      a0,  t2,  t3      # x = ((x >> 2) & 0x33333333) + (x & 0x33333333)
    srli     t0,  a0,  4
    add      t0,  t0,  a0
    li       t1,  0x0f0f0f0f
    and      a0,  t0,  t1      # x = ((x >> 4) + x) & 0x0f0f0f0f
    srli     t0,  a0,  8
    add      a0,  a0,  t0      # x += (x >> 8);
    srli     t0,  a0,  16
    add      a0,  a0,  t0      # x += (x >> 16);
    andi     a0,  a0,  0x7f    # return (x & 0x7f)
    ret
mmul:
    li       t0,  0            # r = #t0
    slli     a0,  a0,  1
    mmulls:
    andi     t1,  a1,  1
    beq      t1,  x0,  +8      # skip add if (b & 1) == 0
    add      t0,  t0,  a0
    srli     t0,  t0,  1
    andi     t1,  a1,  2
    beq      t1,  x0,  +8      # skip add if (b & 1) == 0
    add      t0,  t0,  a0
    srli     t0,  t0,  1
    andi     t1,  a1,  4
    beq      t1,  x0,  +8      # skip add if (b & 1) == 0
    add      t0,  t0,  a0
    srli     t0,  t0,  1
    andi     t1,  a1,  8
    beq      t1,  x0,  +8      # skip add if (b & 1) == 0
    add      t0,  t0,  a0
    srli     a1,  a1,  4
    srli     t0,  t0,  1
    bne      a1,  x0,  mmulls  # loop back if b != 0
    mv       a0,  t0
    ret
fmul32:
    addi     sp,  sp,  -32     # allocate stack (leave 1 word empty)
    sw       ra,  0(sp)        # save registers
    sw       s0,  4(sp)
    sw       s1,  8(sp)
    sw       s2,  12(sp)
    sw       s3,  16(sp)
    sw       s4,  20(sp)
    sw       s5,  24(sp)
    li       s0,  0x7fffff     # 0x7fffff = #s0
    li       s1,  0x800000     # 0x800000 = #s1
    li       s2,  0xff         # 0xff = #s2
    xor      s3,  a0,  a1
    srli     s3,  s3,  31
    slli     s3,  s3,  31      # sr = #s3
    and      t4,  a0,  s0
    or       t4,  t4,  s1      # ma = #t4
    and      t5,  a1,  s0
    or       t5,  t5,  s1      # mb = #t5
    srai     s4,  a0,  23
    and      s4,  s4,  s2      # ea = #s4
    srai     s5,  a1,  23
    and      s5,  s5,  s2      # eb = #s5
    # special values
    bne      s4,  s2,  mulsan  # skip if ea != 0xff
    beq      t4,  s1,  mulsam  # skip if mar == 0x800000
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    mulsam:
    bne      s5,  s2,  mulsaf  # skip if eb != 0xff
    beq      t5,  s1,  mulsaf  # skip if mb == 0x800000
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    mulsaf:
    bnez     s5,  mulsa0       # skip if eb != 0
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    mulsa0:
    li       a0,  0x7f800001
    or       a0,  a0,  s3      # return 0x7f800000 | sr
    j        fadd32ret
    mulsan:
    bne      s5,  s2,  mulsbn  # skip if eb != 0xff
    beq      t5,  s1,  mulsbm  # skip if mb == 0x800000
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    mulsbm:
    bne      s4,  x0,  mulsb0  # skip if ea != 0
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    mulsb0:
    li       a0,  0x7f800001
    or       a0,  a0,  s3      # return 0x7f800000 | sr
    j        fadd32ret
    mulsbn:
    bne      s4,  x0,  mulsz1n # skip if ea != 0
    mv       a0,  s3           # return sr
    j        fmul32ret
    mulsz1n:
    bne      s5,  x0,  mulsz2n # skip if eb != 0
    mv       a0,  s3           # return sr
    j        fmul32ret
    mulsz2n:
    # multiplication and realign mantissa
    mv       a0,  t4
    mv       a1,  t5
    call     mmul              # mrtmp = mmul(ma, mb) = #a0
    srli     t3,  a0,  24
    andi     t3,  t3,  1       # mshift = (mrtmp >>> 24) & 1 = #t3
    srl      t4,  a0,  t3      # mr = mrtmp >> mshift = #t4
    add      s4,  s4,  s5
    addi     s4,  s4,  -127
    add      s4,  s4,  t3      # er = ea + eb - 127 + mshift = #s4
    # overflow and underflow
    bgt      s4,  x0,  mulun   # skip if er > 0
    mv       a0,  s3           # return sr << 31
    j        fmul32ret
    mulun:
    blt      s4,  s2,  mulon   # skip if er < 0xff
    li       a0,  0x7f800000
    or       a0,  a0,  s3      # return 0x7f800000 | sr
    j        fmul32ret
    mulon:
    and      s4,  s4,  s2
    slli     s4,  s4,  23
    and      t4,  t4,  s0
    or       a0,  s3,  s4
    or       a0,  a0,  t4      # return sr | ((er & 0xff) << 23) | (mr & 0x7fffff)
    fmul32ret:
    lw       ra,  0(sp)        # restore registers
    lw       s0,  4(sp)
    lw       s1,  8(sp)
    lw       s2,  12(sp)
    lw       s3,  16(sp)
    lw       s4,  20(sp)
    lw       s5,  24(sp)
    addi     sp,  sp,  32      # free stack
    ret
fadd32:
    addi     sp,  sp,  -48     # allocate stack (leave 1 word empty)
    sw       ra,  0(sp)        # save registers
    sw       s0,  4(sp)
    sw       s1,  8(sp)
    sw       s2,  12(sp)
    sw       s3,  16(sp)
    sw       s4,  20(sp)
    sw       s5,  24(sp)
    sw       s6,  28(sp)
    sw       s7,  32(sp)
    sw       s8,  36(sp)
    sw       s9,  40(sp)
    li       s0,  0x7fffff     # 0x7fffff = #s0
    li       s1,  0x800000     # 0x800000 = #s1
    li       s2,  0xff         # 0xff = #s2
    srli     s3,  a0,  31
    slli     s3,  s3,  31      # sa = #s3
    srai     s4,  a1,  31
    slli     s4,  s4,  31      # sb = #s4
    mv       s5,  s3           # sr = #s5
    and      s6,  a0,  s0
    or       s6,  s6,  s1      # ma = #s6
    and      s7,  a1,  s0
    or       s7,  s7,  s1      # mb = #s7
    srli     s8,  a0,  23
    and      s8,  s8,  s2      # ea = #s8
    srli     s9,  a1,  23
    and      s9,  s9,  s2      # eb = #s9
    # special values
    bne      s8,  s2,  addsean # skip if ea != 0xff
    or       t0,  s6,  s7
    beq      s6,  s1,  addsman # skip if ma == 0x800000
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    addsman:
    bne      s9,  s2,  addseabn # skip if eb != 0xff
    beq      s7,  s1,  addsabmn # skip if mb == 0x800000
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    addsabmn:
    xor      t0,  a0,  a1
    beq      t0,  x0,  addseabn # skip if (ia ^ ib) == 0
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    addseabn:
    li       t0,  0x7f800000
    or       a0,  t0,  s3      # return 0x7f800000 | sb
    j        fadd32ret
    addsean:
    bne      s9,  s2,  addsebn # skip if eb != 0xff
    beq      s7,  s2,  addsmbn # skip if mb == 0x800000
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    addsmbn:
    li       t0,  0x7f800000
    or       a0,  t0,  s4      # return 0x7f800000 | sb
    j        fadd32ret
    addsebn:
    # exponent align
    blt      s8,  s9,  addeltn # goto else if ea < eb
    sub      t2,  s8,  s9      # eab = ea - eb
    li       t3,  24
    ble      t2,  t3,  addearn # skip return if eab <= 24
    j        fadd32ret         # return ia
    addearn:
    srl      s7,  s7,  t2      # mb = mb >>> eab
    mv       s8,  s8           # er = ea = #s8
    j        addelte
    addeltn:
    sub      t0,  s9,  s8      # eab = eb - ea
    li       t1,  24
    ble      t0,  t1,  addebrn # skip return if eab <= 24
    mv       a0,  a1
    j        fadd32ret         # return ib
    addebrn:
    srl      s6,  s6,  t0      # ma = ma >>> eab
    mv       s8,  s9           # er = eb = #s8
    addelte:
    # addition or substraction
    mv       s5,  s3           # sr = sa
    xor      t0,  s3,  s4
    bne      t0,  x0,  addaxn  # skip if (sa ^ sb) != 0
    add      t0,  s6,  s7
    mv       s6,  t0           # mr = ma + mb = #s6
    j        addaxe
    addaxn:
    sub      s6,  s6,  s7      # mr = ma - mb = #s6
    bge      s6,  x0,  addaxe  # skip if mr >= 0
    xori     s5,  s5,  1       # sr ^= 1
    sub      s6,  x0,  s6      # mr = 0 - mr
    addaxe:
    # realign mantissa
    mv       a0,  s6
    call     highestbit        # digits = highestbit(mr) = #a0
    li       t1,  25
    bne      a0,  t1,  addrn   # skip if digits != 25
    addi     s6,  s6,  1
    srli     s6,  s6,  1       # mr = (mr + 1) >>> 1
    j        addre
    addrn:
    li       t1,  24
    sub      t1,  t1,  a0
    sll      s6,  s6,  t1      # mr << (24 - digits)
    addre:
    addi     s8,  s8,  -24
    add      s8,  s8,  a0      # er = er - 24 + digits
    # overflow and underflow
    bge      s8,  x0,  addo0n  # skip if er >= 0
    mv       a0,  s5
    j        fadd32ret
    addo0n:
    blt      s8,  s2,  addofn  # skip if er < 0xff
    li       t0,  0x7f800000
    or       a0,  t0,  s5      # return 0x7f800000 | sr
    j        fadd32ret
    addofn:
    # result
    and      s8,  s8,  s2
    slli     s8,  s8,  23
    and      s6,  s6,  s0
    or       a0,  s5,  s8
    or       a0,  a0,  s6      # return sr | ((er & 0xff) << 23) | (mr & 0x7fffff)
    fadd32ret:
    lw       ra,  0(sp)        # restore registers
    lw       s0,  4(sp)
    lw       s1,  8(sp)
    lw       s2,  12(sp)
    lw       s3,  16(sp)
    lw       s4,  20(sp)
    lw       s5,  24(sp)
    lw       s6,  28(sp)
    lw       s7,  32(sp)
    lw       s8,  36(sp)
    lw       s9,  40(sp)
    addi     sp,  sp,  48      # free stack
    ret
matmul:
    addi     sp,  sp,  -68     # allocate stack
    sw       ra,  0(sp)        # save registers
    sw       s0,  4(sp)
    sw       s1,  8(sp)
    sw       s2,  12(sp)
    sw       s3,  16(sp)
    sw       s4,  20(sp)
    sw       s5,  24(sp)
    sw       s6,  28(sp)
    sw       s7,  32(sp)
    sw       s8,  36(sp)
    sw       s9,  40(sp)
    sw       s10, 44(sp)
    sw       s11, 52(sp)
    lw       s0,  0(a0)        # m = #s0
    lw       s1,  4(a0)        # n = #s1
    lw       t0,  0(a1)
    lw       s2,  4(a1)        # o = #s2
    beq      s1,  t0,  +12     # return null if dimension doesn't match
    li       a0,  0
    j        matmulret
    lw       s3,  8(a0)        # astart = #s3
    mv       s5,  s3           # aptr = #s5
    lw       s6,  8(a1)        # bptr = #s6
    mv       s8,  s6           # brow = #s8
    # inline new_mat start (a0) -> (t3)
    la       t5,  heap_top
    lw       t4,  0(t5)
    mv       t3,  t4
    addi     t4,  t4,  12
    sw       t4,  0(t5)
    # inline new_mat end
    sw       t3   56(sp)       # ret = heap_top = (temp #t3) = (sp+56)
    bgtz     s0,  +8           # not return if m > 0
    j        matmulret
    bgtz     s1,  +8           # not return if n > 0
    j        matmulret
    bgtz     s2,  +8           # not return if o > 0
    j        matmulret
    sw       s0,  0(t3)        # ret->row = m
    sw       s2,  4(t3)        # ret->col = o
    mv       a0,  s0
    mv       a1,  s2
    # inline imul32 start (a0, a1) -> (t0)
    li       t0,  0
    andi     t1,  a1,  1
    beqz     t1,  +8
    add      t0,  t0,  a0
    slli     a0,  a0,  1
    srai     a1,  a1,  1
    bnez     a1,  -20
    # inline imul32 end
    # inline new_arr start (t0) -> (t2)
    slli     t1,  t0,  2
    mv       t2,  t4
    add      t4,  t4,  t1
    sw       t4,  0(t5)
    # inline new_arr end
    sw       t2,  8(t3)        # ret->data = retdata = heap_top = (temp #t2)
    sw       t2,  60(sp)       # cstart = (sp+60)
    mv       s7,  t2           # cptr = #s7
    mv       s8,  s6           # brow = #s8
    li       s10, 0            # i = #s9,  j = #s10,  k = #s11
    slli     s0,  s0,  2       # m <<= 2
    slli     s1,  s1,  2       # n <<= 2
    slli     s2,  s2,  2       # o <<= 2
    matjs:
    add      s5,  s3,  s10     # aptr = astart + j
    lw       s7,  60(sp)       # cptr = cstart
    li       s9,  0            # i = 0
    matis:
    mv       s6,  s8           # bptr = brow
    lw       s4,  0(s5)        # aval = *aptr
    li       s11, 0            # k = 0
    matks:
    lw       a1,  0(s6)
    mv       a0,  s4
    call     fmul32
    lw       a1,  0(s7)
    call     fadd32
    sw       a0,  0(s7)        # *cptr = fadd32(fmul32(aval, *bptr), *cptr)
    addi     s6,  s6,  4       # bptr += 4
    addi     s7,  s7,  4       # cptr += 4
    addi     s11, s11, 4       # k += 4
    blt      s11, s2,  matks   # loop if k < o
    add      s5,  s5,  s2      # aptr += o
    addi     s9,  s9,  4       # i += 4
    blt      s9,  s0,  matis   # loop if i < m
    add      s8,  s8,  s2      # brow += o
    addi     s10, s10, 4       # j += 4
    blt      s10, s1,  matjs   # loop if j < n
    matmulret:
    lw       a0,  56(sp)       # return ret
    lw       ra,  0(sp)        # restore registers
    lw       s0,  4(sp)
    lw       s1,  8(sp)
    lw       s2,  12(sp)
    lw       s3,  16(sp)
    lw       s4,  20(sp)
    lw       s5,  24(sp)
    lw       s6,  28(sp)
    lw       s7,  32(sp)
    lw       s8,  36(sp)
    lw       s9,  40(sp)
    lw       s10, 44(sp)
    lw       s11, 48(sp)
    addi     sp,  sp,  68      # free stack
    ret
printmatrix:
    lw       t0,  0(a0)
    lw       t1,  4(a0)
    bne      t0,  x0,  +8
    jr       ra
    bne      t1,  x0,  +8
    jr       ra
    lw       t2,  8(a0)
    li       t3,  0
    li       t4,  0
    printis:
    li       t5,  0
    printjs:
    add      a1,  t2,  t4
    lw       a0,  0(a1)
    li       a7,  2
    ecall
    li       a0,  32
    li       a7,  11
    ecall
    addi     t5,  t5,  1
    addi     t4,  t4,  4
    blt      t5,  t1,  printjs
    li       a0,  10
    li       a7,  11
    ecall
    addi     t3,  t3,  1
    blt      t3,  t0,  printis
    ret
main:
    addi     sp,  sp,  -16     # allocate stack
    sw       ra,  0(sp)        # save registers
    sw       s0,  4(sp)
    sw       s1,  8(sp)
    sw       s2,  12(sp)
    la       a0,  resstr
    addi     a7,  x0,  4       # print "first result:\n"
    ecall
    la       a0,  amat
    la       a1,  bmat
    call     matmul            # a0 = matmul(amat, bmat)
    mv       s0,  a0           # s0 = a0
    ecall
    mv       a0,  s0
    call     printmatrix
    lw       ra,  0(sp)        # restore registers
    lw       s0,  4(sp)
    lw       s1,  8(sp)
    lw       s2,  12(sp)
    addi     sp,  sp,  16      # free stack
	li       a7,  10           # return 0
	ecall