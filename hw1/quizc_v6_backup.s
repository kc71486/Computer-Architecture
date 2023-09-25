.rodata
.data
    resstr:  .string  "result=\n"
    .align 4
    aarr:    .word    0x3f63d70a, 0x3e3851ec, 0x3d23d70a, 0x3d8f5c29, 0x3f800000, 0x3e4ccccd, 0x3e051eb8, 0x00000000, 0x3f333333
    amat:    .word    3, 3, aarr
    barr:    .word    0x3ca3d70a, 0x3f8147ae, 0x3e0f5c29, 0x3dcccccd, 0x3e0f5c29, 0x3f7d70a4, 0x3f5eb852, 0x3e4ccccd, 0x3db851ec
    bmat:    .word    3, 3, barr
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
    bne      s5,  x0,  mulsa0  # skip if eb != 0
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
    jr       ra
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
    bne      s9,  s2,  addsab  # skip if eb != 0xff
    beq      s7,  s1,  addsabm # skip if mb == 0x800000
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    addsabm:
    xor      t0,  a0,  a1
    beq      t0,  x0,  addsab  # skip if (ia ^ ib) == 0
    li       a0,  0x7f800001   # return nan
    j        fadd32ret
    addsab:
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
    jr       ra
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
    la       t0,  retmat
    sw       t0,  72(sp)       # ret = (sp + 72)
    lw       t1,  60(sp)
    sw       t1,  0(t0)        # ret->row = m
    lw       t1,  68(sp)
    sw       t1,  4(t0)        # ret->col = o
    la       t1,  retdata
    sw       t1,  8(t0)        # ret->data = retdata
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
main:
    addi     sp,  sp,  -4      # allocate stack
    sw       ra,  0(sp)        # save ra
    la       a0,  amat
    la       a1,  bmat
    call     matmul            # cmat = matmul(amat, bmat)
    lw       t0,  8(a0)        # c = cmat->data = #t0
    lw       a0,  resstr
    addi     a7,  x0,  4       # print "result=\n"
    ecall
    li       t1,  0            # i = #t1
    li       t2,  9            # 9 = #t2
    printl:
    lw       a0,  0(t0)
    addi     a7,  x0,  2       # print aarr[i]
	ecall
    li       a0,  10
    addi     a7,  x0,  11      # print '\n'
	ecall
    addi     t0,  t0,  4
    addi     t1,  t1,  1
    blt      t1,  t2,  printl  # loop while i < 9
    lw       ra,  0(sp)        # restore ra
    addi     sp,  sp,  4       # free stack
	li       a7,  10           # return 0
	ecall