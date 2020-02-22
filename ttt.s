##########################
## Name: Braydon Hampton
## File: ttt.s 
##########################

#=====================================================================
# INPUT: 
# n = board size (size of row/col)
# size = n*n
# Row
# Col
#
# REGISTER ASSOCIATION: 
# s0 = n
# s1 = n*n (size) 
# s2 = index (4 * (n * row + col))
# s3 = turn (1 or 2)
# s4 = main loop incrementation
# s5 = $ra placeholder
# s6 = array start address
# s7 = player turn (1)
#
# NOTE:
# 0 = Space
# 1 = X
# 2 = 0
#=====================================================================

#########################################################################################
##																					   ##
##	text Segment																	   ##
##																					   ##
#########################################################################################

	.text
	.globl main
	
main:
		############# input #############		
		li	$s7, 1			#initialize player turn 
		la	$s6, Board
		la	$a0, Greeting
		li	$v0, 4			#Print introduction
		syscall
		
		li	$v0, 5
		syscall				# Get row/col size
		move $s0, $v0
		mul	$s1, $s0, $s0	# Get board size
		
		li		$s3, 1		# set turn
		jal		Init
		jal		printBoard
		
		# LOOP HERE
########################################
		li		$s4, 1
MLOOP:	beq	$s4, $s1, ENDMLOOP	
		
		#player turn
		bne		$s3, $s7, AIturn
		la	$a0, PlTurn
		li	$v0, 4			#Print Player turn
		syscall
		jal		getInput
		j		ENDAI
AIturn:		
		#AI turn
		la	$a0, AITurn
		li	$v0, 4			#Print AI turn
		syscall
#######################################
		#AI go for win
		# MUST USE $t4 or higher
AIwin:
		li		$t4, 0
		move	$t5, $s6
AIWLOOP:
		beq		$t4, $s1, ENDAIWLOOP
		
		lw		$t6, 0($t5)
		bne		$t6, $zero, NoChange2
		sw		$s3, 0($t5)				# see if 0 in pos will cause gameover
		jal		Gameover
		bne		$v1, $zero, ENDAI
		sw		$zero, 0($t5)
		
NoChange2:		
		addi	$t5, $t5, 4
		addi	$t4, $t4, 1
		j		AIWLOOP
ENDAIWLOOP:

########################################
		#AI prevent player win
		# MUST USE $t4 or higher
AIBwin:
		li		$t4, 0
		move	$t5, $s6
AIBLOOP:
		beq		$t4, $s1, ENDAIBLOOP
		
		lw		$t6, 0($t5)
		bne		$t6, $zero, NoChange3
		jal		TurnSwap
		sw		$s3, 0($t5)				#see if X in pos will cause gameover
		jal		Gameover
		jal		TurnSwap
		bne		$v1, $zero, BLOCK
		sw		$zero, 0($t5)
		j		NoChange3
		
BLOCK:
		sw		$s3, 0($t5)
		j		ENDAI
		
NoChange3:		
		addi	$t5, $t5, 4
		addi	$t4, $t4, 1
		j		AIBLOOP
ENDAIBLOOP:

########################################
		
		jal		AIdefault	#default AI move
ENDAI:
		
		jal		printBoard	
		
		jal		Gameover
		bne		$v1, $zero, WINNER
		jal		TurnSwap
		addi	$s4, $s4, 1
		j		MLOOP
ENDMLOOP:
########################################
#		jal		printBoard
		la		$a0, Draw
		li		$v0, 4
		syscall
		j		endProg
WINNER:
		bne	$s3, $s7, AIWmessage
		la		$a0, PlWin
		li		$v0, 4
		syscall
		j		endProg
AIWmessage:					#	state ai won
		la		$a0, AIWin
		li		$v0, 4
		syscall
		############ exiting ############
endProg:
		li		$v0, 10		#exit
		syscall

		
		
		
		
		
		
		
		
		
		
		
		
		
#########################################################################################
#	AI DEFAULT																			#
#########################################################################################
AIdefault:
		li		$t0, 0
		move	$t1, $s6
AIDLOOP:
		beq		$t0, $s1, ENDAIDLOOP
		
		lw		$t2, 0($t1)
		bne		$t2, $zero, NoChange1
		sw		$s3, 0($t1)
		j		ENDAIDLOOP
		
NoChange1:		
		addi	$t1, $t1, 4
		addi	$t0, $t0, 1
		j		AIDLOOP
ENDAIDLOOP:
		jr		$ra
		
#########################################################################################
#	TURN SWAP																			#
#########################################################################################
TurnSwap:
		li	$t0, 1
		beq	$t0, $s3, SETAI		# if turn = X swap to 0
		li	$s3, 1				# else make it X
		j		ExitTS
SETAI:	li	$s3, 2
ExitTS:
		jr		$ra
#########################################################################################
#########################################################################################


#########################################################################################
#	CHECK DIAG L~R																		#
#	s3 = turn																			#
#########################################################################################
CheckDiagLR:
			li		$v1, 0		#boolean
			li		$t1, 0		#set j to 0
			li		$t0, 0
