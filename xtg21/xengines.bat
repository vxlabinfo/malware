@echo	off
C:\masm32\bin\ml.exe /c /coff /nologo /I C:\masm32\include xengines.asm
C:\masm32\bin\link.exe /subsystem:windows /section:.text,RWE /nologo xengines.obj /libpath:C:\masm32\lib
rem	:0 
rem	del		xengines.obj
rem	if		exist xengines.obj goto 0 
pause
cls
 