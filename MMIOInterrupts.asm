.text

usefultask:
	# Program which can perform useful computations, whereas 
	# the exception handler takes care of input/output.
	# Unlike polling, with interrupts it is very easy to perform 
	# useful computations in addition to handling input/output and 
	# not waste computing time with unnecessary waiting.
	# This shall remain unchanged!
	b usefultask

# Bootup code
.ktext
# TODO Implement the system initialization here. What do you need to do for this?
	
## set interrupt bit keyboard
	lw $k0 0xffff0000	
	ori $k0 0x2		
	sw $k0 0xffff0000
		
## set interrupt bit display
	lw $k0 0xffff0008	
	andi $k0 0xfffffffe		
	sw $k0 0xffff0008

###################this parts are exactly like task1
li $t0 0xfffff13
mtc0 $t0, $12 

#The EPC register

#li $t0 0x00400000 # 0x00400000 - Text segment - program instructions
#mtc0 $t0 $14
##################end of edited bootup
la	$t0,	usefultask
mtc0	$t0,	$14


# TODO Jump to our useful task
eret


# Exception handler
# Here, you may use $k0 and $k1
# Other registers must be saved first
.ktext 0x80000180
	# Save all registers that we will use in the exception handler
	move $k1, $at
	sw $v0 exc_v0
	sw $a0 exc_a0
	sb $t8, buffer
	mfc0 $k0 $13		# Cause register

# The following case can serve you as an example for detecting a specific exception:
# test if our PC is mis-aligned; in this case the machine hangs
	bne $k0 0x18 okpc	# Bad PC exception
	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word aligned?
	beq $a0 0 okpc
fail:	j fail			# PC is not aligned -> processor hangs

# The PC is ok, test for further exceptions/interrupts
okpc:
	andi $a0 $k0 0x7c
	beq $a0 0 interrupt	# 0 means interrupt

# Exception code. For problem 2.3, it is not required to handle exceptions.
	j ret

# Interrupt-specific code
# TODO Implement handlers for keyboard and display interrupts here.

# You may outsource the actual functionality to functions (similar to problem 2.2).
interrupt:


	mfc0 $k0, $12
	ori $k0, $k0, 0x00000001 ###  enable interrupts for CoProc0
	mtc0 $k0, $12

	mfc0 $k0, $13
	andi $k0, $k0, 0x00000c00  ##10th BIT 	== keyboard. 
	
	beq $k0, 0x00000400, push
	
	beq $k0, 0x00000800, pop
	j ret
	
	
	

	
	
ret:
# Restore used registers
	lw $v0 exc_v0
	lw $a0 exc_a0
	move $at, $k1
# Return to the EPC
	eret

# Internal kernel data
	.kdata
exc_v0:	.word 0
exc_a0:	.word 0
buffer:  .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
# TODO Additional space for registers you want to save temporarily in the exception handler

# TODO Allocate your 16-byte buffer here

.ktext
########### $t9 : register for push	 $t0: register for pop
push:
	##la $t1, buffer
	lbu $k1, 0xffff0004
	addiu $t2, $zero, 15
	b push_loop
	
push_loop:
	lbu $t1, buffer($t2)
	subiu $t2, $t2, 1
	
	bne $t1, 0, push_loop
	beqz $t2, mark1 
	b overflow_init 
	b mark1
mark1:	
	sb $k1, buffer($t2)  ## writes $t0 to mem at address buffer+offset
	

	j interrupt
	
overflow_init:
	
	addiu $t2, $zero, 14
	addiu $t3, $zero, 15
	b overflow
overflow:	
	lb $t4, buffer($t2)
	sb $t4, buffer($t3)
	
	subiu $t2, $t2, 1
	subiu $t3, $t3, 1
	
	bne $t4, 0, overflow 
	sb $zero, buffer
	
	b mark1
	
	
	
	
pop:
	#la $t1, buffer
	#addiu $t1, $t1, 15
	##addu $t0, $t1, $zero  ## 
	lb   $k1, buffer+15  ## t0 = output register   will always output the 15th value
	
	addiu $t2, $zero, 14
	addiu $t3, $zero, 15
	b pop_shift
Mark2:	
	# TODO # print
	
	
	
	sw $k1, 0xffff000c

	j ret
	
pop_shift:
	
	lb $t4, buffer($t2)
	sb $t4, buffer($t3)
	
	subiu $t2, $t2, 1
	subiu $t3, $t3, 1
	
	bne $t4, 0, pop_shift 
	sb $zero, buffer
	b Mark2
	


