INCLUDE Irvine32.inc


.data
    
    BOARD_SIZE      EQU 4
    TILE_SIZE       EQU 4           
    
    
    board          DWORD 16 DUP(0) 
    score          DWORD 0
    game_over       DWORD 0
    is_move_d        DWORD 0         ; change in block positions
    can_move         dword 0           ; checks if any move can be maid more the valid postion and early game over
    
    
    lineBuf         DWORD 4 DUP(0)
    tempBuf         DWORD 4 DUP(0)
    emptyIndices    DWORD 16 DUP(0) ; Stores indices of empty cells for spawning
    checkValidMove  dword 16 Dup(0) ; see if any move can be made


    ; Strings

    strTitle        BYTE "2048", 0
    strScore        BYTE "Score: ", 0
    strControls     BYTE "Controls: w, a, s, d to move; q to quit", 0
    strLine         BYTE "+++------+++------+++------+++------+++", 0
    strPipe         BYTE " | ", 0
    strSpace        BYTE "      ", 0
    strGameOver     BYTE "GAME OVER! Final Score: ", 0
    strWin          BYTE "YOU WIN!", 0
    strQuit         BYTE "Quit...", 0
    strLost         BYTe "sorry no valid moves left", 0



    ; number space pad

    fP1         BYTE "   ",0    ; d1/d2
    fP2         BYTE "  ",0     ; d2
    fP3         BYTE "  ",0     ; d2/d3
    fP4         BYTE " ",0      ; d4
    
.code


;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; main proc
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

main PROC
    call Randomize          ; rand ke seed
              
    call SpawnTile
    call SpawnTile
    
GameLoop:
    call DrawBoard
    ;call Check valid if not vlaid if al l then end game
    ;cmp al, 'l'
    ;je quiting
    
    call ReadChar           
    call WriteChar         
    
    cmp al, 'q'
    je quiting
    

    mov is_move_d, 0        
    

    cmp al, 'w'
    je up
    cmp al, 's'
    je down
    cmp al, 'a'
    je left
    cmp al, 'd'
    je right
    jmp GameLoop           


; see if something moves if it doesn't move its an inavlid move and therefore there shouldn't be any spwans 
up:
    call move_Up
    jmp Checkmove_
down:
    call move_Down
    jmp Checkmove_
left:
    call move_Left
    jmp Checkmove_
right:
    call move_Right
    jmp Checkmove_

Checkmove_:
    cmp is_move_d, 1
    jne GameLoop           
    
    call SpawnTile
    jmp GameLoop

quiting:                  
    call Crlf
    mov edx, OFFSET strQuit
    call WriteString
    call Crlf
    exit

lost:                  
    call Crlf
    mov edx, OFFSET strLost
    call WriteString
    call Crlf
    exit
main ENDP

;XXXXXXXXXXXXXXXXXXx
;actual merging and sorthing 
;xxxxxxxxxxxxxxxxxxxx
ProcessLine PROC uses ecx esi edi ebx
    
    mov ecx, BOARD_SIZE                                                 ; lline buf (esi)---> temp buf (edi) skip the zero
    mov esi, 0              
    mov edi, 0              
    
   
    mov ebx, 0                 ;temp clear so no left over from perv use of this fucntion left
    mov tempBuf[0], ebx
    mov tempBuf[4], ebx
    mov tempBuf[8], ebx
    mov tempBuf[12], ebx




ShiftLoop:                      ;copy the line buf to temp buf and skip the zeros
    mov ebx, lineBuf[esi*4]
    cmp ebx, 0
    je SkipZero
    mov tempBuf[edi*4], ebx
    inc edi

SkipZero:
    inc esi
    dec ecx         
    jnz ShiftLoop   


    ; Step 2: Merge adjacent equals in tempBuf
 

    mov esi, 0
MergeLoop:                      ; comp x and x + 1 see if they are the same and then add 
    cmp esi, 3
    jge EndMerge
    
    mov eax, tempBuf[esi*4] 
    cmp eax, 0
    je EndMerge                 ;if zero no need to go forth just end it 
    
    mov ebx, tempBuf[esi*4 + 4] ; Next val
    cmp ebx, 0
    je EndMerge   
    cmp eax, ebx
    jne NextMerge           
    
    
    add eax, ebx            
    mov tempBuf[esi*4], eax
    add score, eax                          ; score updated (score will be the sum of the addition)
    mov tempBuf[esi*4 + 4], 0                ; Clear merged tile
    

    
