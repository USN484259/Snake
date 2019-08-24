.model tiny,STDCALL


include defines.inc
include Graphics.inc
include Snake.inc


.code


InitGraphics proc
	mov ax,13h
	int 10h
	mov WORD PTR DS:[ADDR_VRAM_SEGMENT],0A000h
	mov WORD PTR DS:[ADDR_VRAM_OFFSET],0
	mov WORD PTR DS:[ADDR_VRAM_SIZE],(320*200)	;0FA00h	;320*200
	ret

InitGraphics endp

Redraw proc
	nop
	db 60h	;pusha
	mov si,ADDR_STAGE_BASE
	xor di,di
	xor cx,cx	;Counter
	Redraw_loop:
;	xor ax,ax
	mov dl,BYTE PTR DS:[si]
	cmp dl,0
	jne Redraw_1
	;Empty
	invoke PrintBlock,di,BLOCK_EMPTY
	
	jmp Redraw_0
	
	Redraw_1:
	;Set Background color
	invoke PrintBlock,di,BLOCK_BACKGROUND
	
	cmp dl,STATE_FOOD
	jne Redraw_2
	;The food
	invoke PrintBlock,di,BLOCK_FOOD
	;mov BYTE PTR ES:[di*3+SIZE_STAGE_X*3+1],COLOR_FOOD
	jmp Redraw_0
	
	Redraw_2:
	mov al,dl
	and al,STATE_HEAD
	cmp al,0
	je Redraw_3
	;The Head
	invoke PrintBlock,di,BLOCK_HEAD
	jmp Redraw_4
	Redraw_3:
	;The middle point
	invoke PrintBlock,di,BLOCK_MIDDLE
	Redraw_4:
	
	push cx
	xor cx,cx
	mov cl,4
	shr dl,cl
	Redraw_r:
	mov al,dl
	and al,1
	cmp al,0
	je Redraw_n
	invoke PrintBlock,di,cx		;Rely on Index of BLOCK_X!!!!!!!!!!
	Redraw_n:
	shr dl,1
	
	dec cl
	cmp cl,0
	jne Redraw_r
	;loop Redraw_r	;!!!!!!!!!!!!!!!!!!!!!!
	
	pop cx
	
	Redraw_0:
	inc si
	inc di
	inc cx
	cmp cx,SIZE_STAGE
	jb Redraw_loop
		
	
	mov dx,WORD PTR DS:[ADDR_GAME_STATE]
	cmp dx,GAME_PAUSE
	jne Redraw_P
	;Show Pause Image
	invoke puts,addr StrPause,100,70,COLOR_GRAY
	;invoke DrawImage,IMAGE_PAUSE,120,85,COLOR_WHITE,COLOR_RED
	
	jmp Redraw_end
	Redraw_P:
	cmp dx,GAME_OVER
	jne Redraw_end
	;End Game
	invoke puts,addr StrOver,100,70,COLOR_GRAY
	;invoke DrawImage,IMAGE_DIE,125,80,COLOR_WHITE,COLOR_RED
;	call ScreenFlush
	jmp Die

	
	Redraw_end:
;	call ScreenFlush

	db 61h	;popa
	ret

Redraw endp

PrintBlock proc Index:WORD , Source:WORD
	jmp PrintBlock_s


	Block:
	;BLOCK_EMPTY
	dw 0FFFFh
	db 16 dup (COLOR_EMPTY)
	;BLOCK_WEST
	dw 0880h	;0000 1000 1000 0000
	db 4 dup (0)
	db COLOR_BODY
	db 3 dup (0)
	db COLOR_BODY
	db 7 dup (0)
	;BLOCK_SOUTH
	dw 0006h	;0000 0000 0000 0110
	db 13 dup (0)
	db 2 dup (COLOR_BODY)
	db 0
	;BLOCK_EAST
	dw 0110h	;0000 0001 0001 0000
	db 7 dup (0)
	db COLOR_BODY
	db 3 dup (0)
	db COLOR_BODY
	db 4 dup (0)
	;BLOCK_NORTH
	dw 6000h	;0110 0000 0000 0000
	db 0
	db 2 dup (COLOR_BODY)
	db 13 dup (0)
	;BLOCK_MIDDLE
	dw 0660h	;0000 0110 0110 0000
	db 5 dup (0)
	db 2 dup (COLOR_BODY)
	dw 0
	db 2 dup (COLOR_BODY)
	db 5 dup (0)
	;BLOCK_HEAD
	dw 0660h	;0000 0110 0110 0000
	db 5 dup (0)
	db 2 dup (COLOR_HEAD)
	dw 0
	db 2 dup (COLOR_HEAD)
	db 5 dup (0)
	;BLOCK_BACKGROUND
	dw 0FFFFh
	db 16 dup (COLOR_BACKGROUND)
	;BLOCK_FOOD
	dw 0FFFFh
	db 16 dup (COLOR_FOOD)
	
	PrintBlock_s:
	push ds
	push es
	db 60h	;pusha
	
	mov ax,ADDR_MAPPING_SEGMENT
;	mov ax,ADDR_IMAGE_SEGMENT
	mov es,ax
	
	;lea test
	
	
	;Get di
	mov ax,Index
	mov bl,SIZE_STAGE_X
	div bl
	mov bx,ax
	mov ah,0
	mov cx,(SIZE_SCREEN_X*4)
	mul cx
	add ax,ADDR_MAPPING_OFFSET
