.model tiny,stdcall

include Snake.inc

include Defines.inc
include Point.inc
include Graphics.inc
include Buffer.inc

.code
org 1000h

Entry proc
	jmp Entry_start
	
	;Data here
	
	StrPause db 'Game Paused',0
	
	StrOver db 'Game Over',0
	
	public StrPause
	public StrOver
	
	IFDEF _DEBUG
	
	StrDBG db 'Debug Output.',0
	
	
	ENDIF
	
	
	Entry_start:
	xor ax,ax
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,1000h
	call InitGraphics
	call InitOS
	call InitFont
	call InitInt
	
		
	Entry_loop:
;	cli
;	mov cx,WORD PTR DS:[ADDR_KEY_STATE]
	mov dx,WORD PTR DS:[ADDR_GAME_STATE]
;	mov WORD PTR DS:[ADDR_KEY_STATE],0
;	sti
	
	
;	cli
	invoke GetKey
	sti
	
	;Set state and call Refresh
	
	cmp dx,GAME_OVER
	je Entry_Draw
	
	cmp dx,GAME_PAUSE
	jne Entry_R1
	;If pause
	cmp ax,KEY_ENTER
	jne Entry_Draw
	mov WORD PTR DS:[ADDR_GAME_STATE],0
	jmp Entry_Draw
	Entry_R1:
	
	cmp ax,KEY_ESC
	jne Entry_R
	
	;Pause the game
	mov WORD PTR DS:[ADDR_GAME_STATE],GAME_PAUSE
	jmp Entry_Draw
	Entry_R:
	
	invoke Refresh,ax
;	push ax
;	call Refresh
	
	
	Entry_Draw:
	invoke Redraw

	IFDEF _DEBUG
	invoke puts,addr StrDBG,0,0,COLOR_RED
	ENDIF
	
	call ScreenFlush
	invoke _Sleep,0
	jmp Entry_loop
	
	
	
	
	int 19h
	ret

Entry endp

InitFont proc
	push cx
	push si
	push di
	mov si,ADDR_CHARS_BASE
;	mov WORD PTR DS:[ADDR_FONT_BASE],(ADDR_CHARS_BASE+8)
	
	mov cx,4
	mov di,ADDR_FONT_COUNT	;Rely on the ADDRESS!!!!!!
	InitFont_loop:
	mov ax,WORD PTR CS:[si]
	mov WORD PTR DS:[di],ax
	add si,2
	add di,2
	loop InitFont_loop
	
	mov WORD PTR DS:[ADDR_FONT_BASE],si
	
	pop di
	pop si
	pop cx
	ret

InitFont endp


GetKey proc
	LOCAL @ret
	nop
	db 60h	;pusha
	GetKey_loop:
	invoke BufGet
	cmp ax,0
	je GetKey_end
	mov dx,ax
	and al,80h
	cmp al,0
	jne GetKey_loop
	
	cmp dl,KEY_PAGEUP
	jne GetKey_U
	;Page up
	cmp WORD PTR DS:[ADDR_TIMER_CONST],11h
	jbe GetKey_loop
	sub WORD PTR DS:[ADDR_TIMER_CONST],10h
	jmp GetKey_loop
	GetKey_U:
	cmp dl,KEY_PAGEDOWN
	jne GetKey_D
	;Page down
	cmp WORD PTR DS:[ADDR_TIMER_CONST],0FFE0h
	jbe GetKey_loop
	add WORD PTR DS:[ADDR_TIMER_CONST],10h
	jmp GetKey_loop
	GetKey_D:
	mov ax,dx
	GetKey_end:
	mov @ret,ax
	db 61h	;popa
	mov ax,@ret
	ret

GetKey endp


InitOS proc
	push es
	db 60h	;pusha
	xor ax,ax
	mov es,ax
	mov di,ADDR_STAGE_BASE
	mov cx,SIZE_STAGE
	cld
	rep stosb
	call InitRand
	call InitStage
	call NewFood
	call InitBuf
	
	mov WORD PTR DS:[ADDR_GAME_STATE],GAME_PAUSE
