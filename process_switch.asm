	.text
# User program 1: Output numbers
task1:	li	$a0, '0'
	li 	$v0, 11   
	li 	$t0, 10	    
loop1:	syscall 
	addiu   $a0, $a0, 1
	divu    $t1, $a0, ':'
	multu   $t1, $t0
	mflo    $t1
	subu    $a0, $a0, $t1 
	b	loop1 

# User program 2: Output B 
task2:	li	$a0, 'B'
	li	$v0, 11
loop2:  syscall
	b	loop2

# Bootup code
	.ktext
# TODO Implement the bootup code
# Initialize all required data structures
# The final exception return (eret) shall jump to the beginning of program 1
 
# Before the execution begin  we have the two processes in
# (Default) idle state as defined in the comment with value 0 
# we will execute first task1 ... so we change the state of the process1 to 1 
 
addi $k0 , $k0, 1              # add value 1 to $k0
sw  $k0 ,pcb_task1+4            # change the state of process1 to 1 which means it is in running state 
li  $k1 , 100                  # add 100 to $k1
mtc0  $k1, $11               # move immediate 100 to the compare register , since we have the execution time has limit of "100 Takte" . 
la    $t7 , task1            # save the address of the first programm in $t7
mtc0  $t7 , $14                # set epc at this address ( start of programm 1)

addi  $t1,$t1, -3                   # we start counting when programm 1 start 
mtc0  $t1 , $9                        # move value of counter to counter register
move $at , $zero                      # set the registers to default value zero
move $t1 , $zero                    
eret

# Exception handler
# Here, you may use $k0 and $k1
# Other registers must be saved first
.ktext 0x80000180
	# Save all registers that we will use in the exception handler
	move $k1, $at
	sw $v0 exc_v0
	sw $a0 exc_a0
        sw $t0 , savedRegisters 
        sw $t1 , savedRegisters+4 
        sw $t2 , savedRegisters+8
        sw $t3 , savedRegisters+12 
        sw $t4 , savedRegisters+16
       # sw $t5 , savedRegisters+20 
       # sw $t6 , savedRegisters+24
        sw $t7 , savedRegisters+20
       # sw $t8 , savedRegisters+32                                                    sw $t0 , savedRegisters 
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
# TODO Detect and implement system calls here. Here, you can reuse parts from problem 2.1

# Remember that an adjustment of the epc may be necessary.

move $t0 , $zero          # set t0 to zero   
mfc0 $t0 , $14                # get the current pc value from epc register

addu  $t0 , $t0  , 4          # add 4 to pc value
mtc0  $t0 , $14               # return the pc value to epc register 

mfc0  $t1, $13              # check for ExCode ( should 6-2 bits of cause register equal to 8 in decimal )
srl   $t1 ,$t1 , 2            # remove the first 2 bits , so we can apply AND operator with the new first 5 bits
li  $t2 ,0                         # make sure that $t2 is zero
li   $t2, 31               # since we want to check the first 5 bits , so we apply AND with the value "11111"
li  $t3 , 0                         # make sure that $t3 is zero
and  $t3 , $t2, $t1                 # apply AND between "11111" and "xxxx01000"
bne  $t3 , 8 ,ret  # result not equal to 8 , so we return the stored registers
         
# if the result is equal to 8 then we do another Check for the Syscall's function 
li $t4 , 0                          # to assure that $t4 is zero
lw $t4 , exc_v0                      # get the value of $v0
bne $t4 , 11 ,ret   # if $v0 not equal to 11 then return the Registers
 # else 
 
                     ################   NEW EDIT     ###############
 printAscii0 :
 lbu $k0 , 0xffff0008    # screen control port 
 andi $k0 , $k0 , 0x01      # get the ready bit 
 beq  $k0 , 0 ,ret 
  
  
pintAscii_string :           ##### AM NOT SURE HERE IN SECOND LINE ######
lw $a0 , exc_a0              # get the argument value 
sw $a0 , 0xffff000c             # communicate with the screen ??     //////////
 
j ret

# Interrupt-specific code

interrupt:
# TODO For timer interrupts, call timint

        lw $v0 exc_v0
	lw $a0 exc_a0
        lw $t0 , savedRegisters 
        lw $t1 , savedRegisters+4 
        lw $t2 , savedRegisters+8
        lw $t3 , savedRegisters+12 
        lw $t4 , savedRegisters+16
       # lw $t5 , savedRegisters+20 
       # lw $t6 , savedRegisters+24
        lw $t7 , savedRegisters+20   
       # lw $t8 , savedRegisters+32   
 # here we use only k0 and k1 
   mfc0  $k0 , $12            # get the content of status register 
   andi  $k0 , $k0 , 1       # check whether the first bit of status register by apply AND with immediate 1 
   bnez  $k0 , Continue1        # if the first is 1 then we get 1 otherwise we get 0 
   b     end                  # if we get zero 
   
   Continue1 :
   
   mfc0  $k0 , $12             # again get the value of status register
   andi  $k0, $k0 ,32768         # since we need to check if IM[7] which is the 16th bit is one and 32768 is equal to 1 000 000 000 000 000 in binary   
   bnez  $k0 , Continue2   # we check next : whether timer-interrupt is the cause
   b     end
   
   Continue2 :
   
   mfc0  $k0, $13               # get the content of cause register and store it $k0
   andi  $k0, $k0, 32768         # again we have to check if IM[7] which is the 16th bit is one 
   bne    $k0 , 32768 , end            # if IM[7] of the cause register is 1 then branch to timint 
   b      timint
   
   end : 
   
   move $at , $k1                # return value of $at , that we saved before 
   eret
   
   
  j ret
	
	