CDLRL:		beq		$t0, $s1, ExitCDLRL		#for loop til i = size

			add		$t2, $t0, $t1
			add		$t2, $t2, $t2
			add		$t2, $t2, $t2
			la		$t3, 0($s6)			# load array index at board[i+j]
			add		$t2, $t2, $t3
			lw		$t2, 0($t2)

			bne		$t2, $s3, BreakNfalse3
			li		$v1, 1
			

			addi	$t1, $t1, 1			# ++j
			add		$t0, $t0, $s0		# i += n
			j		CDLRL
BreakNfalse3:
			li		$v1, 0
ExitCDLRL:
			jr		$ra

#########################################################################################
#########################################################################################

#########################################################################################
#	CHECK DIAG R~L																		#
#	s3 = turn																			#
#########################################################################################
CheckDiagRL:
			li		$v1, 0		#boolean
			addi	$t1, $s0, -1	#set j to n-1
			li		$t0, 0
CDRLL:		beq		$t0, $s0, ExitCDRLL		#for loop til i = size

			move	$t2, $t1
			add		$t2, $t2, $t2
			add		$t2, $t2, $t2
			la		$t3, 0($s6)			# load array index at board[i+j]
			add		$t2, $t2, $t3
			lw		$t2, 0($t2)

			bne		$t2, $s3, BreakNfalse2
			li		$v1, 1
			
			add		$t1, $t1, $s0		# j += n
			addi	$t1, $t1, -1		# j -= 1		aka j += n-1
			addi	$t0, $t0, 1			# ++i
			j		CDRLL
BreakNfalse2:
			li		$v1, 0
ExitCDRLL:
			jr		$ra

#########################################################################################
#########################################################################################

				
#########################################################################################
#	CHECK COL																			#
#	s3 = turn																			#
#########################################################################################
CheckCol:	
			li		$v1, 0		#boolean
			li		$t0, 0
CCL1:		beq		$t0, $s0, ExitCCL1		# for loop til i = n
			li		$t1, 0
CCL2:		beq		$t1, $s1, ExitCCL2		# for loop til j = size
			
			add		$t2, $t0, $t1
			add		$t2, $t2, $t2
			add		$t2, $t2, $t2
			la		$t3, 0($s6)			# load array index at board[i+j]
			add		$t2, $t2, $t3
			lw		$t2, 0($t2)
			
			bne		$t2, $s3, BreakNfalse1
			li		$v1, 1
			
			add		$t1, $t1, $s0		# j += n
			j		CCL2
BreakNfalse1:							# breaks if n in a row pieces
			li		$v1, 0
ExitCCL2:			
			bne		$v1, $zero, ExitCCL1
			addi		$t0, $t0, 1		# ++i
			j		CCL1
ExitCCL1:	
			
			jr		$ra
#########################################################################################
#########################################################################################
		
		
#########################################################################################
#	CHECK ROW																			#
#	s3 = turn																			#
#########################################################################################
CheckRow:	
			li		$v1, 0		#boolean
			li		$t0, 0
CRL1:		beq		$t0, $s1, ExitCRL1		# for loop til i = size
			li		$t1, 0
CRL2:		beq		$t1, $s0, ExitCRL2		# for loop til j = n
			
			add		$t2, $t0, $t1
			add		$t2, $t2, $t2
			add		$t2, $t2, $t2
			la		$t3, 0($s6)				# load array index at board[i+j]
			add		$t2, $t2, $t3
			lw		$t2, 0($t2)
			
			bne		$t2, $s3, BreakNfalse
			li		$v1, 1
			
			addi	$t1, $t1, 1				# ++j
			j		CRL2
BreakNfalse:								# break s if n in a row pieces
			li		$v1, 0
ExitCRL2:			
			bne		$v1, $zero, ExitCRL1
			add		$t0, $t0, $s0			# i += n
			j		CRL1
ExitCRL1:	
			
			jr		$ra
#########################################################################################
#########################################################################################
		
		
#########################################################################################
#	GAMEOVER																			#
#########################################################################################
Gameover:
			move	$s5, $ra
			## check row
			jal		CheckRow
			bne		$v1, $zero, GOReturn
			## check col
			jal		CheckCol
			bne		$v1, $zero, GOReturn
			## check diag R~L
			jal		CheckDiagRL
			bne		$v1, $zero, GOReturn
			## check diag L~R
			jal		CheckDiagLR
			bne		$v1, $zero, GOReturn
			
GOReturn:	jal		$s5
#########################################################################################
#########################################################################################


		
#########################################################################################
#	INIT BOARD																			#
#########################################################################################
Init:
		li	$t0, 0
		li	$t2, 2
		la	$t1, Board
INITL:	
		beq $t0, $s1, ENDINITL
		

		sw 	$zero, 0($t1)
		addi	$t1, $t1, 4
		addi	$t0, $t0, 1
		j  	INITL
		
