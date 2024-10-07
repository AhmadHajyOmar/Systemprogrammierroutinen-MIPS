	.text
# user program
task:
	la      $a0, msg
	li	$v0, 4
	syscall
	li	$a0, 'D'
	li 	$v0, 11
loop:	syscall
	li	$a0, 'E'
	b	loop

# Data
	.data
msg: .asciiz "Hello World!"
#Kontrollport Bildschirm

# Bootup code

	.ktext
# TODO implement the bootup code
# The final exception return (eret) should jump to the beginning of the user program





#Status Register

li $k0 0x0000ff13
mtc0 $k0, $12 

#The EPC register

li $k0 0x00400000 # 0x00400000 - Text segment - program instructions
mtc0 $k0 $14 


eret

# Exception handler
# Here, you may use $k0 and $k1
# Other registers must be saved first
.ktext 0x80000180
	# Save all registers that we will use in the exception handler
	move $k1, $at
	sw $v0 exc_v0
	sw $a0 exc_a0
        sw $t8 exc_t8
        sw $t9 exc_t9
        sw $t5 exc_t5
        sw $t3 exc_t3
        sw $t4 exc_t4
     
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

# Exception code
# TODO Detect and implement system calls here.
# Remember that an adjustment of the epc may be necessary.
  
  beq $v0 11 PrintASCIIzeichen #Systemaufruf mit Nummer 11 ASCIIzeichen 'D'
  beq $v0 4  PrintHelloWorld   #Systemaufruf mit Nummer  4 "Hello World!"
  
  PrintASCIIzeichen:
   
   lbu  $k0, 0xffff0008 ## screen control port
   andi $k0, $k0, 0x01 ## extract reayd bit = LSB
   beq  $k0, 1, labelPrintASCIIzeichen

 
  
  j ret
  
  labelPrintASCIIzeichen:
  lw $t3 exc_a0
  sw $t3 0xffff000c #Data port
  b finish   #PC = finish
  
  PrintHelloWorld:
   lbu  $k0, 0xffff0008 ## screen control port
   andi $k0, $k0, 0x01 ## extract reayd bit = LSB
   lw   $t4 exc_a0 
   beq  $k0, 1, labelPrintHelloWorld
  
    j ret 
  
  labelPrintHelloWorld:
  li $t9 1
  lb $t5 ($t4)
  beqz $t5 finish
  sw $t5 0xffff000c #Data port
  addu $t4  $t4 $t9
  b labelPrintHelloWorld # PC = labelPrintHelloWorld
  # Add (if necessary) 4 to epc, here: to not repeat system call
 
  finish:
  li $t8 4
  mfc0 $k1 $14
  addu $k1 $k1 $t8
  mtc0 $k1 $14
  
  
  
  	
	
	
	j ret
	


# Interrupt-specific code (nothing to do here for this exercise)
interrupt:
	j ret
ret:
# Restore used registers
	lw $v0 exc_v0
	lw $a0 exc_a0
	lw $t8 exc_t8
        lw $t9 exc_t9
        lw $t5 exc_t5
        lw $t3 exc_t3
        lw $t4 exc_t4
   
	move $at, $k1
# Return to the EPC
	eret

# Internal kernel data
	.kdata
exc_v0:	.word 0
exc_a0:	.word 0
# TODO Additional space for registers you want to save temporarily in the exception handler
exc_t8: .word 0
exc_t9: .word 0
exc_t5: .word 0
exc_t3: .word 0
exc_t4: .word 0

