.data
    resstr:  .string  "result=\n"
    aarr:    .word    0x3f63d70a, 0x3e3851ec, 0x3d23d70a, 0x3d8f5c29, 0x3f800000, 0x3e4ccccd, 0x3e051eb8, 0x00000000, 0x3f333333
    amat:    .word    3, 3, aarr
    retdata: .word    0,0,0,0,0,0,0,0,0
    retmat:  .word    0,0,0    # matf32_t
.text

start:
    j        main              # jump to main

get_highest_digit:

imul32:

imul32_low:

fmul32:

fadd32:

matmul:
    addi     sp,  sp,  -1000   # allocate stack
    sw       ra,  0(sp)        # save ra
    lw       ra,  0(sp)        # restore ra
    addi     sp,  sp,  -1000   # free stack
main:
    addi     sp,  sp,  -1000   # allocate stack
    sw       ra,  0(sp)        # save ra
    lw       a0,  resstr
    addi     a7,  x0,  4       # print "result=\n"
    ecall
    li       t0,  0            # t0 = i = 0
    li       t1,  9
    la       t2,  aarr         # t2 = aarr
    printl:
    lw       a0,  0(t2)
    addi     a7,  x0,  2       # print aarr[i]
	ecall
    li       a0,  10
    addi     a7,  x0,  11      # print '\n'
	ecall
    addi     t2,  t2,  4
    addi     t0,  t0,  1
    blt      t0,  t1,  printl  # loop while i < 9
    lw       ra,  0(sp)        # restore ra
    addi     sp,  sp,  -1000   # free stack
	addi     a7,  x0,  10      # return 0
	ecall