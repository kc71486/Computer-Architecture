.set SYSWRITE, 64
.set STDOUT, 1
.set INTBUFSIZE, 11

.extern itos

.global printstr
.global printchar
.global printint

.bss
    pch:  .byte 0, 0
    pint: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.align 2

# void printstr(const char *, uint32_t);
printstr:
    mv a2, a1           # length of input string
    mv a1, a0           # input string
    li a0, STDOUT       # write to stdout
    li a7, SYSWRITE     # "write" syscall
    ecall               # invoke syscall to print the string
    ret

# void printchar(char);
printchar:
    la a1, pch          # fake string
    sw a0, 0(a1)        # put char into fake string
    li a0, STDOUT       # write to stdout
    la a2, 1            # length = 2
    li a7, SYSWRITE
    ecall               # invoke syscall
    ret

# void printint(int32_t);
printint:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s1, 4(sp)
    la s1, pint
    mv a1, s1           # fake string
    li a2, INTBUFSIZE
    call  itos          # convert to string
    addi a2, a0, -1     # get (return value - 1) as size
    mv a1, s1           # same fake string
    li a0, STDOUT       # write to stdout
    li a7, SYSWRITE
    ecall               # invoke syscall
    lw ra, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 8
    ret