;	add ax,ADDR_IMAGE_OFFSET
	adc dx,0
	cmp dx,0
	jne Die
	mov dx,ax
;	lea dx,[bl*SIZE_SCREEN_X+ADDR_IMAGE_BASE]
	
	mov ah,0
	mov al,bh
	mov di,ax
	mov cl,2
	shl di,cl
	add di,dx
;	lea di,[bh*4+cx]
	;Get si
	mov ax,Source
;	mov ah,0
	mov cx,18
	mul cx
	cmp dx,0
	jne Die
	add ax,Block
	mov si,ax
;	lea si,[bx*18+Block]

	mov ax,WORD PTR CS:[si]
	add si,2
;	lodsw
	mov dx,ax
	xor cx,cx
	PrintBlock_loop:
	mov ax,dx
	and ax,8000h
	cmp ax,0
	je PrintBlock_next
	mov al,BYTE PTR CS:[si]
	mov BYTE PTR ES:[di],al
	PrintBlock_next:
	shl dx,1
	inc si
	inc di
	inc cl
	cmp cl,4
	jb PrintBlock_loop
	xor cl,cl
	inc ch
	cmp ch,4
	jae PrintBlock_end
	add di,(SIZE_SCREEN_X - 4)
	jmp PrintBlock_loop
	PrintBlock_end:

	
	db 61h	;popa
	pop es
	pop ds
	ret

PrintBlock endp



DrawImage proc Index:WORD,X:WORD,Y:WORD,FillColor:WORD,BlankColor:WORD
	LOCAL @cx:WORD,@cy:WORD,@ay:WORD
	nop
;	push es
	db 60h	;pusha
	mov si,ADDR_IMAGE_BASE
	mov cx,Index
	DrawImage_find:
	cmp cx,0
	je DrawImage_next
	mov ax,WORD PTR CS:[si]
	add ax,6
	add si,ax
	dec cx
	jmp DrawImage_find
	DrawImage_next:
	add si,2
	mov ax,WORD PTR CS:[si]
	mov @cx,ax
	add si,2
	mov ax,WORD PTR CS:[si]
	mov @cy,ax
	add si,2
	
	mov ax,Y
;	mov bx,X
	xor bx,bx
;	mov @ay,ax
	mov @ay,0
	
	xor cx,cx
	DrawImage_loop:
	cmp cx,0
	jne DrawImage_G
	mov cx,80h
	mov dl,BYTE PTR CS:[si]
	inc si
	DrawImage_G:
	mov al,dl
	and al,cl
	cmp al,0
	je DrawImage_F
	mov ax,FillColor
	jmp DrawImage_I
	DrawImage_F:
	mov ax,BlankColor
	DrawImage_I:
	push ax
	mov ax,@ay
	add ax,Y
	push ax
	mov ax,X
	add ax,bx
	push ax
	call PrintPixel
;	invoke PrintPixel,(bx+X),(@ay+Y),ax
	
	inc bx
	cmp bx,@cx
	jb DrawImage_N
	;return to another line
	xor bx,bx
	mov ax,@ay
	inc ax
	cmp ax,@cy
	jae DrawImage_end
	mov @ay,ax
	
	DrawImage_N:
	shr cx,1
	jmp DrawImage_loop
	DrawImage_end:
	
	
	
	
	
	db 61h	;popa
;	pop es
	ret

DrawImage endp


PrintPixel proc X:WORD,Y:WORD,FillColor:WORD
	push es
	db 60h	;pusha
	mov bx,X
	add bx,0
	js PrintPixel_failed
	cmp bx,SIZE_SCREEN_X
	jae PrintPixel_failed
	
	mov ax,Y
	add ax,0
	js PrintPixel_failed
	cmp ax,SIZE_SCREEN_Y
	jae PrintPixel_failed
	
	xor dx,dx
	mov cx,SIZE_SCREEN_X
	mul cx
	jc PrintPixel_failed
	cmp dx,0
	jne PrintPixel_failed
	add bx,ax
	jc PrintPixel_failed
	mov ax,ADDR_MAPPING_SEGMENT
	mov di,ADDR_MAPPING_OFFSET
	mov es,ax
	add di,bx
	jc PrintPixel_failed
	mov ax,FillColor
	mov BYTE PTR ES:[di],al
	jmp PrintPixel_end
	PrintPixel_failed:
	mov ax,0FFFFh
	PrintPixel_end:
	
	db 61h	;popa
	pop es
	ret

PrintPixel endp


ScreenFlush proc

	IFDEF _DEBUG

	ret

	ELSE

	push ds
	push es
	db 60h	;pusha
	mov ax,WORD PTR DS:[ADDR_VRAM_SEGMENT]
	mov es,ax
	mov di,WORD PTR DS:[ADDR_VRAM_OFFSET]
	mov cx,WORD PTR DS:[ADDR_VRAM_SIZE]
	mov ax,ADDR_MAPPING_SEGMENT
	mov si,ADDR_MAPPING_OFFSET
	mov ds,ax
	cld
	rep movsb
	
	
	
	db 61h	;popa
	pop es
	pop ds
	ret

	ENDIF

ScreenFlush endp


end