NextMerge:
    inc esi
    jmp MergeLoop
EndMerge:

    ; final line shift 
    mov ecx, BOARD_SIZE
    mov esi, 0 
    mov edi, 0 
    
    
    push eax
    mov eax, 0          ;clean buffer 
    mov lineBuf[0], eax
    mov lineBuf[4], eax
    mov lineBuf[8], eax
    mov lineBuf[12], eax
    pop eax

    mov esi, 0
    mov edi, 0
CompactFinal:                           
    cmp esi, 4
    jge FinishProcess
    mov eax, tempBuf[esi*4]
    cmp eax, 0                          
    je SkipFinal
    mov lineBuf[edi*4], eax
    inc edi
SkipFinal:
    inc esi
    jmp CompactFinal

FinishProcess:
    ret
ProcessLine ENDP

;XXXXXXXX
;  wasd
;xxxxxxxx

move_Left PROC uses ecx esi edi ebx
    
    mov ecx, 4
    mov esi, 0 
RowLoop:
    
    mov eax, esi
    mov ebx, 16
    mul ebx
    mov edi, eax 
    
    ; line buf 
    mov eax, board[edi]
    mov lineBuf[0], eax
    mov eax, board[edi+4]
    mov lineBuf[4], eax
    mov eax, board[edi+8]
    mov lineBuf[8], eax
    mov eax, board[edi+12]
    mov lineBuf[12], eax
    
    
    call ProcessLine
    
    ;comp if change then full changed and moved set
    mov ebx, board[edi]
    cmp ebx, lineBuf[0]
    jne ChangedL
    mov ebx, board[edi+4]
    cmp ebx, lineBuf[4]
    jne ChangedL
    mov ebx, board[edi+8]
    cmp ebx, lineBuf[8]
    jne ChangedL
    mov ebx, board[edi+12]
    cmp ebx, lineBuf[12]
    jne ChangedL
    jmp NoChangeL
    
ChangedL:
    mov is_move_d, 1
    mov eax, lineBuf[0]
    mov board[edi], eax
    mov eax, lineBuf[4]
    mov board[edi+4], eax
    mov eax, lineBuf[8]
    mov board[edi+8], eax
    mov eax, lineBuf[12]
    mov board[edi+12], eax
    
NoChangeL:
    inc esi
    dec ecx         
    jnz RowLoop     
    ret
move_Left ENDP

move_Right PROC uses ecx esi edi ebx
    ; rev of left the same 

    mov ecx, 4
    mov esi, 0
RowLoopR:
    
    
    mov eax, esi
    mov ebx, 16
    mul ebx
    mov edi, eax ; Base offset
    
    ;  3 _> 2 -> 1 -> 0
    mov eax, board[edi+12]
    mov lineBuf[0], eax
    mov eax, board[edi+8]
    mov lineBuf[4], eax
    mov eax, board[edi+4]
    mov lineBuf[8], eax
    mov eax, board[edi]
    mov lineBuf[12], eax
    
    call ProcessLine
    
    ; Compare and Write Back REVERSE
    mov ebx, board[edi+12]
    cmp ebx, lineBuf[0]
    jne ChangedR
    mov ebx, board[edi+8]
    cmp ebx, lineBuf[4]
    jne ChangedR
    mov ebx, board[edi+4]
    cmp ebx, lineBuf[8]
    jne ChangedR
    mov ebx, board[edi]
    cmp ebx, lineBuf[12]
    jne ChangedR
    jmp NoChangeR
    
ChangedR:
    mov is_move_d, 1
    mov eax, lineBuf[0]
    mov board[edi+12], eax
    mov eax, lineBuf[4]
    mov board[edi+8], eax
    mov eax, lineBuf[8]
    mov board[edi+4], eax
    mov eax, lineBuf[12]
    mov board[edi], eax
    
NoChangeR:
    inc esi
    dec ecx         
    jnz RowLoopR    
    ret
move_Right ENDP


