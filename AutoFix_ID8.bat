@echo off
title IDAS AMD fix cmd bat By AsukaXVB
echo Press any key to start...
pause 
goto initial_check

:ID8
echo Re-dating files...
TIMEOUT /T 2
cd .\data\V5SHADER\
copy *.asm_gl +..
cd ..
cd ..
CLS
echo Done!!
pause
goto done

:initial_check
if exist InitialD8_GLW_RE_SBZZ.exe goto ID8
echo Game's not found!!  please put this fix files to the game root folder.
pause

:done
echo Auto fix by AsukaXVB#4732@Discord.
pause