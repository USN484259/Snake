IFNDEF Snake_Inc
Snake_Inc equ <1>




;OS functions
Entry proto
InitOS proto
InitInt proto
InitRand proto

Int20_Proc proto

IO_out8 proto Port:WORD,Data:BYTE

Rand proto Limit:WORD

Refresh proto Key:WORD

NewFood proto

Die proto

_Sleep proto Time:WORD

puts proto pStr:WORD,X:WORD,Y:WORD,Color:WORD


putchar proto Char:BYTE,X:WORD,Y:WORD,Color:WORD


GetKey proto

InitFont proto


ENDIF