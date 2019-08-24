.model tiny,STDCALL

.code

org 7c00h

Entry:
jmp _Start

dw 6 dup (?)

;	C	H	S	BPS	SIZE	BASE
;	ax	di	si	dx	cx	bx
_Start:

xor ax,ax
mov cx,ax
mov ss,ax
mov sp,7c00h
mov ds,ax
mov es,ax
mov bp,ax
mov di,ax



call LoadOs

call StartOs
;int 19h
die:
cli
hlt
jmp die



StartOs:
pop ax
mov ax,WORD PTR CS:[_Start-2]	;base
push ax

ret


LoadOs:
db 60h	;pusha
mov bp,sp
sub sp,0Ah
mov ax,WORD PTR CS:[_Start-2]
mov cl,4
shr ax,cl
mov es,ax	;base address
xor bx,bx

;	C	H	S	Size
;	-8	-6	-4	-2
mov WORD PTR DS:[bp-8],0
mov WORD PTR DS:[bp-6],0
mov WORD PTR DS:[bp-4],0
mov WORD PTR DS:[bp-2],2

Read_Loop:
mov ax,WORD PTR DS:[bp-2]	;Size
cmp ax,WORD PTR CS:[_Start-4]	;Size
jae Read_end
add ax,WORD PTR CS:[_Start-6]	;Count
mov WORD PTR DS:[bp-2],ax

mov ax,WORD PTR DS:[bp-4]	;S
cmp ax,WORD PTR CS:[_Start-8]
jbe LoadOs_1
;Above
inc WORD PTR DS:[bp-6]
mov WORD PTR DS:[bp-4],1

LoadOs_1:

mov ax,WORD PTR DS:[bp-6]	;H
cmp ax,WORD PTR CS:[_Start-0Ah]
jb LoadOs_2
;Above or Equal
inc WORD PTR DS:[bp-8]
mov WORD PTR DS:[bp-6],0
LoadOs_2:
mov ax,WORD PTR DS:[bp-8]
cmp ax,WORD PTR CS:[_Start-0Ch]	;C
jae die

;Start Reading disk

mov al,1
mov ah,2
mov ch,BYTE PTR DS:[bp-6]
mov bl,BYTE PTR DS:[bp-5]
mov cl,5
shl bl,cl
mov cl,bl
or cl,BYTE PTR DS:[bp-4]
mov dh,BYTE PTR DS:[bp-8]
xor bx,bx
int 13h
jc die

mov ax,WORD PTR CS:[_Start-6]
add WORD PTR DS:[bp-2],ax
mov bx,WORD PTR CS:[_Start-6]
mov cl,4
shl bx,cl
mov ax,es
add ax,bx
mov es,ax

jmp Read_Loop
Read_end:
add sp,0Ah
db 61h	;popa

ret








end Entry