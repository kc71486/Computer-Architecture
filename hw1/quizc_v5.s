.data
    resstr:  .string  "first result:\n"
    .align 4
    aarr:    .word    0x3f63d70a, 0x3e3851ec, 0x3d23d70a, 0x3d8f5c29, 0x3f800000, 0x3e4ccccd, 0x3e051eb8, 0x00000000, 0x3f333333
    amat:    .word    3, 3, aarr
    barr:    .word    0x3ca3d70a, 0x3f8147ae, 0x3e0f5c29, 0x3dcccccd, 0x3e0f5c29, 0x3f7d70a4, 0x3f5eb852, 0x3e4ccccd, 0x3db851ec
    bmat:    .word    3, 3, barr
    heap_top:     .word     0x11000000
.bss
    retdata: .word    0, 0, 0, 0, 0, 0, 0, 0, 0
    retmat:  .word    0, 0, 0  # matf32_t
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
    jr       ra
mmul:
    li       t0,  0            # r = #t0
    slli     a0,  a0,  1
    andi     t1,  a1,  1
    beq      t1,  x0,  +8      # skip add if (b & 1) == 0
    add      t0,  t0,  a0
    srli     a1,  a1,  1
    srli     t0,  t0,  1
    bne      a1,  x0,  -20     # loop back if b != 0
    mv       a0,  t0
    jr       ra
fmul32:
    addi     sp,  sp,  -120    # allocate stack
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
    sw       s11, 48(sp)
    li       s0,  0x7fffff     # #s0 = 0x7fffff
    li       s1,  0x800000     # #s1 = 0x800000
    li       s2,  0xff         # #s2 = 0xff
    xor      t0,  a0,  a1
    srli     t0,  t0,  31
    sw       t0,  52(sp)       # sr = (sp + 52)
    and      t0,  a0,  s0
    or       t0,  t0,  s1
    sw       t0,  56(sp)       # ma = (sp + 56)
    and      t0,  a1,  s0
    or       t0,  t0,  s1
    sw       t0,  60(sp)       # mb = (sp + 60)
    sw       x0,  64(sp)       # mr = (sp + 64)
    srai     t0,  a0,  23
    and      t0,  t0,  s2
    sw       t0,  68(sp)       # ea = (sp + 68)
    srai     t0,  a1,  23
    and      t0,  t0,  s2
    sw       t0,  72(sp)       # eb = (sp + 72)
    sw       x0,  76(sp)       # er = (sp + 76)
    # special values
    lw       t0,  68(sp)
    bne      t0,  s2,  mulsan  # skip if ea != 0xff
    lw       t0,  56(sp)
    lw       t1,  72(sp)
    bne      t0,  s1,  mulsaan
    beq      t1,  x0,  mulsaan # skip if ma != 0x800000 || eb == 0
    lw       t0,  52(sp)
    li       a0,  0x7f800000
    slli     t0,  t0,  31
    or       a0,  a0,  t0      # return 0x7f800000 | sr << 31
    j        fmul32ret
    mulsaan:
    li       a0,  0x7f800001   # return 0x7f800001
    j        fmul32ret
    mulsan:
    lw       t0,  72(sp)
    bne      t0,  s2,  mulsbn  # skip if eb != 0xff
    lw       t0,  60(sp)
    lw       t1,  68(sp)
    bne      t0,  s1,  mulsbbn
    beq      t1,  x0,  mulsbbn # skip if mb != 0x800000 || ea == 0
    lw       t0,  52(sp)
    li       a0,  0x7f800000
    slli     t0,  t0,  31
    or       a0,  a0,  t0      # return 0x7f800000 | sr << 31
    mulsbbn:
    li       a0,  0x7f800001   # return 0x7f800001
    j        fmul32ret
    mulsbn:
    lw       t0,  68(sp)
    lw       t1,  72(sp)
    bne      t0,  x0,  mulsz1n # skip if ea != 0
    lw       a0,  52(sp)
    slli     a0,  a0,  31      # return sr << 31;
    j        fmul32ret
    mulsz1n:
    bne      t1,  x0,  mulsz2n # skip if eb != 0
    lw       a0,  52(sp)
    slli     a0,  a0,  31      # return sr << 31;
    j        fmul32ret
    mulsz2n:
    # multiplication
    lw       a0,  56(sp)
    lw       a1,  60(sp)
    call     mmul              # mrtmp = #a0 = mmul(ma, mb)
    lw       t0,  68(sp)
    lw       t1,  72(sp)
    add      t0,  t0,  t1
    addi     t4,  t0,  -127    # ertmp = #t4 = ea + eb - 127
    # realign mantissa
    srli     t5,  a0,  24
    andi     t5,  t5,  1       # mshift = #t5 = (mrtmp >>> 24) & 1
    srl      t0,  a0,  t5
    sw       t0,  64(sp)       # mr = mrtmp >> mshift
    add      t0,  t4,  t5
    sw       t0,  76(sp)       # er = ertmp + mshift
    # overflow and underflow
    bgt      t0,  x0,  mulun   # skip if er > 0
    lw       a0,  52(sp)
    slli     a0,  a0,  31      # return sr << 31
    j        fmul32ret
    mulun:
    blt      t0,  s2,  mulon   # skip if er < 0xff
    lw       t0,  52(sp)
    li       a0,  0x7f800000
    slli     t0,  t0,  31
    or       a0,  a0,  t0      # return 0x7f800000 | sr << 31
    j        fmul32ret
    mulon:
    lw       t0,  52(sp)
    lw       t1,  76(sp)
    lw       t2,  64(sp)
    slli     t0,  t0,  31
    and      t1,  t1,  s2
    slli     t1,  t1,  23
    and      t2,  t2,  s0
    or       a0,  t0,  t1
    or       a0,  a0,  t2      # return (sr << 31) | ((er & 0xff) << 23) | (mr & 0x7fffff)
    fmul32ret:
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
    addi     sp,  sp,  120     # free stack
    jr       ra