move_Up PROC uses ecx esi edi ebx
    
    mov ecx, 4
    mov esi, 0 ; Col index then +4 the prev iternation col 
ColLoopU:
    
    ; byte val go in col by 0,16,32,48 and then plus 4
    ;col to line buf then line buf to board then esi plus 
    mov eax, board[esi*4]
    mov lineBuf[0], eax
    mov eax, board[esi*4 + 16]
    mov lineBuf[4], eax
    mov eax, board[esi*4 + 32]
    mov lineBuf[8], eax
    mov eax, board[esi*4 + 48]
    mov lineBuf[12], eax
    
    call ProcessLine
    
    ; bock to board from line bujf
    mov ebx, board[esi*4]
    cmp ebx, lineBuf[0]
    jne ChangedU
    mov ebx, board[esi*4 + 16]
    cmp ebx, lineBuf[4]
    jne ChangedU
    mov ebx, board[esi*4 + 32]
    cmp ebx, lineBuf[8]
    jne ChangedU
    mov ebx, board[esi*4 + 48]
    cmp ebx, lineBuf[12]
    jne ChangedU
    jmp NoChangeU  ;if no changes move to inc without making moved 1 
    
ChangedU:
    mov is_move_d, 1
    mov eax, lineBuf[0]
    mov board[esi*4], eax
    mov eax, lineBuf[4]
    mov board[esi*4 + 16], eax
    mov eax, lineBuf[8]
    mov board[esi*4 + 32], eax
    mov eax, lineBuf[12]
    mov board[esi*4 + 48], eax
    
NoChangeU:
    inc esi
    dec ecx         
    jnz ColLoopU    ; TO FIX JUMP DISTANCE
    ret
move_Up ENDP




move_Down PROC uses ecx esi edi ebx
    
    mov ecx, 4
    mov esi, 0 ; Col index
ColLoopD:
    push ecx
    
    ;rev extraction same logic as up
    mov eax, board[esi*4 + 48]
    mov lineBuf[0], eax
    mov eax, board[esi*4 + 32]
    mov lineBuf[4], eax
    mov eax, board[esi*4 + 16]
    mov lineBuf[8], eax
    mov eax, board[esi*4]
    mov lineBuf[12], eax
    
    call ProcessLine
    
    ; back to board
    mov ebx, board[esi*4 + 48]
    cmp ebx, lineBuf[0]
    jne ChangedD
    mov ebx, board[esi*4 + 32]
    cmp ebx, lineBuf[4]
    jne ChangedD
    mov ebx, board[esi*4 + 16]
    cmp ebx, lineBuf[8]
    jne ChangedD
    mov ebx, board[esi*4]
    cmp ebx, lineBuf[12]
    jne ChangedD
    jmp NoChangeD
    
ChangedD:
    mov is_move_d, 1
    ;full copy of col 
    mov eax, lineBuf[0]
    mov board[esi*4 + 48], eax
    mov eax, lineBuf[4]
    mov board[esi*4 + 32], eax
    mov eax, lineBuf[8]
    mov board[esi*4 + 16], eax
    mov eax, lineBuf[12]
    mov board[esi*4], eax
    
NoChangeD:
    inc esi
    pop ecx
    dec ecx         
    jnz ColLoopD    
    ret
move_Down ENDP

;xxxxxxx
;spawn
;xxxxxxx

SpawnTile PROC uses eax ebx ecx edx esi edi
    ;sq  empty tiles
    mov ecx, 16
    mov esi, 0 
    mov edi, 0 ; count of the empty tiles
    
FindEmpty:
    mov eax, board[esi*4]
    cmp eax, 0
    jne NotEmpty
    mov emptyIndices[edi*4], esi ; saves the index of the empty tiles 
    inc edi
NotEmpty:
    inc esi
    dec ecx         
    jnz FindEmpty   
    
    
    cmp edi, 0 ; if zero spaces then no need skip 
    je SpawnDone
    
    
    mov eax, edi
    call RandomRange ; rand  val 
    
    ;index of the spawn set to ebx
    mov ebx, emptyIndices[eax*4] 
    
    ; 2 has 90 percent chance of coming and 4 q0 percent chance
    mov eax, 10
    call RandomRange
    cmp eax, 0 ; 0-9 and 0 means 10 percent 
    je Spawn4
    mov board[ebx*4], 2
    jmp SpawnDone