;	mov WORD PTR DS:[ADDR_KEY_STATE],KEY_ENTER
	db 61h	;popa
	pop es
	ret

InitOS endp

InitStage proc
	db 60h	;pusha
	invoke Rand,SIZE_STAGE
	mov bx,ax
	mov WORD PTR DS:[ADDR_CURRENT_HEAD],ax
	invoke Rand,4
	mov dx,ax
	invoke GetNextHead,al
	mov cx,ax
	mov dl,BYTE PTR DS:[ADDR_DIRECTION]
	invoke DirToState,dl
	or al,STATE_TAIL
	invoke SetPoint,bx,al
	mov WORD PTR DS:[ADDR_CURRENT_TAIL],bx
	add dl,2
	and dl,3
	invoke DirToState,dl
	or al,STATE_HEAD
	invoke SetPoint,cx,al
	mov WORD PTR DS:[ADDR_CURRENT_HEAD],cx
	mov WORD PTR DS:[ADDR_CURRENT_LENGTH],2
	db 61h	;popa
	ret

InitStage endp

InitRand proc
	xor ax,ax
	;Get current time here
	mov WORD PTR DS:[ADDR_RAND_SEED],ax
	ret

InitRand endp
InitInt proc


	;Set Int20 Callback address
	mov WORD PTR DS:[082h],0h
	mov WORD PTR DS:[080h],Int20_Proc
	mov WORD PTR DS:[086h],0h
	mov WORD PTR DS:[084h],Int21_Proc
	mov WORD PTR DS:[ADDR_TIMER_CONST],TIMER_CONST_DEFAULT
	mov WORD PTR DS:[ADDR_TIMER_COUNT],0
	
	;Init PIC controler	P_117
	invoke IO_out8,PIC0_IMR,0ffh
	invoke IO_out8,PIC1_IMR,0ffh
	invoke IO_out8,PIC0_ICW1,11h
	invoke IO_out8,PIC0_ICW2,20h
	invoke IO_out8,PIC0_ICW3,04h
	invoke IO_out8,PIC0_ICW4,01h
	invoke IO_out8,PIC1_ICW1,11h
	invoke IO_out8,PIC1_ICW2,28h	;20h ?
	invoke IO_out8,PIC1_ICW3,02h
	invoke IO_out8,PIC1_ICW4,01h
	
	sti
	
	invoke IO_out8,PIT_CTRL,034h
	invoke IO_out8,PIT_CNT0,0
	invoke IO_out8,PIT_CNT0,0

	invoke IO_out8,PIC0_IMR,0f8h	;11111000b	;11111110b ?
	invoke IO_out8,PIC1_IMR,0ffh
	
	ret

InitInt endp

IO_out8 proc Port:WORD , Data:BYTE
	
	push dx
	mov al,Data
	mov dx,Port
	out dx,al
	pop dx
	ret

IO_out8 endp

Int20_Proc proc
	db 60h	;pusha
	mov ax,WORD PTR DS:[ADDR_TIMER_COUNT]
	inc ax
	cmp ax,WORD PTR DS:[ADDR_TIMER_CONST]
	jb Int20_Proc_R
	xor ax,ax
	Int20_Proc_R:
	mov WORD PTR DS:[ADDR_TIMER_COUNT],ax
	
	invoke IO_out8,PIC0_OCW2,60h
	db 61h	;popa
	
	iret
Int20_Proc endp

Int21_Proc proc
	cli
	db 60h	;pusha
	invoke IO_out8,PIC0_OCW2,61h
	in al,PORT_KEYBOARD
	invoke BufAdd,al
	
	db 61h	;popa
	sti
	iret
	
	
Int21_Proc endp


