.model tiny,STDCALL


DATA_C equ (_Start-0Eh)
DATA_H equ (_Start-0Ch)
DATA_S equ (_Start-0Ah)
DATA_BPS equ (_Start-08h)
DATA_SIZE equ (_Start-06h)
DATA_CS equ (_Start-04h)
DATA_IP equ (_Start-02h)


.code

org 7c00h

Entry:
jmp _Start

dw 7 dup (?)

;	C	H	S	BPS	SIZE	CS	IP
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
mov ax,WORD PTR CS:[DATA_CS]	;CS
push ax
mov ax,WORD PTR CS:[DATA_IP]	;IP
push ax

retf


LoadOs proc
LOCAL @C:WORD , @H:WORD , @S:WORD , @Size:WORD



nop


db 60h	;pusha

mov ax,WORD PTR CS:[DATA_CS]	;CS
mov es,ax
mov bx,WORD PTR CS:[DATA_IP]	;IP

;mov cl,4
;shr ax,cl
;mov es,ax	;base address
;xor bx,bx


;	C	H	S	Size
;	-8	-6	-4	-2

mov @C,0
mov @H,0
mov @S,2
mov @Size,0
;mov WORD PTR DS:[bp-8],0
;mov WORD PTR DS:[bp-6],0
;mov WORD PTR DS:[bp-4],2
;mov WORD PTR DS:[bp-2],0

Read_Loop:

mov ax,@S
;mov ax,WORD PTR DS:[bp-4]	;S
cmp ax,WORD PTR CS:[DATA_S]
jbe LoadOs_1
;Above
inc @H
;inc WORD PTR DS:[bp-6]
;mov WORD PTR DS:[bp-4],1
mov @S,1

LoadOs_1:


mov ax,@H
;mov ax,WORD PTR DS:[bp-6]	;H
cmp ax,WORD PTR CS:[DATA_H]
jb LoadOs_2
;Above or Equal

inc @C
;inc WORD PTR DS:[bp-8]
mov @H,0
;mov WORD PTR DS:[bp-6],0

LoadOs_2:

mov ax,@C
;mov ax,WORD PTR DS:[bp-8]
cmp ax,WORD PTR CS:[DATA_C]	;C
jae die

;Start Reading disk



mov ax,@H
xchg ah,al
mov bl,al
mov ch,ah

;mov ch,BYTE PTR DS:[bp-6]
;mov bl,BYTE PTR DS:[bp-5]
mov cl,5
shl bl,cl
mov cl,bl

mov ax,@S
or cl,al
;or cl,BYTE PTR DS:[bp-4]
mov ax,@C
mov dh,al
;mov dh,BYTE PTR DS:[bp-8]
;xor bx,bx

mov bx,WORD PTR CS:[DATA_IP]	;IP

mov al,1
mov ah,2


int 13h
jc die

mov bx,@Size
mov ax,WORD PTR CS:[DATA_BPS]
add bx,ax
cmp bx,WORD PTR CS:[DATA_SIZE]
jae Read_end
mov @Size,bx

add @S,ax
;add WORD PTR DS:[bp-2],ax

mov bx,dx	;Rely on ax above !!!!!
mov dx,32	;512/16
mul dx
cmp dx,0
jne Die
mov cx,es
add cx,ax
jc Die	;?????????
mov es,cx

mov dx,bx

jmp Read_Loop
Read_end:
;ax equals Amount has loaded
push bx		;Rely on bx above !!!!!
call PrintHex
mov ax,StrCount
push ax
call Puts

db 61h	;popa

ret

LoadOs endp

PrintHex:
push bp
mov bp,sp
mov ax,WORD PTR SS:[bp+4]	;Argu_1
push dx
push cx
push bx

mov dx,ax
mov cl,10h
_PrintHex_loop:
sub cl,4
mov ax,dx
shr ax,cl
and ax,000fh
cmp al,9
jbe _PrintHex_j1
add al,'A'-0Ah
jmp _PrintHex_j2
_PrintHex_j1:
add al,'0'
_PrintHex_j2:

call putchar

cmp cl,0
jne _PrintHex_loop

pop bx
pop cx
pop dx
pop bp

retn 2

putchar:
mov ah,0Eh
xor bx,bx
int 10h
ret


Puts:
push bp
mov bp,sp
mov ax,WORD PTR SS:[bp+4]	;Argu_1
push bx
push si
mov si,ax
Puts_loop:
mov al,BYTE PTR DS:[si]
cmp al,0
je Puts_end

call putchar

inc si
jmp Puts_loop
Puts_end:
pop si
pop bx
pop bp
retn 2


StrCount:
db '  Sections loaded',0dh,0ah,0

end Entry