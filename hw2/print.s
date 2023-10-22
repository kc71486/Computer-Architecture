.set SYSWRITE, 64
.set STDOUT, 1

.global printstr
.global printchar

.bss
    pch: .byte 0, 0

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
    li a7, SYSWRITE     # "write" syscall
    ecall               # invoke syscall
    ret