Refresh proc Key:WORD
	push bx
	push cx
	push dx
	;Convert Key Code to Direction
	mov ax,Key
	cmp ax,KEY_ESC
	jne Refresh_s1
	mov WORD PTR DS:[ADDR_GAME_STATE],GAME_PAUSE
	jmp Refresh_end
	
	Refresh_s1:
	cmp ax,KEY_UP
	jne Refresh_s2
	mov bx,DIR_NORTH
	jmp Refresh_s0
	Refresh_s2:
	cmp ax,KEY_RIGHT
	jne Refresh_s3
	mov bx,DIR_EAST
	jmp Refresh_s0
	Refresh_s3:
	cmp ax,KEY_DOWN
	jne Refresh_s4
	mov bx,DIR_SOUTH
	jmp Refresh_s0
	Refresh_s4:
	cmp ax,KEY_LEFT
	jne Refresh_s5
	mov bx,DIR_WEST
	jmp Refresh_s0
	Refresh_s5:
	mov bx,WORD PTR DS:[ADDR_DIRECTION]
	Refresh_s0:
	mov ax,bx
	add ax,2
	and ax,3
	cmp ax,WORD PTR DS:[ADDR_DIRECTION]
	je Refresh_s5
;	switch (Key){
;	case KEY_ESC:
;	mov WORD PTR DS:[ADDR_GAME_STATE],GAME_PAUSE
;	return;
;	break;
;	case KEY_UP:
;	mov bx,DIR_NORTH
;	break
;	case KEY_RIGHT:
;	mov bx,DIR_EAST
;	break;
;	case KEY_DOWN:
;	mov bx,DIR_SOUTH
;	break;
;	case KEY_LEFT:
;	mov bx,DIR_LEFT;
;	break;
;	default:
;	mov bx,WORD PTR DS:[ADDR_CURRRENT_DIRECTION]
;	}

;	push bx
;	call GetNextHead
	invoke GetNextHead,bl
	;This function will get the new index of the head
	;Have ADDR_DIRECTION written
	;Also try to find a better way when reaching the edge
	
	mov dx,ax
	invoke GetPoint,ax
	mov cx,ax
	and ax,(STATE_BODY or STATE_HEAD or STATE_TAIL)
	cmp ax,0
	je Refresh_j1
	mov WORD PTR DS:[ADDR_GAME_STATE],GAME_OVER
;	mov ax,dx	;return the Index
	jmp Refresh_end
	Refresh_j1:
	and cx,STATE_FOOD
;	cmp cx,0
	;cx : if has got the food
	push cx
	
	mov bx,WORD PTR DS:[ADDR_CURRENT_HEAD]
	invoke GetPoint,bx
	and al,(not STATE_HEAD)
	or al,STATE_BODY
	mov cx,ax
;	mov ax,WORD PTR DS:[ADDR_DIRECTION]
	invoke DirToState,BYTE PTR DS:[ADDR_DIRECTION]
;	or al,bl
	or cl,al
	invoke SetPoint,bx,cl	;Old head
	
	mov cx,WORD PTR DS:[ADDR_DIRECTION]
	add cl,2
	and cl,3
	invoke DirToState,cl
	
	mov cl,STATE_HEAD
	or cl,al
	invoke SetPoint,dx,cl	;New head
	
	
	mov WORD PTR DS:[ADDR_CURRENT_HEAD],dx
	
	pop cx	;If grow longer
	cmp cx,0
	je Refresh_j2
	inc WORD PTR DS:[ADDR_CURRENT_LENGTH]
	
	call NewFood
	
	jmp Refresh_end
	
	Refresh_j2:
	
	mov bx,WORD PTR DS:[ADDR_CURRENT_TAIL]
	invoke GetPoint,bx
;	mov cl,4
;	mov ah,0
;	shr ax,cl
	invoke StateToDir,al
	cmp ax,0FFFFh
	je Die
	mov cx,ax
	invoke GetIndex,bx,al
	cmp ax,0FFFFh
	je Die
	mov dx,ax
	invoke SetPoint,bx,0
	mov WORD PTR DS:[ADDR_CURRENT_TAIL],dx
	invoke GetPoint,dx
	mov bx,ax
	and bl,(not STATE_BODY)
	or bl,STATE_TAIL
	add cl,2	;Direction
	and cl,3
	invoke DirToState,cl
	not al
	and bl,al
	invoke SetPoint,dx,bl
	
	
	
	Refresh_end:
	pop dx
	pop cx
	pop bx
	
	ret