ENDINITL:
		######## SET AI MOVE 1 #######
		div		$s0, $t2
		mfhi	$t0
		beq $t0, $zero, NEVEN
		## set AI piece to mid via n/2
		div		$s1, $t2
		mflo	$t0
		li		$t1, 4
		mul		$t0, $t0, $t1
		la		$t1, Board
		add		$t1, $t1, $t0
		sw		$t2, 0($t1)
		
		j 	NODD
NEVEN:  ## set AI piece to mid via n(n/2 -1) + n/2 - 1
		div		$s0, $t2
		mflo	$t0
		addi	$t0, $t0, -1	# store (n / 2) - 1
		mul		$t1, $s0, $t0	#n (n/2-1)
		add		$t1, $t1, $t0	
		li		$t0, 4
		mul		$t1, $t1, $t0
		la		$t0, Board
		add		$t1, $t1, $t0
		sw	$t2, 0($t1)
NODD:

		jr		$ra

#########################################################################################
#########################################################################################

		
#########################################################################################
# GET USER MOVE																			#
#########################################################################################

getInput:
INVALID:la	$a0, InRow
		li	$v0, 4		# print row request
		syscall
		
		li	$v0, 5
		syscall			# get row input
		move	$s2, $v0
		
		la	$a0, InCol
		li	$v0, 4		# get col request
		syscall
		
		li	$v0, 5
		syscall			# get col input
		move	$t3, $v0
		
		mul 	$s2, $s2, $s0
		addu	$s2, $s2, $t3	# convert input to index
		bge		$s2, $s1, INVALID1
		blt		$s2, $zero, INVALID1			
		li	$v0, 4
		mul		$s2, $s2, $v0
		la		$t0, Board
		add		$t0, $t0, $s2
		lw		$s2, 0($t0)
		
		
		beq $s2, $zero, VALID
INVALID1:		la		$a0, BadInput
				li		$v0, 4
				syscall
				j 	INVALID
VALID:		
		li	$t1, 1
		sw	$s3, 0($t0)			#### EDIT HERE TO MAKE MOVE CONST TO 1

		jr	$ra
#########################################################################################
#########################################################################################


		
#########################################################################################
# PRINT BOARD FUNCTION																	#
#########################################################################################
printBoard:
		li	$t0, 0
		la	$t3, Board
PBL:	beq	$t0, $s0, ENDPBL # main print loop
		#######################
		## print boarder
		#######################
		la	$a0, HBoarderEnd
		li	$v0, 4			# print +
		syscall
		
		li	$t1, 0
PBL2:	beq	$t1, $s0, ENDPBL2


		
		la	$a0, HBoarder	# print -+ n times
		li	$v0, 4
		syscall
		
		addi	$t1, $t1, 1
		j	PBL2
ENDPBL2:
		la	$a0, Newline
		li	$v0, 4			#print newline
		syscall
		
		######################
		## print pieces
		######################
		li	$t1, 0
PBL4:	beq	$t1, $s0, ENDPBL4
		
		la	$a0, VLine
		
		li	$v0, 4
		syscall
		
		lw	$a0, 0($t3)
		bne	$a0, $zero, SKIP1
		la	$a0, Space
		j		PrintPiece
SKIP1:
		bne	$a0, $s7, SKIP2
		la	$a0, PlayerX
		j		PrintPiece		
SKIP2:	
		la	$a0, Player0
PrintPiece:
		li	$v0, 4
		syscall

		addi	$t3, $t3, 4
		addi	$t1, $t1, 1		
		j	PBL4
		
ENDPBL4:
		la	$a0, VLine
		li	$v0, 4
		syscall

		la	$a0, Newline
		li	$v0, 4			#print newline
		syscall
		
		addi	$t0, $t0, 1
		j	PBL
ENDPBL: 
		#####################
		## print boarder
		#####################
		la	$a0, HBoarderEnd
		li	$v0, 4			# print +
		syscall
		
		li	$t1, 0
PBL3:	beq	$t1, $s0, ENDPBL3

		la	$a0, HBoarder	# print -+ n times
		li	$v0, 4
		syscall

		addi	$t1, $t1, 1
		j	PBL3
ENDPBL3:
		la	$a0, Newline
		li	$v0, 4			#print newline
		syscall
		jr		$ra
#########################################################################################
#########################################################################################
		
#########################################################################################
##																					   ##
##	data Segment																	   ##
##																					   ##
#########################################################################################
		.data
				
Greeting:		.asciiz "Let's play a game of tic-tac-toe.\nEnter n: "
HBoarder:		.asciiz "-+"
HBoarderEnd:	.asciiz "+"
VLine:			.asciiz	"|"
Space:			.asciiz " "
PlayerX:		.asciiz "X"
Player0:		.asciiz "0"
Newline:		.asciiz "\n"
InRow:			.asciiz "Enter Row: "
InCol:			.asciiz "Enter Col: "
BadInput:		.asciiz "Invalid Move!\n"
PlWin:			.asciiz "You Win!!!\n\n"
AIWin:			.asciiz "I Won!!!\n\n"
Draw:			.asciiz "Draw..."
AITurn:			.asciiz "\nMy turn!\n"
PlTurn:			.asciiz "\nYour turn!\n"

Board:			.word 0