ret:

    
# Restore used registers        
	lw $v0 exc_v0
	lw $a0 exc_a0
	move $at, $k1
        lw $t0 , savedRegisters 
        lw $t1 , savedRegisters+4 
        lw $t2 , savedRegisters+8
        lw $t3 , savedRegisters+12 
        lw $t4 , savedRegisters+16
        #lw $t5 , savedRegisters+20 
       # lw $t6 , savedRegisters+24
        lw $t7 , savedRegisters+20
       # lw $t8 , savedRegisters+32   
# Return to the EPC
	eret

# Internal kernel data
	.kdata
exc_v0:	.word 0
exc_a0:	.word 0
# TODO Additional space for registers you want to save temporarily in the exception handler

savedRegisters :
 .word 0,0,0,0,0,0
	.ktext
# Helper functions
timint:
# TODO Process the timer interrupt here, and call this function from the exception handler

  lw $k0 , pcb_task1+4                 # get the 2 element of data structure pcb_task1 to know if the task1/task2 is running or not  
  beq $k0 , 0 , save_stateOfTask2      # state of the process of task1 == zero means that the process1 is not running     
   
   # else state of process1 is running :
   
  b  save_stateOfTask1 
  
  reverse_state :             
 
  lw $k0, pcb_task1+4          # get the current state of process 1
  beqz $k0 , changeBit               # convert the state to the other option ... if it is 1(running) will become 0(idle) and vice versa     
  li   $k0 , 0  
  sw  $k0 , pcb_task1+4          # save the value after converting
   
  lw $k0, pcb_task2+4          # get the current state of process 2
  beqz $k0 , changeBit               # convert the state to the other option ... if it is 1(running) will become 0(idle) and vice versa       
  li   $k0 , 0   
  sw  $k0 , pcb_task2+4          # save the value after converting
   
  lw $k0, pcb_task1+4         # after revers the state we have to check which program to excute next 
  beq $k0 , 0 , loadTask2       # branch to load task2 if state of progrm 1 is idle (0)
     
  # otherwise load task1 :
  
     loadTask1 :
     
        lw $k0, pcb_task1       # get the pc of task1
        mtc0  $k0, $14           # initialize the epc with value of pc 
        # load all used registers in task1 
        lw $a0 , pcb_task1+8
        lw $v0 , pcb_task1+12      
        lw $t0 , pcb_task1+16
        lw $t1 , pcb_task1+20
        lw $k0 , pcb_task1+24 
        mthi $k0 
        lw  $k0 , pcb_task1+28 
        mtlo  $k0 
        lw  $k1 , pcb_task1+32         # get $at register and store it is value at $k1  
        b   update_Counter 
                
                
                
         loadTask2 :
     
        lw $k0, pcb_task2       # get the pc of task2
        mtc0  $k0, $14           # initialize the epc with value of pc 
        # load all used registers in task1 
        lw $a0 , pcb_task2+8
        lw $v0 , pcb_task2+12      
      #  lw $t0 , pcb_task2+16
      #  lw $t1 , pcb_task2+20
        lw $k0 , pcb_task2+16 
        mthi $k0 
        lw  $k0 , pcb_task2+20 
        mtlo  $k0 
        lw  $k1 , pcb_task2+2       # get $at register and store it is value at $k1  
        
    update_Counter :
    
       addi $k0 ,$k0, -3              #  change value of counter and move it to counter register 
       mtc0  $k0 , $9            
       b      ret                         #### edit from end to ret           #########
        
      save_stateOfTask1 : 
      
        mfc0  $k0 , $14        # get the value of pc from epc register
        sw $k0, pcb_task1
         
        sw $a0 , pcb_task1+8
        sw $v0 , pcb_task1+12      
        sw $t0 , pcb_task1+16
        sw $t1 , pcb_task1+20
        
        mfhi $k0 
        sw  $k0 , pcb_task1+24 
        mflo  $k0
        sw   $k0 , pcb_task1+28
         
        sw  $k1 , pcb_task1+32         # get $at register and store it is value in data structure  
        b   update_Counter
        
          save_stateOfTask2 : 
      
        mfc0  $k0 , $14        # get the value of pc from epc register
        sw $k0, pcb_task2
         
        sw $a0 , pcb_task2+8 
        sw $v0 , pcb_task2+12      
   
        mfhi $k0 
        sw  $k0 , pcb_task2+16   
        mflo  $k0
        sw   $k0 , pcb_task2+20
         
        sw  $k1 , pcb_task2+24         # get $at register and store it is value in data structure  
        b   update_Counter 
        
    	j	ret                        # AM NOT SURE BUT THIS JUMP WAS ALREADY HERE       //////////
        changeBit : 
           li $k0 , 1 
          j  ret
       
# Process control blocks
# Location 0: the program counter
# Location 1: state of the process; here 0 -> idle, 1 -> running
# Location 2-..: state of the registers
	.kdata
pcb_task1:             #  i have to add word for Location 2 #####################
.word task1
.word 0

# TODO Allocate space for the state of all registers here
.word 0,0,0,0,0,0,0                 #  Allocate space for all registers of task1 : $a0 , $v0 , $t0, $t1, $lo ,$hi, $at

pcb_task2:             #  i have to add word for Location 2 #####################
.word task2
.word 0

# TODO Allocate space for the state of all registers here
.word 0,0,0,0,0                 #  Allocate space for all registers of task2 : $a0 , $v0 ,( $t0 ), ( $t1 ), $lo ,$hi, $at