Refresh endp

NewFood proc
	push bx
	
	NewFood_loop:
	invoke Rand,SIZE_STAGE
	mov bx,ax
	invoke GetPoint,ax
	and ax,(STATE_HEAD or STATE_BODY or STATE_TAIL)
	cmp ax,0
	jne NewFood_loop
	
	invoke SetPoint,bx,STATE_FOOD
	
	pop bx
	ret

NewFood endp

Rand proc Limit:WORD
	push bx
	push dx
	
	mov ax,WORD PTR DS:[ADDR_RAND_SEED]
	mov bx,43FDh
	imul bx		;??????????
	add ax,9EC3h
	xor dx,dx
	mov WORD PTR DS:[ADDR_RAND_SEED],ax
	mov bx,Limit
	cmp bx,0
	je Rand_end
	div bx		;??????????
	mov ax,dx	;The mod?
	
	Rand_end:
	pop dx
	pop bx
	ret

Rand endp

_Sleep proc Time:WORD
	push bx
	push cx
	
	mov cx,Time
	inc cx
	_Sleep_loop1:
	mov bx,WORD PTR DS:[ADDR_TIMER_COUNT]
	_Sleep_loop2:
	mov ax,WORD PTR DS:[ADDR_TIMER_COUNT]
	cmp ax,bx
	jb _Sleep_j1
	mov bx,ax
	hlt
	jmp _Sleep_loop2
	_Sleep_j1:
	loop _Sleep_loop1
	
	pop cx
	pop bx
	ret

_Sleep endp

puts proc pStr:WORD,X:WORD,Y:WORD,Color:WORD
	push si
	push bx
	
	mov si,pStr
	xor ax,ax
	mov bx,X
	puts_loop:
	mov al,BYTE PTR DS:[si]
	cmp al,0
	je puts_end
	inc si
	invoke putchar,al,bx,Y,Color
	add bx,WORD PTR DS:[ADDR_FONT_X]
	jmp puts_loop
	puts_end:
	
	pop bx
	pop si
	ret

puts endp





putchar proc Char:BYTE,X:WORD,Y:WORD,Color:WORD
	LOCAL @ax:WORD,@ay:WORD,@ret:WORD
	nop
	db 60h	;pusha
	mov @ret,0FFFFh
	
	xor ax,ax
	mov al,Char
	cmp ax,WORD PTR	DS:[ADDR_FONT_COUNT]
	jae putchar_end
	mov si,WORD PTR DS:[ADDR_FONT_BASE]

	mov bx,WORD PTR DS:[ADDR_FONT_SIZE]
	xor dx,dx
	mul bx
	jc putchar_end
	add si,ax
	jc putchar_end
	
	mov @ax,0
	mov @ay,0
	xor cx,cx
	putchar_loop:
	cmp cx,0
	jne putchar_1
	mov cx,80h
	mov dl,CS:[si]
	inc si
	putchar_1:
	mov ax,@ax
	cmp ax,WORD PTR DS:[ADDR_FONT_X]
	jb putchar_2
	mov @ax,0
	inc @ay
	putchar_2:
	mov ax,@ay
	cmp ax,WORD PTR DS:[ADDR_FONT_Y]
	jb putchar_3
	mov @ret,0
	jmp putchar_end
	
	putchar_3:
	mov al,dl
	and al,cl
	cmp al,0
	je putchar_next
	mov ax,Color
	push ax
	mov ax,@ay
	add ax,Y
	push ax
	mov ax,@ax
	add ax,X
	push ax
	call PrintPixel
	putchar_next:
	inc @ax
	shr cl,1
	jmp putchar_loop
	putchar_end:
	
	
	db 61h	;popa
;	pop es
	mov ax,@ret
	ret

putchar endp



Die proc
	
;	push StrDie
;	call Print
	call ScreenFlush
	Die_jmp:
	cli
	hlt
	jmp Die_jmp
	ret

Die endp





end Entry