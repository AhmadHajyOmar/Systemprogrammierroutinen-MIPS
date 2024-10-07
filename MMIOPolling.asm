.text

# Bootup code
# Since we only implement input/output with polling here and do no computations, all your code can be here.

.ktext
start:
	lbu $k0, 0xffff0000 ## keyboard control port		
        andi $k1, $k0, 0x01	## store interrrupt-enableness ##### 1stLSB == 1 -> ready  |  if LSB==0 -> no key pressed
	beq $k1, 0, start		## if keyboard wasn't ready: loop || else: continue underneath
	lw $k1, 0xffff0004		## store char from keyboard in $k1
	# TODO Implement input/output with polling
	b print
print:
	lbu $k0, 0xffff0008 ## screen control port
	andi $k0, $k0, 0x01 ## extract reayd bit = LSB
	beq $k0, 0, print   ## 1 = ready ;; 0 = try again
	sw $k1, 0xffff000c ## actual print
	b start
	
