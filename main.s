    .data
n_dict:
	.word 0
dict:
    .space  800
buffer_1:
	.space	4096
buffer_0:
	.space	4096
output_buffer:
	.word	buffer_1
input_buffer:
	.word	buffer_0
errMsg:
	.asciz "error\n"

    .text
    .globl main
main:
    addi sp, sp, -16
    sw s0, 0(sp)    #s0
    sw s1, 4(sp)    #
    sw s2, 8(sp)
    sw s3, 12(sp)
    mv s0, a1   #s0 <- argv
    lw a0, 0(s0)    #a0 <- file name
    call get_file_size
    mv s2, a0   #s2 <- file size
    call sbrk
    mv s3, a0   #s3 <- heap address
    lw a0, 0(s0)    #a0 <- file name
    call open   #return a0 file descriptor or -1 error
    li a1, -1
    beq a0, a1, error
    mv a1, s3   #a1 <- address of buf
    mv a2, s2   #a2 <- max length to read
    call read   #return a0 length read or -1 error
    li a1, -1
    beq a0, a1, error
    mv a0, s3   #a0 <- heap address
    mv a1, s2   #a1 <- file size
    call read_file_buf
    j .main_done
error:
	# Write (64) the error message to stdout (1)
	li a0, 1
	la a1, errMsg
    li a2, 39
 	li a7, 64
	ecall   
.main_done:
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    addi sp, sp, 16

	# Exit (93) with error code 0
	li a0,0 
	li a7, 93
	ecall

    .globl get_file_size
get_file_size:
    addi sp, sp, -12
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw ra, 8(sp)
    li a1, 0    #flag
    call open
    li a1, -1   #output
    beq a0, a1, error   #return -1 when error occurs
    mv s0, a0   #s0 <- file discriptor
    li a1, 0    #offset 0
    li a2, 2    #the end of the file
    call lseek
    li a1, -1   #flag
    beq a0, a1, error   #return -1 when error occurs
    mv s1, a0   #s1 <- returned position file size
    mv a0, s0   #a0 <- file descriptor
    call close
    mv a0, s1   #a0 <- filesize
    lw ra, 8(sp)    #Restore the return address from the stack.
    lw s1, 4(sp)
    lw s0, 0(sp)
    addi sp, sp, 12
    ret

	.globl	read_file_buf
read_file_buf:
	addi	sp,sp,-16
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	sw	ra,12(sp)
	mv	s0,a0   #s0 <- heap address
	add	s1,a0,a1    #s1 <- the end address of the heap
	li	s2,10   #s2 <- 10 :"\n"
end_of_file:
	bgtu	s1,s0,check_newline #the end address > heap address jump to check
	sb	zero,0(s1)
	call	handle_line
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
check_newline:
	lbu	a5,0(s0)    #a5 <- the 1st element of input
	addi	s0,s0,1 #s0++
	bne	a5,s2,end_of_file  #the char != "\n"
	sb	zero,-1(s0)
	call	handle_line	
	mv	a0,s0
	j	end_of_file

	.globl	define_symbol
define_symbol:
	la	a3,n_dict   #a3 <- address of n_dict
	lw	a5,0(a3)    #a5 <- current entries
	li	a4,99   #a4 <- max_dict_entries
	bgt	a5,a4,define_symbol_done   #n_dict >= MAX_DICT_ENTRIES
	slli	a4,a5,3 #a4 <- a5*8 offset for new entries
	add	a4,a3,a4    #a4 <- a3 + a4 address for new entry
	addi	a5,a5,1 #+1 for entry
	sw	a0,4(a4)    #new entry <- a0
	sw	a1,8(a4)    #
	sw	a5,0(a3)
define_symbol_done:
	ret

    .globl handle_line
handle_line:
	mv	a5,a0   #a5 <- *line
	li	a4,0    #a4 = definition
	li	a2,58   #a2 <- ':'
	li	a6,32   #a6 <- ' '
