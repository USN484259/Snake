IFNDEF Point_Inc
Point_Inc equ <1>


GetPoint proto Index:WORD

SetPoint proto Index:WORD,State:BYTE

GetNextHead proto Direction:BYTE

GetIndex proto Current:WORD,Direction:BYTE

DirToState proto Direction:BYTE

StateToDir proto State:BYTE





























ENDIF