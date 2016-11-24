; Tic-tac-toe assmebly
; For emu8086
; Made by Oz Elentok
.model small
.stack 100h
.data
	grid db 9 dup(0)
	player db 0
	win db 0
	temp db 0
	newGameQuest db "Would you like a rematch? (y - yes, any key - no)$"
	welcome db "Tic Tac Toe Game - By Oz Elentok$"
	separator db "---|---|---$"
	enterLoc db "Enter your move by location(1-9)$"
	tieMessage db "A tie between the two players!$"
	winMessage db "The player who won was $"
	inDigitError db "ERROR!, this place is taken$"
	inError db "ERROR!, input is not a digit$"
	newline db 0Dh,0Ah,'$'

	symbolMessage db "Symbol for $ "
	symbolWarningMessage db " (Except numbers): $"

	turnMessage db "Turn of $ "
	twodots db ": $ "

	symbol1 DB ?
	symbol2 DB ?

	namePlayer1 db "Name of player 1: $"
	namePlayer2 db "Name of player 2: $"

	username1 db 10, ?, 10 dup(' ')
	username2 db 10, ?, 10 dup(' ')
.CODE
START:
    MOV AX, DATA
    MOV DS, AX
    mov es, ax
NAME:
    ; prompt message to username for player 1
    lea dx, namePlayer1
    mov ah, 9
    int 21H

    mov dx, offset username1
    mov ah, 0ah
    int 21h

    lea dx, newline
	call printString

    ; prompt message to username for player 2
	lea dx, namePlayer2
    mov ah, 9
    int 21H

    mov dx, offset username2
    mov ah, 0ah
    int 21h

    lea dx, newline
	call printString
DISPLAY:
    ; set symbol for player 1
	mov ax, data
	mov ds, ax
	mov es, ax

    ; Ask player 1 name
    mov dx, offset symbolMessage
    mov ah, 9
    int 21h

    ; print player 1 name
	call printUsername1

    ; Show a message to say that only non digits was accept
    mov dx, offset symbolWarningMessage
    mov ah, 9
    int 21h

    mov ah, 1
    int 21H
    mov symbol1, al

	lea dx, newline
	call printString

    ; Set symbol for player 2
	mov ax, data
	mov ds, ax
	mov es, ax

    ; Ask player 2 name
    mov dx, offset symbolMessage
    mov ah, 9
    int 21h

    ; Print player 2 name
	call printUsername2

    ; Show a message to say that only non digits was accept
    mov dx, offset symbolWarningMessage
    mov ah, 9
    int 21h

    mov ah, 1
    int 21H
    mov symbol2, al

    ; end of set symbols

	mov ax, data
	mov ds, ax
	mov es, ax

	newGame:
	call initiateGrid
	mov player, 10b; 2dec
	mov win, 0
	mov cx, 9
	gameAgain:
		call clearScreen
		lea dx, welcome
		call printString
		lea dx, newline
		call printString
		lea dx, enterLoc
		call printString
		lea dx, newline
		call printString
		call printString
		call printGrid
		mov al, player
		cmp al, 1
		je p2turn
			; previous player was 2
			shr player, 1; 0010b --> 0001b;

            ;-------------------------------------------;
            ; Print change turn message
            mov dx, offset turnMessage
            mov ah, 9
            int 21h

            ; Print player 1 name
        	call printUsername1

            mov dx, offset twodots
            mov ah, 9
            int 21h

			jmp endPlayerSwitch
		p2turn:; previous player was 1
			shl player, 1; 0001b --> 0010b

			;-------------------------------------------;
            ; Print change turn message
            mov dx, offset turnMessage
            mov ah, 9
            int 21h

            ; Print player 2 name
        	call printUsername2

            mov dx, offset twodots
            mov ah, 9
            int 21h


		endPlayerSwitch:
		call getMove; bx will point to the right board postiton at the end of getMove
		mov dl, player
		cmp dl, 1
		jne p2move
		mov dl, symbol1
		jmp contMoves
		p2move:
		mov dl, symbol2
		contMoves:
		mov [bx], dl
		cmp cx, 5 ; no need to check before the 5th turn
		jg noWinCheck
		call checkWin
		cmp win, 1
		je won
		noWinCheck:
		loop gameAgain

	;tie, cx = 0 at this point and no player has won
	 call clearScreen
	 lea dx, welcome
	 call printString
	 lea dx, newline
	 call printString
	 call printString
	 call printString
	 call printGrid
	 lea dx, tieMessage
	 call printString
	 lea dx, newline
	 call printString
	 jmp askForNewGame

	won:; current player has won
	 call clearScreen
	 lea dx, welcome
	 call printString
	 lea dx, newline
	 call printString
	 call printString
	 call printString
	 call printGrid
	 lea dx, winMessage
	 call printString
	 cmp player, 1
	 je player1Win
	 jg player2Win

	askForNewGame:
	 lea dx, newGameQuest; ask for another game
	 call printString
	 lea dx, newline
	 call printString
	 call getChar
	 cmp al, 'y'; play again if 'y' is pressed
	 jne sof
	 jmp newGame

	sof:
	mov ax, 4c00h
	int 21h