for1:
	lbu	a3,0(a5)    #a3 <- char
	beqz	a3,if1 #char = null jump to if1
	bne	a3,a2,next  #char != ':' jump to next
	addi	a4,a5,1 #a4 <- next char address
	sb	zero,0(a5)  #':' = null
while1:
	lbu	a3,0(a4)    #a3 <- next char
	mv	a5,a4   #a5 <- next char
	addi a4,a4,1    #a4++
	beq	a3,a6,while1  #char == ' ' jump to while1
	mv	a1,a5   #value = p
	li	a4,1    #definition = 1
next:
	addi	a5,a5,1
	j	for1
if1:
	beqz	a4,if2  #definition != 0 jump to if2
	tail	define_symbol
if2:
	addi	sp,sp,-8
	sw	ra,4(sp)
	call	replace
	lw	ra,4(sp)
	addi	sp,sp,8
	tail	print_string


.globl	replace
replace:
	addi	sp,sp,-24
	sw	s0,16(sp)
	la	s0,output_buffer    #s0 = *out
	lw	a5,0(s0)
	sw	ra,20(sp)
	sw	s1,12(sp)
	sw	s2,8(sp)
	sw	s3,4(sp)
for2:
	lbu	a4,0(a0)    #a4 <- char
	sb	a4,0(a5)    #a5 <- char
	lbu	a4,0(a0)    #a0 <- char
	bnez	a4,add1 #*line != '\0' jump to add1
	la	s1,dict     #s1 <- dict
	li	s2,0    #s2 <- 0
	la	s3,n_dict   #s3 <-n_dict
for3:
	lw	a5,0(s3)
	lw	a0,0(s0)
	bgt	a5,s2,for3.1  #i > 0 jump to
	lw	ra,20(sp)
	lw	s0,16(sp)
	lw	s1,12(sp)
	lw	s2,8(sp)
	lw	s3,4(sp)
	addi	sp,sp,24    #end of stack frame
	jr	ra
add1:
	addi	a5,a5,1 #out++
	addi	a0,a0,1 #line++
	j	for2
for3.1:
	lw	a1,4(s0)
	lw	a3,4(s1)
	lw	a2,0(s1)
	sw	a0,4(s0)
	sw	a1,0(s0)
	addi	s2,s2,1 #i++
	call	replace_key
	addi	s1,s1,8
	j	for3

	.globl	replace_key
replace_key:
	li	a7,32   #a7 <-' '
for4:
	mv	a6,a2   #a6 <- the base address key
	mv	a5,a0   #a5 <- the base address of p
while_rek:
	lbu	t1,0(a5)
	lbu	a4,0(a6)
	andi	t3,t1,223
	beq	t3,zero,end_search
	bne	a4,zero,if1_rek
source_null:
	bgeu	a0,a5,skip
	mv	a4,a3
	j	after_rep1
if1_rek:
	bne	t1,a4,not_match   #*p != *k jump to
	addi	a5,a5,1
	addi	a6,a6,1
	j	while_rek
after_rep2:
	addi	a1,a1,1
	addi	a5,a5,1
	sb	a4,-1(a1)
copy:
	lbu	a4,0(a5)
	andi	a0,a4,223
	bne	a0,zero,after_rep2
skip:
	mv	a0,a5
append_space:
	lbu	a5,0(a0)
	bne	a5,a7,append_end
	addi	a1,a1,1
	addi	a0,a0,1
	sb	a7,-1(a1)
	j	append_space
add_rep:
	addi	a1,a1,1
	addi	a4,a4,1
	sb	a0,-1(a1)
after_rep1:
	lbu	a0,0(a4)
	bne	a0,zero,add_rep
	j	skip
append_end:
	bne	a5,zero,for4
	sb	zero,0(a1)
	ret
end_search:
	beq	a4,zero,source_null
not_match:
	mv	a5,a0
	j	copy