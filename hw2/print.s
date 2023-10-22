.set SYSWRITE, 64
.set STDOUT, 1

.global printstr

.text
.align 2

printstr:
    mv a2, a1           # length of input string
    mv a1, a0           # input string
    li a0, STDOUT       # write to stdout
    li a7, SYSWRITE     # "write" syscall
    ecall               # invoke syscall to print the string