;-------------------------------------------;
; Sets ah = 01
; Input char into al;
getChar:
	mov ah, 01
	int 21h
	ret
;-------------------------------------------;
; Sets ah = 02
; Output char from dl
; Sets ah to last char output
putChar:
	mov ah, 02
	int 21h
	ret
;-------------------------------------------;
; Sets ah = 09
; Outputs string from dx
; Sets al = 24h
printString:
	mov ah, 09
	int 21h
	ret
;-------------------------------------------;
; Clears the screen
; ah = 0 at the end
clearScreen:
	mov ah, 0fh
	int 10h
	mov ah, 0
	int 10h
	ret

;-------------------------------------------;
; Gets location that can be used
; after successfuly geting the location:
; al - will hold the place number(0 - 8)
; bx - will hold the positon(bx[al])
getMove:
	call getChar; al = getchar()
	call isValidDigit
	cmp ah, 1
	je contCheckTaken
	mov dl, 0dh
	call putChar
	lea dx, inError
	call printString
	lea dx, newline
	call printString
	jmp getMove

	contCheckTaken: ; Checks this: if(grid[al] > '9'), grid[al] == 'O' or 'X'
	lea bx, grid
	sub al, '1'
	mov ah, 0
	add bx, ax
	mov al, [bx]
	cmp al, '9'
	jng finishGetMove
	mov dl, 0dh
	call putChar
	lea dx, inDigitError
	call printString
	lea dx, newline
	call printString
	jmp getMove
	finishGetMove:
	lea dx, newline
	call printString
	ret

;-------------------------------------------;
; Initiates the grid from '1' to '9'
; Uses bx, al, cx
initiateGrid:
	lea bx, grid
	mov al, '1'
	mov cx, 9
	initNextTa:
	mov [bx], al
	inc al
	inc bx
	loop initNextTa
	ret

;-------------------------------------------;
; checks if a char in al is a digit
; DOESN'T include '0'
; if is Digit, ah = 1, else ah = 0
isValidDigit:
	mov ah, 0
	cmp al, '1'
	jl sofIsDigit
	cmp al, '9'
	jg sofIsDigit
	mov ah, 1
	sofIsDigit:
	ret


;-------------------------------------------;
; Outputs the 3x3 grid
; uses bx, dl, dx
printGrid:
	lea bx, grid
	call printRow
	lea dx, separator
	call printString
	lea dx, newline
	call printString
	call printRow
	lea dx, separator
	call printString
	lea dx, newline
	call printString
	call printRow
	ret

;-------------------------------------------;
; Outputs a single row of the grid
; Uses bx as the first number in the row
; At the end:
; dl = third cell on row
; bx += 3, for the next row
; dx points to newline
printRow:

	;First Cell
	mov dl, ' '
	call putChar
	mov dl, [bx]
	call putChar
	mov dl, ' '
	call putChar
	mov dl, '|'
	call putChar
	inc bx

	;Second Cell
	mov dl, ' '
	call putChar
	mov dl, [bx]
	call putChar
	mov dl, ' '
	call putChar
	mov dl, '|'
	call putChar
	inc bx

	;Third Cell
	mov dl, ' '
	call putChar
	mov dl, [bx]
	call putChar
	inc bx

	lea dx, newline
	call printString
	ret

;-------------------------------------------;
; Returns 1 in al if a player won
; 1 for win, 0 for no win
; Changes bx
checkWin:
	lea si, grid
	call checkDiagonal
	cmp win, 1
	je endCheckWin
	call checkRows
	cmp win, 1
	je endCheckWin
	call CheckColumns
	endCheckWin:
	ret

