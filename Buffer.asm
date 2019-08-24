.model tiny,STDCALL


include defines.inc
include Buffer.inc

.code

InitBuf proc
	push es
	push cx
	
	xor ax,ax
	mov di,ADDR_BUFFER_BASE
	mov es,ax
	mov cx,SIZE_BUFFER
	cld
	rep stosb
	mov BYTE PTR DS:[ADDR_BUFFER_READ],0
	mov BYTE PTR DS:[ADDR_BUFFER_WRITE],0
	
	pop cx
	pop es
	ret

InitBuf endp

BufAdd proc Data:BYTE
	push bx
	push dx
	invoke BufCount
	cmp ax,(SIZE_BUFFER-2)
	jb BufAdd_C
	mov ax,0FFFFh
	jmp BufAdd_end
	BufAdd_C:
	mov bx,ADDR_BUFFER_BASE
	xor ax,ax
	mov al,BYTE PTR DS:[ADDR_BUFFER_WRITE]
	add bx,ax
	mov dl,Data
	mov BYTE PTR DS:[bx],dl
	inc ax
	xor dx,dx
	mov bl,SIZE_BUFFER
	div bl
	mov BYTE PTR DS:[ADDR_BUFFER_WRITE],ah
	BufAdd_end:
	pop dx
	pop bx
	ret

BufAdd endp

BufGet proc
	LOCAL @ret:WORD
	push bx
	push dx
	invoke BufCount
	cmp ax,0
	je BufGet_end
	mov bx,ADDR_BUFFER_BASE
	xor ax,ax
	mov al,BYTE PTR DS:[ADDR_BUFFER_READ]
	add bx,ax
	xor dx,dx
	mov dl,BYTE PTR DS:[bx]
	mov @ret,dx
;	add ax,SIZE_BUFFER
	inc ax
	xor dx,dx
	mov bl,SIZE_BUFFER
	div bl
	mov BYTE PTR DS:[ADDR_BUFFER_READ],ah
	mov ax,@ret
	BufGet_end:
	
	pop dx
	pop bx
	ret

BufGet endp

BufCount proc
	push bx
	push dx
	
	xor dx,dx
	xor ax,ax
	mov al,BYTE PTR DS:[ADDR_BUFFER_WRITE]
	add al,SIZE_BUFFER
	sub al,BYTE PTR DS:[ADDR_BUFFER_READ]
	xor bx,bx
	mov bl,SIZE_BUFFER
	div bl
	xchg ah,al
	mov ah,0
	
	
	
	pop dx
	pop bx
	ret

BufCount endp



end