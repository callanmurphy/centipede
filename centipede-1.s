#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Callan Murphy, 1006027844 (murph308)
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the project handout for descriptions of the milestones)
# - Milestone 1
# - Milestone 2
# - Milestone 3
#
# Which approved additional features have been implemented?
# (See the project handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# 
#
# Any additional information that the TA needs to know:
#
#####################################################################
# 
# Notes from a future Callan (2023-08-04):
# - download MARS v4.5: https://courses.missouristate.edu/KenVollmar/MARS/download.htm
# - open this file in MARS
# - click Tools > Bitmap Display and set it to 8 > 8 > 256 > 256 > $gp, then press "Connect to MIPS"
# - click Tools > Keyboard and Display MMIO Simulator, then press "Connect to MIPS"
# - click Run > Assemble
# - click Run > Go
# - the game should now render
# - to play, type keys in the bottom white box of the Keyboard and Display MMIO Simulator
# - press j to move left and k to move right

 .data
	displayAddress:	.word 0x10008000
	bugBlasterLocation: .word 944
	
	centipedeSize: .word 10
	centipedeLocation: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	centipedeDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	
	screenHeight: .word 32
	screenWidth: .word 32
	
	playing: .word 0
	
	black: .word 0x00000  # Background colour
	green: .word 0x00ff00  # Centipede colour
	orange: .word 0xff9100 # Mushrooms colour
	white: .word 0xffffff  # Bug Blaster colour


 .text
 
#####################################################################
# Game setup (draw mushrooms, draw inital Bug Blaster)

gameSetup:
	# load to registers from data
	lw $t0, displayAddress 		# $t0 stores the base address for display
	lw $t1, white
	lw $t2, orange
	
	# draw initial Bug Blaster
	lw $t5, bugBlasterLocation
	
	sll $t4, $t5, 2		# $t4 is the bias of the location in memory (offset*4)
	add $t4, $t0, $t4	# $t4 is the address of the location
	sw $t1, 0($t4)		# colour the 0($t4) pixel white
	
	# draw mushrooms
	sw $t2, 604($t0)
	sw $t2, 1204($t0)
	sw $t2, 2200($t0)
	sw $t2, 2800($t0)
	
	#li $a0, 5
	#li $a1, 3
	#mult $a0, $a1
	#jal get_random_number		# Get random number (0-24) in $a0
	#lw $t5, 0($a0)	
	
#####################################################################
# Main game loop

Loop:
	jal check_keystroke
	jal draw_centipede
	
	
	#beq centipedepos, mushroompos, func
	
	# sleep before loop restart (delay)
	li $v0, 32	# sleep op code
	li $a0, 300	# sleep 50 milliseconds
	syscall
	
	#jal check_keystroke
			
	j Loop


#####################################################################
# Various game functions below
#####################################################################


# Draw a static centipede
draw_centipede:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw $t0, centipedeSize

	la $a1, centipedeLocation  # load the address of the array into $a1
	la $a2, bugBlasterLocation # load the address of the array into $a2
	add $a3, $zero, $t0	   # load a3 with the loop count (centipedeSize)
	
# iterate over the loops elements to draw each body in the centiped
arr_loop:
	lw $t1, 0($a1)		 # load a word from the centipedeLocation array into $t1
	lw $t5, 0($a2)		 # load a word from the centipedeDirection  array into $t5

	lw $t2, displayAddress   # $t2 stores the base address for display
	lw $t3, green		 # $t3 stores the green colour code
	lw $t6, black		 # t6 stores the black colour code
	
	# save location for black painting
	lw $t7, 0($a1) 		# save old location before it's changed
	
	# move centipede
	add $t1, $t1, $t0	# increase pixel location $t0 to the right
	sw $t1, 0($a1)		# save the new location to memory from register
	
	beq $t1, $t5, Exit
	
	# paint previous location black
	sll $t4,$t7, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t6, 0($t4)		# paint old bug with colour: $t6
	
	# draw centipede
	sll $t4,$t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the body with colour: $t3
	
	# increment loop
	addi $a1, $a1, 4	 # DRAW increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	
	# delay ----------------------
	li $v0, 32	# sleep op code
	li $a0, 50	# sleep 50 milliseconds
	syscall
	
	bne $a3, $zero, arr_loop
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

setup_centipede_loop:
	lw $t1, 0($a1)		 # load a word from the centipedeLocation array into $t1
	
	# reset locations
	add $t1, $t1, $a3	
	sw $t1, 0($a1)		# save the new location to memory from register
	
	# draw centipede
	sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t0, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the body with colour: $t3
	
	# increment loop
	addi $a1, $a1, 4	 # DRAW increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, 1	 # decrement $a3 by 1
	
	bne $a3, $t8, setup_centipede_loop	# exit loop when $a3 equals $t8
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x73, respond_to_s
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugBlasterLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, black	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	beq $t1, 800, skip_movement # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the right

skip_movement:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, white	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugBlasterLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, black		# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 831, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right

skip_movement2:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, white	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the block with white
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of s key - restart game
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, displayAddress
	la $a1, centipedeLocation  # load the address of the array into $a1
	lw $t5, bugBlasterLocation
	
	lw $t7, white
	lw $t6, black

	# paint old location black
	sll $t4, $t5, 2		# $t4 is the bias of the location in memory (offset*4)
	add $t4, $t0, $t4	# $t4 is the address of the location
	sw $t6, 0($t4)		# colour the 0($t4) pixel white
	
	# reset location
	addi $t5, $zero, 944
	sw $t5, bugBlasterLocation
	
	# paint the reset Bug Blaster
	sll $t4, $t5, 2		# $t4 is the bias of the location in memory (offset*4)
	add $t4, $t0, $t4	# $t4 is the address of the location
	sw $t7, 0($t4)		# colour the 0($t4) pixel white
	
	
	#addi $t5, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of x key
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)

Exit:
	li $v0, 10 		# terminate the program gracefully
	syscall
	
get_random_number:
  	li $v0, 42         # Service 42, random int bounded
  	li $a0, 0          # Select random generator 0
  	li $a1, 24             
  	syscall             # Generate random int (returns in $a0)
  	jr $ra