;-------------------------------------------;
checkDiagonal:
	;DiagonalLtR
	mov bx, si
	mov al, [bx]
	add bx, 4	;grid[0] ---> grid[4]
	cmp al, [bx]
	jne diagonalRtL
	add bx, 4	;grid[4] ---> grid[8]
	cmp al, [bx]
	jne diagonalRtL
	mov win, 1
	ret

	diagonalRtL:
	mov bx, si
	add bx, 2	;grid[0] ---> grid[2]
	mov al, [bx]
	add bx, 2	;grid[2] ---> grid[4]
	cmp al, [bx]
	jne endCheckDiagonal
	add bx, 2	;grid[4] ---> grid[6]
	cmp al, [bx]
	jne endCheckDiagonal
	mov win, 1
	endCheckDiagonal:
	ret

;-------------------------------------------;
checkRows:
	;firstRow
	mov bx, si; --->grid[0]
	mov al, [bx]
	inc bx		;grid[0] ---> grid[1]
	cmp al, [bx]
	jne secondRow
	inc bx		;grid[1] ---> grid[2]
	cmp al, [bx]
	jne secondRow
	mov win, 1
	ret

	secondRow:
	mov bx, si; --->grid[0]
	add bx, 3	;grid[0] ---> grid[3]
	mov al, [bx]
	inc bx	;grid[3] ---> grid[4]
	cmp al, [bx]
	jne thirdRow
	inc bx	;grid[4] ---> grid[5]
	cmp al, [bx]
	jne thirdRow
	mov win, 1
	ret

	thirdRow:
	mov bx, si; --->grid[0]
	add bx, 6;grid[0] ---> grid[6]
	mov al, [bx]
	inc bx	;grid[6] ---> grid[7]
	cmp al, [bx]
	jne endCheckRows
	inc bx	;grid[7] ---> grid[8]
	cmp al, [bx]
	jne endCheckRows
	mov win, 1
	endCheckRows:
	ret

;-------------------------------------------;
CheckColumns:
	;firstColumn
	mov bx, si; --->grid[0]
	mov al, [bx]
	add bx, 3	;grid[0] ---> grid[3]
	cmp al, [bx]
	jne secondColumn
	add bx, 3	;grid[3] ---> grid[6]
	cmp al, [bx]
	jne secondColumn
	mov win, 1
	ret

	secondColumn:
	mov bx, si; --->grid[0]
	inc bx	;grid[0] ---> grid[1]
	mov al, [bx]
	add bx, 3	;grid[1] ---> grid[4]
	cmp al, [bx]
	jne thirdColumn
	add bx, 3	;grid[4] ---> grid[7]
	cmp al, [bx]
	jne thirdColumn
	mov win, 1
	ret

	thirdColumn:
	mov bx, si; --->grid[0]
	add bx, 2	;grid[0] ---> grid[2]
	mov al, [bx]
	add bx, 3	;grid[2] ---> grid[5]
	cmp al, [bx]
	jne endCheckColumns
	add bx, 3	;grid[5] ---> grid[8]
	cmp al, [bx]
	jne endCheckColumns
	mov win, 1
	endCheckColumns:
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; MY EXTRA FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Print username1
printUsername1:
 xor bx, bx ; zero
 mov bl, username1[1] ; number of chars
 mov username1[bx+2], '$' ; insert $
 mov dx, offset username1 + 2
 mov ah, 9
 int 21H
 ret

; Print username2
printUsername2:
 xor bx, bx ; zero
 mov bl, username2[1] ; number of chars
 mov username2[bx+2], '$' ; insert $
 mov dx, offset username2 + 2
 mov ah, 9
 int 21H
 ret

; Player 1 win, print his name and ask for a new game
player1Win:
 xor bx, bx ; zero
 mov bl, username1[1] ; number of chars
 mov username1[bx+2], '$' ; insert $
 mov dx, offset username1 + 2
 mov ah, 9
 int 21H

 lea dx, newline
 call printString
 jmp askForNewGame

; Player 2 win, print his name and ask for a new game
player2Win:
 xor bx, bx ; zero
 mov bl, username2[1] ; number of chars
 mov username2[bx+2], '$' ; insert $
 mov dx, offset username2 + 2
 mov ah, 9
 int 21H

 lea dx, newline
 call printString
 jmp askForNewGame

.EXIT
end START


; referencias

; Ler caracter pra definir como simbolo: http://cssimplified.com/computer-organisation-and-assembly-language-programming/an-assembly-program-to-read-a-character-from-console-and-echo-it
