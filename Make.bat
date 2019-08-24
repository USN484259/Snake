@color 2f
ml /c snake.asm
@echo Press any key to continue...
@pause > nul
@cls
ml /c point.asm
@echo Press any key to continue...
@pause > nul
@cls
ml /c graphics.asm
@echo Press any key to continue...
@pause > nul
@cls
ml /c buffer.asm
@echo Press any key to continue...
@pause > nul
@cls
link16 /tiny snake.obj point.obj graphics.obj buffer.obj < CR.txt
@echo Press any key to continue...
@pause > nul
@cls
copy .\Snake.com C:\Snake.bin
@echo Press any key to continue...
@pause > nul
@cls
@exit