fadd32:
    addi     sp,  sp,  -120    # allocate stack
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
    sw       s11, 48(sp)
    li       s0,  0x7fffff     # #s0 = 0x7fffff
    li       s1,  0x800000     # #s1 = 0x800000
    li       s2,  0xff         # #s2 = 0xff
    srai     t0,  a0,  31
    sw       t0,  52(sp)       # sa = (sp + 52)
    srai     t0,  a1,  31
    sw       t0,  56(sp)       # sb = (sp + 56)
    sw       x0,  60(sp)       # sr = (sp + 60)
                               # skip (sp+64)
    and      t0,  a0,  s0
    or       t0,  t0,  s1
    sw       t0,  68(sp)       # ma = (sp + 68)
    and      t0,  a1,  s0
    or       t0,  t0,  s1
    sw       t0,  72(sp)       # mb = (sp + 72)
    sw       x0,  76(sp)       # mr = (sp + 76)
    srai     t0,  a0,  23
    and      t0,  t0,  s2
    sw       t0,  80(sp)       # ea = (sp + 80)
    srai     t0,  a1,  23
    and      t0,  t0,  s2
    sw       t0,  84(sp)       # eb = (sp + 84)
    sw       x0,  88(sp)       # er = (sp + 88)
    sw       x0,  92(sp)       # madd = (sp + 92)
    # special values
    lw       t0,  80(sp)
    bne      t0,  s2,  addsean # skip if ea != 0xff
    lw       t0,  68(sp)
    bne      t0,  s1,  addsman # skip if ma != 0x800000
    li       t2,  0x80000000
    xor      t0,  a0,  a1
    beq      t0,  t2,  addsman # skip if  (ia ^ ib) == 0x80000000
    lw       t0,  56(sp)
    li       t1,  0x7f800000
    slli     t0,  t0,  31
    or       a0,  t0,  t1      # return 0x7f800000 | sb << 31
    j        fadd32ret
    addsman:
    li       a0,  0x7f800001   # return 0x7f800001
    j        fadd32ret
    addsean:
    lw       t0,  84(sp)
    bne      t0,  s2,  addsebn # skip if eb != 0xff
    lw       t0,  72(sp)
    bne      t0,  s1,  addsmbn # skip if mb != 0x800000
    li       t2,  0x80000000
    xor      t0,  a0,  a1
    beq      t0,  t2,  addsmbn # skip if  (ia ^ ib) == 0x80000000
    lw       t0,  52(sp)
    li       t1,  0x7f800000
    slli     t0,  t0,  31
    or       a0,  t0,  t1      # return 0x7f800000 | sa << 31
    j        fadd32ret
    addsmbn:
    li       a0,  0x7f800001   # return 0x7f800001
    j        fadd32ret
    addsebn:
    # exponent align
    lw       t0,  80(sp)
    lw       t1,  84(sp)
    blt      t0,  t1,  addeltn # goto else if ea < eb
    sub      t2,  t0,  t1      # eab = ea - eb
    li       t3,  24
    bgt      t2,  t3,  addearn # goto else if eab > 24
    lw       t0,  72(sp)
    srl      t0,  t0,  t2
    sw       t0,  72(sp)       # mb = mb >>> eab
    j        addeare
    addearn:
    sw       x0,  72(sp)       # mb = 0
    addeare:
    lw       t0,  80(sp)
    sw       t0,  88(sp)       # er = ea
    j        addelte
    addeltn:
    sub      t2,  t1,  t0      # eab = eb - ea
    li       t3,  24
    bgt      t2,  t3,  addebrn # goto else if eab > 24
    lw       t0,  68(sp)
    srl      t0,  t0,  t2
    sw       t0,  68(sp)       # ma = ma >>> eab
    j        addebre
    addebrn:
    sw       x0,  68(sp)       # ma = 0
    addebre:
    lw       t0,  84(sp)
    sw       t0,  88(sp)       # er = eb
    addelte:
    # addition or substraction
    lw       t0,  52(sp)
    lw       t1,  56(sp)
    sw       t0,  60(sp)       # sr = sa
    xor      t0,  t0,  t1
    bne      t0,  x0,  addaxn  # skip if (sa ^ sb) != 0
    lw       t0,  68(sp)
    lw       t1,  72(sp)
    add      t0,  t0,  t1
    sw       t0,  92(sp)       # madd = ma + mb
    j        addaxe
    addaxn:
    lw       t0,  68(sp)
    lw       t1,  72(sp)
    sub      t0,  t0,  t1
    sw       t0,  92(sp)       # madd = ma - mb
    bge      t0,  x0,  addaxe  # skip if madd >= 0
    lw       t1,  60(sp)
    sub      t0,  x0,  t0
    xori     t1,  t1,  1
    sw       t1,  60(sp)       # sr ^= 1
    sw       t0,  92(sp)       # madd = 0 - madd
    addaxe:
    # realign mantissa
    mv       a0,  t0
    call     highestbit        # digits = #a0 = highestbit(madd)
    li       t1,  25
    lw       t0,  92(sp)
    bne      a0,  t1,  addrn   # skip if digits != 25
    addi     t0,  t0,  1
    srli     t0,  t0,  1
    sw       t0,  76(sp)       # mr = (madd + 1) >>> 1
    j        addre
    addrn:
    li       t1,  24
    sub      t1,  t1,  a0
    sll      t0,  t0,  t1
    sw       t0,  76(sp)       # madd << (24 - digits)
    addre:
    lw       t0,  88(sp)
    addi     t0,  t0,  -24
    add      t0,  t0,  a0
    sw       t0,  88(sp)
    # overflow and underflow
    lw       t2,  60(sp)
    slli     t2,  t2,  31
    bge      t0,  x0,  addo0n  # skip if er >= 0
    mv       a0,  t2
    j        fadd32ret
    addo0n:
    blt      t0,  s2,  addofn  # skip if er < 0xff
    li       t0,  0x7f800000
    or       a0,  t0,  t2      # return 0x7f800000 | sr << 31
    j        fadd32ret
    addofn:
    # result
    lw       t3,  88(sp)
    lw       t4,  76(sp)
    and      t3,  t3,  s2
    slli     t3,  t3,  23
    and      t4,  t4,  s0
    or       a0,  t2,  t3
    or       a0,  a0,  t4      # return (sr << 31) | ((er & 0xff) << 23) | (mr & 0x7fffff)
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
    lw       s10, 44(sp)
    lw       s11, 48(sp)
    addi     sp,  sp,  120     # free stack
    jr       ra
