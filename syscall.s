    .text
    .globl sbrk
sbrk:
    li a7, 9
    ecall
    ret

    .globl open
open:
    li a7, 1024
    li a1, 0    #flag: read only
    ecall
    ret

    .globl close
close:
    li a7, 57
    ecall
    ret

    .globl read
read:
    li a7, 63
    ecall
    ret

    .globl lseek
lseek:
    li a7, 62
    ecall
    ret

	.globl	print_string
print_string:
    li  a7, 4
    ecall
    li a0, 10
    li a7, 11
    ecall
    ret

    .globl print_int
print_int:
    li a7, 1
    ecall
    ret

    .globl print_char
print_char:
    li a7, 11
    ecall
    ret