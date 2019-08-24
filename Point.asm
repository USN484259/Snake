.model tiny,STDCALL


include Defines.inc
include Point.inc
include Snake.inc

.code


GetPoint proc Index:WORD
	push bx
	
	cmp Index,SIZE_STAGE
	jae GetPoint_Failed
	
	mov bx,ADDR_STAGE_BASE
	add bx,Index
	mov al,BYTE PTR DS:[bx]
	xor ah,ah
	
	jmp GetPoint_end
	GetPoint_Failed:
	mov ax,0ffffh
	GetPoint_end:
	pop bx
	ret

GetPoint endp

SetPoint proc Index:WORD,Data:BYTE
	
	push bx
	
	cmp Index,SIZE_STAGE
	jae SetPoint_Failed
	
	mov bx,ADDR_STAGE_BASE
	add bx,Index
	
	mov al,Data
	mov BYTE PTR DS:[bx],al
	
	
	jmp SetPoint_end
	SetPoint_Failed:
	mov ax,0ffffh
	SetPoint_end:
	
	pop bx
	ret

SetPoint endp


DirToState proc Direction:BYTE
	push cx
	xor ax,ax
	
	mov cl,Direction
	and cl,3
	mov al,10h
	shl al,cl
	
	pop cx
	ret

DirToState endp



StateToDir proc State:BYTE
	push cx
	push dx
	
	mov dl,State
	and dl,0F0h
	jp StateToDir_Failed
	mov ax,3
	StateToDir_loop:
	
	mov cl,dl
	and cl,80h
	cmp cl,0
	jne StateToDir_end
	cmp ax,0
	je StateToDir_Failed
	dec ax
	shl dl,1
	jmp StateToDir_loop
	
	
	StateToDir_Failed:
	mov ax,0ffffh
	StateToDir_end:
	pop dx
	pop cx
	ret

StateToDir endp



GetIndex proc Current:WORD,Direction:BYTE
	push dx
	push cx
	push bx
	xor cx,cx
	
	mov bx,Current
	cmp bx,SIZE_STAGE
	jae GetIndex_Failed
	
	mov cl,Direction
	mov al,cl
	and al,1
	cmp al,0
	jne GetIndex_j1
	;North or South
	cmp cl,0
	jne GetIndex_South
	;North
	cmp bx,SIZE_STAGE_X
	jb GetIndex_Failed
	sub bx,SIZE_STAGE_X
	mov ax,bx
	jmp GetIndex_end
	
	GetIndex_South:
	add bx,SIZE_STAGE_X
	cmp bx,SIZE_STAGE
	jae GetIndex_Failed
	mov ax,bx
	jmp GetIndex_end
	
	GetIndex_j1:
	;West or East
	and cl,2
	cmp cl,0
	jne GetIndex_West
	;East
	mov ax,bx
	mov cl,SIZE_STAGE_X
	xor dx,dx
	div cl
	cmp ah,(SIZE_STAGE_X-1)		;mod
	jae GetIndex_Failed
	inc bx
	mov ax,bx
	jmp GetIndex_end
	
	GetIndex_West:
	mov ax,bx
	mov cl,SIZE_STAGE_X
	xor dx,dx
	div cl
	cmp ah,0		;mod
	je GetIndex_Failed
	dec bx
	mov ax,bx
	jmp GetIndex_end
	
	GetIndex_Failed:
	mov ax,0ffffh
	GetIndex_end:
	pop bx
	pop cx
	pop dx
	ret

GetIndex endp



GetNextHead proc Direction:BYTE
	LOCAL @ret:WORD
	;Get the New head Index
	;if reach the edge try to find the better movement
	;just return the Index of the next head
	;It's caller who should judge if game is over
	nop
	db 60h	;pusha
		
	xor cx,cx
	mov dx,WORD PTR DS:[ADDR_CURRENT_HEAD]
	mov cl,Direction
	invoke GetIndex,dx,cl
	mov bx,ax
	cmp ax,0FFFFh
	jne GetNextHead_end
	;Reach the edge,try to turn
	invoke Rand,0
	xor ax,0	;Get Flags
	jp GetNextHead_R
	add cl,2	;+2+1 = -1
	mov ch,1	;means turning left
	GetNextHead_R:
	inc cl
	and cl,3
	invoke GetIndex,dx,cl
	mov bx,ax
	cmp ax,0FFFFh
	je GetNextHead_E	;Have to turn to another direction
	
	invoke GetPoint,ax
	and ax,(STATE_HEAD or STATE_BODY or STATE_TAIL)
	cmp ax,0	;if there's the body on the way when forced to turn,try another direction
	je GetNextHead_end
	GetNextHead_E:
	;Get another direction
	mov cl,Direction
	cmp ch,0	;right,and now turn left
	jne GetNextHead_1
	add cl,2	;turning left
	GetNextHead_1:
	inc cl		;left,and now turn right
	and cl,3
	invoke GetIndex,dx,cl
	mov bx,ax
	cmp ax,0FFFFh
	jne GetNextHead_end
	jmp Die
	GetNextHead_end:
	mov BYTE PTR DS:[ADDR_DIRECTION],cl
	mov @ret,bx
	
	db 61h	;popa
	mov ax,@ret
	ret

GetNextHead endp










end