Spawn4:
    mov board[ebx*4], 4
    
SpawnDone:
    ret
SpawnTile ENDP



;xxxxxxxxxxxxxxxxxxxxx
; pading and color and drawing
; xxxxxxxxxxxxxxxxxxxx

SetColorForValue PROC uses eax
   
    ;eax val se colour set karna
    
    cmp eax, 2
    je C_2
    cmp eax, 4
    je C_4
    cmp eax, 8
    je C_8
    cmp eax, 16
    je C_16
    cmp eax, 32
    je C_32
    cmp eax, 64
    je C_64
    cmp eax, 128
    je C_128
    cmp eax, 256
    je C_2
    cmp eax, 512
    je C_4
    cmp eax, 1024
    je C_8
    cmp eax, 2048
    je C_16
   
    jmp C_High


C_2:     mov eax, white     
         jmp DoSet
C_4:     mov eax, yellow     
         jmp DoSet
C_8:     mov eax, lightRed  
         jmp DoSet
C_16:    mov eax, lightMagenta 
         jmp DoSet
C_32:    mov eax, lightBlue 
         jmp DoSet
C_64:    mov eax, lightCyan 
         jmp DoSet
C_128:   mov eax, lightGreen 
         jmp DoSet
C_High:  mov eax, lightCyan
         jmp DoSet

DoSet:
    call SetTextColor
    ret
SetColorForValue ENDP

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxxxx

DrawBoard PROC
    call Clrscr
    
    mov eax, lightMagenta                   ;top str
    call SetTextColor
    mov edx, OFFSET strTitle
    call WriteString
    call Crlf
    
    
    mov edx, OFFSET strScore                ;score
    call WriteString
    mov eax, score
    call WriteDec
    call Crlf
    
    
    mov edx, OFFSET strControls              ;control
    call WriteString
    call Crlf
    call Crlf
    
    
    mov ecx, 4      
    mov esi, 0      
       

DrawRowLoop:

    push ecx        ; 2 for loops push
    
    mov eax, RED
    call SetTextColor
    mov edx, OFFSET strLine
    call WriteString
    call Crlf
    
    
    mov ecx, 4                  ; inner 4 numbers and pad and space and pipe
DrawColLoop:
    mov eax, red
    call SetTextColor
    mov edx, OFFSET strPipe
    call WriteString
    
    
    mov eax, board[esi*4]                  ; set color on the number
    call SetColorForValue
    
    
    mov eax, board[esi*4]                   ; if number then print number else direct done 
    cmp eax, 0
    jne PrintNum
    
    
    mov edx, OFFSET strSpace
    call WriteString
    jmp CellDone
    
PrintNum:
    
    cmp eax, 10
    jl Pad1
    cmp eax, 100
    jl Pad2
    cmp eax, 1000
    jl Pad3
    jmp Pad4
    
Pad1:
    mov edx, OFFSET fP1
    call WriteString
    mov eax, board[esi*4]
    call WriteDec
    mov edx, OFFSET fP2
    call WriteString
    jmp CellDone
Pad2:
    mov edx, OFFSET fP2
    call WriteString
    mov eax, board[esi*4]
    call WriteDec
    mov edx, OFFSET fP2
    call WriteString
    jmp CellDone
Pad3:
    mov edx, OFFSET fP3
    call WriteString
    mov eax, board[esi*4]
    call WriteDec
    mov edx, OFFSET fP4
    call WriteString
    jmp CellDone
Pad4:
    mov edx, OFFSET fP4
    call WriteString
    mov eax, board[esi*4]
    call WriteDec
    mov edx, OFFSET fP4
    call WriteString

CellDone:
    inc esi
    dec ecx         
    jnz DrawColLoop
    
    mov eax, red
    call SetTextColor
    mov edx, OFFSET strPipe
    call WriteString
    call Crlf
    
    pop ecx        
    dec ecx         
    jnz DrawRowLoop 
    
    mov edx, OFFSET strLine
    call WriteString
    call Crlf
    
    ret
DrawBoard ENDP

END main
