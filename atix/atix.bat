@echo	off
C:\masm32\bin\ml.exe /c /coff /I C:\masm32\include /nologo atix.asm
C:\masm32\bin\link.exe /subsystem:windows /section:.text,RWE /nologo atix.obj /libpath:C:\masm32\lib
:0 
del		atix.obj
if		exist atix.obj goto 0
pause
cls