new_arr:
imul32:
    li       t0,  0
    imulls:
    beqz     a1,  imulle
    andi     t1,  a1,  1
    beqz     t1,  +8
    add      t0,  t0,  a0
    slli     a0,  a0,  1
    srai     a1,  a1,  1
    j        imulls
    imulle:
    mv       a0,  t0
    ret
matmul:
    addi     sp,  sp,  -132    # allocate stack
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
    sw       s11, 48(sp)
    sw       a0,  52(sp)       # first = (sp + 52)
    sw       a1,  56(sp)       # second = (sp + 56)
    lw       t0,  52(sp)
    lw       t1,  0(t0)
    sw       t1,  60(sp)       # m = (sp + 60)
    lw       t0,  52(sp)
    lw       t1,  4(t0)
    sw       t1,  64(sp)       # n = (sp + 64)
    lw       t0,  56(sp)
    lw       t1,  4(t0)
    sw       t1,  68(sp)       # o = (sp + 68)
    lw       t0,  64(sp)
    lw       t2,  56(sp)
    lw       t1,  0(t2)
    beq      t0,  t1,  dimok   # skip if n == second->row
    li       a0,  0            # return NULL
    j        matmulret
    dimok:
    la       t5,  heap_top
    lw       t4,  0(t5)
    mv       t3,  t4
    addi     t4,  t4,  12
    sw       t4,  0(t5)
    sw       t3,  72(sp)       # ret = heap_top = (temp #t3) = (sp + 72)
    lw       t1,  60(sp)
    sw       t1,  0(t3)        # ret->row = m
    lw       t1,  68(sp)
    sw       t1,  4(t3)        # ret->col = o
    la       t1,  retdata
    sw       t1,  8(t3)        # ret->data = retdata
    lw       t0,  52(sp)
    lw       t1,  8(t0)
    sw       t1,  76(sp)       # a = first->data = (sp + 76)
    lw       t0,  56(sp)
    lw       t1,  8(t0)
    sw       t1,  80(sp)       # b = second->data = (sp + 80)
    lw       t0,  72(sp)
    lw       t1,  8(t0)
    sw       t1,  84(sp)       # c = ret->data = (sp + 84)
    sw       x0,  88(sp)       # subtotal = (sp + 88)
    sw       x0,  92(sp)       # arow = (sp + 92)
    sw       x0,  96(sp)       # aidx = (sp + 96)
    sw       x0,  100(sp)      # bidx = (sp + 100)
    lw       t1,  84(sp)
    sw       t1,  104(sp)      # cptr = c = (sp + 104)
    sw       x0,  108(sp)      # i = (sp + 108)
    sw       x0,  112(sp)      # j = (sp + 112)
    sw       x0,  116(sp)      # k = (sp + 116)
    matmis:
    lw       t0,  108(sp)
    lw       t1,  60(sp)
    bge      t0,  t1,  matmie  # end if i >= m
    sw       x0,  112(sp)      # j = 0
    matmjs:
    lw       t0,  112(sp)
    lw       t1,  68(sp)
    bge      t0,  t1,  matmje  # end if j >= o
    sw       x0,  88(sp)       # subtotal = 0
    lw       t0,  92(sp)
    sw       t0,  96(sp)       # aidx = arow
    lw       t0,  112(sp)
    sw       t0,  100(sp)      # bidx = j
    sw       x0,  116(sp)      # k = 0
    matmks:
    lw       t0,  116(sp)
    lw       t1,  64(sp)
    bge      t0,  t1,  matmke  # end if k >= n
    lw       t0,  96(sp)
    lw       t1,  76(sp)
    slli     t0,  t0, 2
    add      t0,  t0, t1
    lw       a0,  0(t0)        # get a[aidx]
    lw       t0,  100(sp)
    lw       t1,  80(sp)
    slli     t0,  t0, 2
    add      t0,  t0, t1
    lw       a1,  0(t0)        # get b[bidx]
    call     fmul32            # a0 = fmul32(a[aidx], b[bidx])
    lw       a1,  88(sp)
    call     fadd32            # a0 = fadd32(a0, subtotal)
    sw       a0,  88(sp)
    lw       t0,  96(sp)
    addi     t0,  t0,  1
    sw       t0,  96(sp)       # aidx += 1
    lw       t0,  100(sp)
    lw       t1,  68(sp)
    add      t0,  t0,  t1
    sw       t0,  100(sp)      # bidx += o
    lw       t0,  116(sp)
    addi     t0,  t0,  1
    sw       t0,  116(sp)      # k += 1
    j        matmks
    matmke:
    lw       t0,  88(sp)
    lw       t1,  104(sp)
    sw       t0,  0(t1)        # *(cptr) = subtotal
    lw       t1,  104(sp)
    addi     t1,  t1,  4
    sw       t1,  104(sp)      # cptr += 1
    lw       t0,  112(sp)
    addi     t0,  t0,  1
    sw       t0,  112(sp)      # j += 1
    j        matmjs
    matmje:
    lw       t0,  92(sp)
    lw       t1,  64(sp)
    add      t0,  t0,  t1
    sw       t0,  92(sp)       # arow += n;
    lw       t0,  108(sp)
    addi     t0,  t0,  1
    sw       t0,  108(sp)      # i += 1
    j        matmis
    matmie:
    lw       a0,  72(sp)
    matmulret:
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
    addi     sp,  sp,  132     # free stack
    jr       ra
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
    jr       ra
main:
    addi     sp,  sp,  -1000   # allocate stack
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
    sw       s11, 48(sp)
    la       a0,  resstr
    addi     a7,  x0,  4       # print "first result:\n"
    ecall
    la       a0,  amat
    la       a1,  bmat
    call     matmul            # a0 = matmul(amat, bmat)
    mv       s2,  a0           # s2 = a0
    mv       a0,  s2
    call     printmatrix
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
    addi     sp,  sp,  1000   # free stack
	li       a7,  10           # return 0
	ecall