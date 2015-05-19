;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;																										 ;
;                                                            											 ;
;																										 ;
;                                       																 ;
;                                     xxxxxxxxxxxxxxxxxxxxxxxxxx      xxxxxxxxxxxxxxxxxxx				 ;
;                                     xxxxxxxxxxxxxxxxxxxxxxxxxx     xxxxxxxxxxxxxxxxxxxx     			 ;
;                                     xxxxxxxxxxxxxxxxxxxxxxxxxx    xxxxxxxxxxxxxxxxxxxxx      			 ;
;        x                         x  xxxxxxxxxxxxxxxxxxxxxxxxxx   xxxxxxxxxxxxxxxxxxxxxx				 ;
;        xxx                     xxx           xxxxxxxx           xxxxxxx		  xxxxxxx      			 ; 
;        xxxxx                 xxxxx           xxxxxxxx           xxxxxxx								 ;
;        xxxxxxx             xxxxxxx           xxxxxxxx           xxxxxxx								 ;
;        xxxxxxxxx         xxxxxxxxx           xxxxxxxx           xxxxxxx								 ;
;         xxxxxxxxxx     xxxxxxxxxx            xxxxxxxx           xxxxxxx								 ;
;           xxxxxxxxxx xxxxxxxxxx              xxxxxxxx           xxxxxxx								 ;
;             xxxxxxxxxxxxxxxxx                xxxxxxxx           xxxxxxx								 ;
;               xxxxxxxxxxxxx                  xxxxxxxx           xxxxxxx       xxxxxxxxx				 ;
;                xxxxxxxxxxx                   xxxxxxxx           xxxxxxx       xxxxxxxxx				 ;
;              xx  xxxxxxx  xx                 xxxxxxxx           xxxxxxx       xxxxxxxxx				 ;
;             xxxx  xxxxx  xxxx                xxxxxxxx           xxxxxxx         xxxxxxx				 ;
;            xxxxxx   x   xxxxxx               xxxxxxxx           xxxxxxx         xxxxxxx				 ;
;           xxxxxxxx     xxxxxxxx              xxxxxxxx            xxxxxxxxxxxxxxxxxxxxxx 				 ;
;          xxxxxxxx       xxxxxxxx             xxxxxxxx             xxxxxxxxxxxxxxxxxxxxx 				 ;
;         xxxxxxxx         xxxxxxxx            xxxxxxxx              xxxxxxxxxxxxxxxxxxxx 				 ;
;        xxxxxxxx           xxxxxxxx           xxxxxxxx               xxxxxxxxxxxxxxxxxxx				 ;
;																										 ;
;																										 ;
;																										 ;
;																										 ;
;																										 ; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;							eXperimental/eXtended/eXecutable Trash Generator							 ;
;												  xTG													 ;
;												xtg.inc													 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;																										 ;
;												  xD													 ;
;																										 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;Заголовочный файл xtg.inc (для xtg.asm, logic.asm, faka.asm); 											 ;
;здесь общие значения; частные значения смотри в функе, реализующей необходимые задачи; 				 ;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
;v2.1.1


																		;m1x
																		;pr0mix@mail.ru
																		;EOF



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;основные значения/константы 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
NUM_INSTR				equ		47 										;количество (кол-во) доступных конструкций в данном моторе; 
MAX_STAT				equ		1001									;
MAX_SIZE_INSTR			equ		1001 									;max размер инструкции для сравнения (можно вписать сюда хоть 10000h, похеру xD); 
																		;юзается для вычисления минимального размера доступной для генерации команды (смотрив сорцы etc); 
NUM_HASH				equ		77										;кол-во хэшей (от имён винапишек); 
WINAPI_MAX_SIZE			equ		(06 + 10 * 10 + 01)						;max размер винапи-конструкции: вызов винапи (6 байт) + передаваемые параметры (10 штук * 10 байт (размер одной штуки)); 

size_of_stack_commit	equ		5000h									;объём виртуальной памяти, выделяемой под стек (позже заменим адрес стека в esp на свой адрес в выделенной памяти); 
																		;при необходимости данное значение увеличить; 

;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;основные значения/константы 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;константы, нужные для генерации функций; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
init_local_max_size		equ		10										;инициализация локальной переменной(ых) - максимальный размер; должно быть >= 3; 
max_local_num			equ		10										;максимальное количество локальных переменных; если сделать их больше 31, тогда в движке предусмотреть генерацию и таких перем., т.к. они имеют большую длину команд; 
max_param_num			equ		5										;максимальное кол-во входных параметров; если сделать их больше 31, тогда в движке предусмотреть генерацию и таких перем., т.к. они имеют большую длину команд; 
param_max_size			equ		6										;максимальный размер одного входного параметра (push dword ptr [403008h] = 6 bytes); смотрим в функу gen_param_for_func - если там изменения есть, то и для этого параметра возможно тогда тоже; 
trash_max_size			equ		30										;максимальный размер одной пачки мусора;  должен быть >= 6; 
max_func				equ		10										;максимальное кол-во функций, которые можно сгенерить (= максимальному уровню рекурсии); 
USEFUL_CODE_MAX_SIZE	equ		70										;максимальный размер внедряемого полезного кода (в ситуации с iRPE - это максимальный размер декриптора); 
func_size				equ		(01 + 02 + 06 + init_local_max_size + 02 + 01 + 03 + ((max_func - 01) * 5) + (max_param_num * param_max_size * (max_func - 01)) + trash_max_size + USEFUL_CODE_MAX_SIZE) 
																		;поясним: 
													   					;push ebp - 01;
													   					;mov ebp, esp - 02 bytes;
													   					;sub esp,XXXXXXXXh 
													   					;mov dword ptr [ebp - XXXXXXXXh], XXXXXXXXh - 10 - инициализация хотя бы одной локал. перем; 
													   					;mov esp, ebp - 02; (или leave - 1); но мы берем по max; 
													   					;pop ebp - 1;
													   					;ret XXh - 3;
													   					;call XXXXXXXXh - размер max кол-ва вызовов в функе (max_func - 1) * 5 byte; 
													   					;push 05 etc - (max_param_num * 6 * (max_func - 01)) - максимальное кол-во входных параметров в функу * max размер одного такого параметра * max кол-во вызовов (call'ов); 
													   					;trash - 100; трэшовый код; 
													   					;+ USEFUL_CODE_MAX_SIZE; (возможно, ещё будем внедрять некоторый полезный код)
													   					;func_size - это максимальный размер функции; 

;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;константы, нужные для генерации функций; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;вспомогательные константы; 
;для работы логики; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
vl_vstack_size			equ		5000h									;размер виртуального стэка
vl_vstack_small_size	equ		1000h									;размер дополнительного виртуального стека
vl_regs_states			equ		100										;кол-во возможных состояний для каждого виртуального рега
vl_lv_num				equ		32										;кол-во проверяемых локальных переменных 
vl_lv_states			equ		50										;кол-во возможных состояний для каждого локал-вара =)
vl_instr_buf_size		equ		(MAX_SIZE_INSTR + 1000h)				;размер буфера для запуска команды (там еще будем копировать некоторые другие спец. фичи); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;вспомогательные константы; 
;для работы логики; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;структуры для движка xTG;
;+ их описуха;
;XTG_TRASH_GEN				-	основная структура, её адрес передаётся движку xTG для генерации трэша; ([0] - in_param, [1] - out_param); 
;XTG_EXT_TRASH_GEN			-	вспомогательная структура, подразумевается хранение в ней различной инфы 
;XTG_FUNC_STRUCT			-	структурка, которая нужна для/при генерации функций (с прологами, 
;								эпилогами etc); 
;XTG_DATA_STRUCT			-	структура, поля которой содержат адреса и размеры областей памяти, 
;								нужных для генерации трэш-кода и трэш-данных;
;FAKA_FAKEAPI_GEN			-	структура, основная для движка FAKA;
;XTG_LOGIC_STRUCT			-	структура, адрес на которую передается (в EAX) после инициализации let_init (LET технология);
;								структура после инициализации заполнена нужными значениями;
;								структурa содержит адреса памяти, необходимые для работы фунок проверки/построения логики трэш-кода (let); 
;XTG_INSTR_DATA_STRUCT		-	структура, которая заполняется движком xTG, и адрес этой структы передаётся 
;								для функи let_main;
;								тут в поля вбиваем адрес команды для проверки логики, размер этой команды и т.п. (смотри сорцы+)! 
;XTG_INSTR_PARS_STRUCT		-	структа, которая заполняется парсером для эмуля и анализатора/корректора логики; 
;								в полях этой структуры указываем, какие параметры содержит разобранная структа, 
;								сколько их, различные флаги etc; 
;XTG_REGS_CURV_STRUCT		-	структура для текущих состояний виртуальных регов и + маски;
;XTG_REGS_STRUCT			-	структа для хранения всех собранных состояний виртуальных регов (для анализатора/корректора логики); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;--------------------------------------------------------------------------------------------------------
XTG_TRASH_GEN				struct
	fmode							dd					?				;[0]; режим генерации трэша: XTG_MASK или XTG_REALISTIC 			
	rang_addr 						dd					?				;[0]; адрес ГСЧ;
	faka_addr						dd					?				;[0]; адрес движка генерации фэйковых винапишек; 
	faka_struct_addr				dd					?				;[0]; адрес структуры FAKA_FAKEAPI_GEN для движка генерации фэйк-апи; 
	xfunc_struct_addr				dd					?				;[0]; адрес структуры XTG_FUNC_STRUCT - если генерируются функи не этим двиглом (xTG), а нужна генерация некоторых команд с участием ebp etc, тогда заполняем данную структуру и передаем её адрес сюда; 
	xdata_struct_addr				dd					?				;[0]; адрес структуры XTG_DATA_STRUCT - если нужна генерации команд, в которых юзается mem32 (address), а также хочется генерить трэш-данные - заполняем такую структурку; 
	xlogic_struct_addr				dd					?				;[0]; адрес структуры XTG_LOGIC_STRUCT; 
	icb_struct_addr					dd					?				;[0]; адрес структуры IRPE_CONTROL_STRUCT; 
	alloc_addr						dd					?				;[0]; адрес функции выделения памяти
	free_addr						dd					?				;[0]; адрес функи освобождения памяти
	tw_trash_addr					dd					?				;[0]; tw - To Write; адрес, куда записывать генерируемое дерьмо
	trash_size						dd					?				;[0]; размер этого дерьма
	xmask1							dd					?				;[0]; 64-битная маска для генерации мусора
	xmask2							dd					?				;[0]; применять в режиме XTG_MASK; 
	fregs							dd					?				;[0]; занятые регистры (реги); 
	nobw							dd					?				;[1]; number of bytes written; кол-во реально записанных байтов (размер реально сгенеренного трэшака); 
	ep_trash_addr					dd					?				;[1]; address of entry point; точка входа в трэш;
	fnw_addr						dd					?				;[1]; address for next write; адрес для дальнейшей записи мусора; 	 
XTG_TRASH_GEN				ends 
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_EXT_TRASH_GEN			struct
	ofs_addr						dd					?				;[0]; opcode frequency statistics
	one_byte_opcode_addr			dd					?				;[0]; адрес таблицы однобайтовых команд; 
	xlogic_struct_addr				dd					?				;[0]; адрес структуры XTG_LOGIC_STRUCT
XTG_EXT_TRASH_GEN			ends
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_FUNC_STRUCT				struct
	func_addr						dd					?				;[0]; adrress of func; адрес функции (адрес, по которому будет или уже сгенерирована функа);
	func_size						dd					?				;[0]; size of func; размер функи (etc); 
	call_num						dd					?				;[0]; numbers of call's in func; кол-во вызовов в функе (кол-во call'ов); 
	local_num						dd					?				;[0]; numbers of local variable in func; кол-во локальных переменных в данной функе; 
	param_num						dd					?				;[0]; numbers of input parameters in func; кол-во входных параметров;
XTG_FUNC_STRUCT				ends 
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_DATA_STRUCT				struct
	xmask							dd					?				;[0]; маска для генерации трэш-данных 
	rdata_addr						dd					?				;[0]; адрес области памяти, в которую будут сгенерированны трэш-данные 
	rdata_size						dd					?				;[0]; размер этой области памяти
	rdata_pva						dd					?				;[0]; какой адрес передаётся в rdata_addr: абсолютный физический в файле или виртуальный в памяти?;
	;wdata_addr						dd					?				;[0]; 
	;wdata_size						dd					?				;[0]; 
	xdata_addr						dd					?				;[0]; адрес области памяти, адреса которой будут учавствовать в генерации трэш-кода (VA); 
	xdata_size						dd					?				;[0]; рзмер этой области памяти;
	;xdata_pva						dd					?				;[0]; 
	nobw							dd					?				;[1]; кол-во реально записанных байтов трэш-данных; 
XTG_DATA_STRUCT				ends
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
FAKA_FAKEAPI_GEN			struct
	mapped_addr						dd					?				;[0]; база мэппинга 
	rang_addr						dd					?				;[0]; адрес ГСЧ
	alloc_addr						dd					?				;[0]; адрес функции выделения памяти
	free_addr						dd					?				;[0]; адрес функции освобождения памяти
	xfunc_struct_addr				dd					?				;[0]; адрес структуры XTG_FUNC_STRUCT - если генерируются функи не этим двиглом (xTG), а нужна генерация некоторых команд с участием ebp etc, тогда заполняем данную структуру и передаем её адрес сюда; 
	xdata_struct_addr				dd					?				;[0]; адрес структуры XTG_DATA_STRUCT - если нужна генерации команд, в которых юзается mem32 (address), а также хочется генерить трэш-данные - заполняем такую структурку; 
	tw_api_addr						dd					?				;[0]; адрес, куда записать сгенерированный фэйковый вызов винапи функции;
	api_size						dd					?				;[0]; max размер винапи-конструкции
	api_hash						dd					?				;[0] [1]; хэш от имени винапи (более подробно обо всех полях всех структур и многое другое читай в доках по движкам); 
	api_va							dd					?				;[1]; VirtualAddress (VA); 
	nobw							dd					? 				;[1]; кол-во реально записанных байт
	fnw_addr						dd					?				;[1]; адрес для дальнейшей записи кода; 
FAKA_FAKEAPI_GEN			ends

;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_LOGIC_STRUCT			struct
	xalloc_buf_addr					dd					?				;[1]; адрес всей выделенной области памяти (а также адрес данной структуры); 
	xalloc_buf_size					dd					?				;[1]; размер этой памяти; 
	flags_addr						dd					?				;[1]; адрес памяти, в которой будут храниться флаги эмулируемого кода (pushfd/popfd); 
	xinstr_data_struct_addr			dd					?				;[1]; адрес структы XTG_INSTR_DATA_STRUCT; данные по команде/конструкции, которую следует проанализировать (возможно и эмулить); 
	xinstr_pars_struct_addr			dd					?				;[1]; адрес структы XTG_INSTR_PARS_STRUCT, содержащую данные о пропарсенной команде; 
	vstack_addr						dd					?				;[1]; адрес выделенной памяти под виртуальный стэк
	vstack_small_addr				dd					?				;[1]; адрес выдел. памяти под дополнительный вирт. стек;
	xregs_curv_struct_addr			dd					?				;[1]; XTG_REGS_STRUCT -> текущие значения виртуальных регов + маски;
	xregs_states_addr				dd					?				;[1]; под состояния регов; 
	xlv_addr						dd					?				;[1]; адреса выбранных локал-перем + маски + число активных л.п.; (их текущие значения лежат в виртуальном стеке); 
	xlv_states_addr					dd					?				;[1]; под состояния локал-варов;
	xdata_addr						dd					?				;[1]; под области памяти; 
	instr_buf_addr					dd					?				;[1]; буфер, в который будет копироваться конструкция для выполнения; 
XTG_LOGIC_STRUCT			ends
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_INSTR_DATA_STRUCT		struct
	instr_addr						dd					?				;[0]; адрес конструкции, которую надо проверить
	instr_size						dd					?				;[0]; её размер		
	flags							dd					?				;[0]; флаги (inc_dec_r32 etc);
	param_1							dd					?				;[0]; тут хранится номер рега, а также возможна установка старшего бита в 1, что означает, что мы генерим команды для конструкции (в рекурсии); 
	norb							dd					?				;[0]; number of remaining bytes -> кол-во оставшихся байтов для записи трэша (нужно для корректной работы проверки); 
XTG_INSTR_DATA_STRUCT		ends
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_INSTR_PARS_STRUCT		struct
	flags							dd					?				;[0]; флаги для анализатора
	param_1							dd					?				;[0]; здесь хранится либо номер регистра либо адрес в памяти (а может еще храниться число?)
	param_2							dd					?				;[0]; здесь хранится либо номер рега, либо адрес в памяти, либо число
	param_3							dd					?				;[0]; а здесь биты соотв-щих регов, принимавших участие в отдаче (give) значений (параметру 1); (бит 0 - eax etc); 
XTG_INSTR_PARS_STRUCT		ends
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_REGS_STRUCT				struct
	x_eax							dd					?				;[0]; значения виртуальных регов (для эмуляции кода); 
	x_ecx							dd					?				;[0]; эта структа предназначена как для хранения текущих значений виртуальных регов, 
	x_edx							dd					?				;[0]; так и для хранения всех полученных состояний эти регов 
	x_ebx							dd					?				;[0]; для этого выделяются разные участки памяти для хранения массивов этой структуры под разные задачи; 
	x_esp							dd					?				;[0]; 
	x_ebp							dd					?				;[0]; 
	x_esi							dd					?				;[0]; 
	x_edi							dd					?				;[0]; 
XTG_REGS_STRUCT				ends
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
XTG_REGS_CURV_STRUCT		struct
	xregs_struct					XTG_REGS_STRUCT		<>				;[0]; адрес структуры XTG_REGS_STRUCT
	regs_init						dd					?				;[0]; проинициализированные реги (от повторной инициализации); 
	regs_used						dd					?				;[0]; реги, которые можно юзать (для отдачи своих значений другим регам etc); 
XTG_REGS_CURV_STRUCT		ends
;--------------------------------------------------------------------------------------------------------
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;структуры для движка xTG;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_TRASH_GEN.fmode (режим генерации трэша); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
XTG_MASK			equ		00000000b									;00h (возможно, что сейчас любое значение != 1 - будет считаться как XTG_MASK); 
XTG_REALISTIC		equ		00000001b									;01h 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_TRASH_GEN.fmode (режим генерации трэша); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_TRASH_GEN.fregs (занятые реги); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
XTG_EAX				equ		00000001b									;01h
XTG_ECX				equ		00000010b									;02h
XTG_EDX				equ		00000100b									;04h
XTG_EBX				equ		00001000b									;08h
XTG_ESP				equ		00010000b									;10h
XTG_EBP				equ		00100000b									;20h
XTG_ESI				equ		01000000b									;40h
XTG_EDI				equ		10000000b									;80h 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_TRASH_GEN.fregs (занятые регистры); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги масок XTG_TRASH_GEN.xmask1 & XTG_TRASH_GEN.xmask2  
;юзаем лучше их (чем цифры, иначе могут получиться привязки - а это хуйня); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

;=====================================[ДЛЯ РЕЖИМА XTG_MASK]==============================================
;----------------------------------------[XMASK1 BEGIN]--------------------------------------------------
XTG_INC_DEC___R32										equ		00000000000000000000000000000001b	;01		;генерация различных инструкций/конструкций; 
XTG_NOT_NEG___R32										equ		00000000000000000000000000000010b	;02
XTG_MOV_XCHG___R32__R32									equ		00000000000000000000000000000100b	;03
XTG_MOV_XCHG___R8__R8_IMM8								equ		00000000000000000000000000001000b 	;04
XTG_MOV_R32_R16__IMM32_IMM16							equ		00000000000000000000000000010000b	;05
XTG_LEA___R32___MSO										equ		00000000000000000000000000100000b	;06
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R32_R16__R32_R16		equ		00000000000000000000000001000000b	;07
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R8__R8					equ		00000000000000000000000010000000b	;08
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R32__IMM32				equ		00000000000000000000000100000000b	;09
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R32__IMM8				equ		00000000000000000000001000000000b	;10
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R8__IMM8				equ		00000000000000000000010000000000b	;11
XTG_RCL_RCR_ROL_ROR_SHL_SHR___R32__IMM8					equ		00000000000000000000100000000000b	;12
XTG_PUSH_POP___R32___R32								equ		00000000000000000001000000000000b	;13
XTG_PUSH_POP___IMM8___R32								equ		00000000000000000010000000000000b	;14
XTG_CMP___R32__R32										equ		00000000000000000100000000000000b	;15
XTG_CMP___R32__IMM8										equ		00000000000000001000000000000000b	;16
XTG_CMP___R32__IMM32									equ		00000000000000010000000000000000b	;17
XTG_TEST___R32_R8__R32_R8								equ		00000000000000100000000000000000b	;18
XTG_JXX_SHORT_DOWN___REL8								equ		00000000000001000000000000000000b	;19
XTG_JXX_NEAR_DOWN___REL32								equ		00000000000010000000000000000000b	;20
XTG_JXX_UP___REL8___REL32								equ		00000000000100000000000000000000b	;21
XTG_JMP_DOWN___REL8___REL32								equ		00000000001000000000000000000000b	;22
XTG_CMOVXX___R32__R32									equ		00000000010000000000000000000000b	;23
XTG_BSWAP___R32											equ		00000000100000000000000000000000b	;24
XTG_THREE_BYTES_INSTR									equ		00000001000000000000000000000000b	;25
XTG_MOV___R32_M32__M32_R32								equ		00000010000000000000000000000000b	;26
XTG_MOV___M32__IMM8_IMM32								equ		00000100000000000000000000000000b	;27
XTG_MOV___R8_M8__M8_R8									equ		00001000000000000000000000000000b	;28
XTG_INC_DEC___M32										equ		00010000000000000000000000000000b	;29
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R32__M32				equ		00100000000000000000000000000000b	;30
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___M32__R32				equ		01000000000000000000000000000000b	;31
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R8_M8__M8_R8			equ		10000000000000000000000000000000b	;32
;----------------------------------------[XMASK1 END]----------------------------------------------------
;----------------------------------------[XMASK2 BEGIN]--------------------------------------------------
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___M32_M8__IMM32_IMM8		equ		00000000000000000000000000000001b	;33 01
XTG_CMP___R32_M32__M32_R32								equ		00000000000000000000000000000010b	;34 02
XTG_CMP___M32_M8__IMM32_IMM8							equ		00000000000000000000000000000100b	;35 03
XTG_MOV_LEA___R32__M32EBPO8								equ		00000000000000000000000000001000b	;36 04
XTG_MOV___M32EBPO8__R32									equ		00000000000000000000000000010000b	;37 05
XTG_MOV___M32EBPO8__IMM32								equ		00000000000000000000000000100000b	;38 06
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___R32__M32EBPO8			equ		00000000000000000000000001000000b	;39 07
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___M32EBPO8__R32			equ		00000000000000000000000010000000b	;40	08
XTG_ADC_ADD_AND_OR_SBB_SUB_XOR___M32EBPO8__IMM32_IMM8	equ		00000000000000000000000100000000b	;41 09
XTG_CMP___R32_M32EBPO8__M32EBPO8_R32					equ		00000000000000000000001000000000b	;42 10
XTG_CMP___M32EBPO8__IMM32_IMM8							equ		00000000000000000000010000000000b	;43 11 

XTG_MASK_WINAPI											equ		00000000000000000000100000000000b	;44 12 

XTG_XFPU												equ		00000000000000000001000000000000b	;45 13
XTG_XMMX												equ		00000000000000000010000000000000b	;46	14 
XTG_XSSE												equ		00000000000000000100000000000000b	;47	15
;----------------------------------------[XMASK2 END]----------------------------------------------------
;=====================================[ДЛЯ РЕЖИМА XTG_MASK]==============================================

;===================================[ДЛЯ РЕЖИМА XTG_REALISTIC]===========================================
;----------------------------------------[XMASK1 BEGIN]--------------------------------------------------
XTG_FUNC												equ		00000000000000000000000000000001b	;генерация функций (с прологами, трэшем, эпилогами etc); 
XTG_REALISTIC_WINAPI									equ		00000000000000000000000000000010b	;генерация фэйк-винапи; 
XTG_LOGIC												equ		00000000000000000000000000000100b	;юзаем логику для генерации трэша; 
;----------------------------------------[XMASK1 END]----------------------------------------------------
;===================================[ДЛЯ РЕЖИМА XTG_REALISTIC]===========================================

;------------------------------------------[XMASK]-------------------------------------------------------
XTG_ON_XMASK											equ		11111111111111111111111111111111b	;01
XTG_OFF_XMASK											equ		00000000000000000000000000000000b	;02
;------------------------------------------[XMASK]-------------------------------------------------------
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги масок XTG_TRASH_GEN.xmask1 & XTG_TRASH_GEN.xmask2  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_DATA_STRUCT.xmask (маска для генерации данных); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
XTG_DG_STRA												equ		00000000000000000000000000000001b
XTG_DG_NUM32											equ		00000000000000000000000000000010b
XTG_DG_ON_XMASK											equ		00000000000000000000000000000011b
XTG_DG_OFF_XMASK										equ		00000000000000000000000000000000b
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_DATA_STRUCT.xmask (маска для генерации данных); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
  


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_DATA_STRUCT.rdata_pva (адрес); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
XTG_OFFSET_ADDR											equ		00h		;адрес в rdata_addr - абсолютный физический в файле;
XTG_VIRTUAL_ADDR										equ		01h 	;виртуальный адрес в памяти (VirtualAddress aka VA); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_DATA_STRUCT.rdata_pva (адрес);
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги для поля XTG_INSTR_DATA_STRUCT.param_1
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
XTG_XIDS_CONSTR											equ		10000000000000000000000000000000b	;обозначает, что мы генерим команды для конструкции (push/pop etc);  
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги для поля XTG_INSTR_DATA_STRUCT.param_1
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_INSTR_PARS_STRUCT.flags
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
XTG_VL_INSTR_INIT										equ		00000000000000000000000000000001b	;данный флаг означает, что разобранная команда - это команда инициализации (mov reg32, reg32   etc); 
XTG_VL_INSTR_CHG										equ		00000000000000000000000000000010b	;команда изменения параметра(ов) (add reg32, reg32 etc); 
XTG_VL_P1_REG											equ		00000000000000000000000000000100b	;есть параметр_1, и это регистр
XTG_VL_P1_ADDR											equ		00000000000000000000000000001000b	;param_1 - адрес
XTG_VL_P1_NUM											equ		00000000000000000000000000010000b	;или число
XTG_VL_P1_GET											equ		00000000000000000000000000100000b	;парам_1 получает значение (add reg32_1, reg32_2 -> reg32_1 - регистр, получает значение, reg32_2 -> рег, отдаёт значение); 
XTG_VL_P1_GIVE											equ		00000000000000000000000001000000b	;param_1 отдает значение
XTG_VL_P2_REG											equ		00000000000000000000000010000000b	;есть парам_2, и это рег
XTG_VL_P2_ADDR											equ		00000000000000000000000100000000b	;или адрес
XTG_VL_P2_NUM											equ		00000000000000000000001000000000b	;или число
XTG_VL_P2_GET											equ		00000000000000000000010000000000b	;парам_2 получает значение
XTG_VL_P2_GIVE											equ		00000000000000000000100000000000b	;отдает значение; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля XTG_INSTR_PARS_STRUCT.flags
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;дополнительные значения для поля XTG_INSTR_DATA_STRUCT.flags;
;основные же значения - это номера, соотв-щие конкретным флагам конструкций; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
XTG_ID_FUNC_PROLOG										equ		1001	;означает, что щас нужно проэмулить и проверить пролог нашей функи
XTG_ID_FUNC_PARAM										equ		1002	;проверка только что сгенеренного входящего параметра 
XTG_ID_FUNC_CALL										equ		1003	;эмуляция call'a
XTG_ID_FUNC_EPILOG										equ		1004	;эмуляция эпилога (+ команда ret); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;дополнительные значения для поля XTG_INSTR_DATA_STRUCT.flags;
;основные же значения - это номера, соотв-щие конкретным флагам конструкций; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 





;========================================================================================================





;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;структуры для движка IRPE (+ xTG); 
;+ их описание; 
;([0] - in_param, [1] - out_param); 
;IRPE_POLYMORPH_GEN			-	основная структура, её адрес передаётся движку IRPE для генерации полиморфного декриптора (с шифрованным кодом);
;IRPE_CONTROL_BLOCK_STRUCT	-	структура, содержащая различные данные по декриптору
;IRPE_BLOCK_DATA_STRUCT		-	структура, содержащая различные данные по блоку(ам) декриптора; располагается(ются) сразу после IRPE_CONTROL_BLOCK_STRUCT; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;--------------------------------------------------------------------------------------------------------
IRPE_POLYMORPH_GEN			struct
	xmask							dd					?				;[0]; маска для полиморфа (мультидекрипторность, генерировать ли переход (call) на расшифрованный код etc); 
	xtg_struct_addr					dd					?				;[0]; address of XTG_TRASH_GEN (similar)
	xtg_addr						dd					?				;[0]; addr of trashgen (similar of xTG);
	code_addr						dd					?				;[0]; адрес кода, который надо зашифровать (код по данному адресу не будет изменяться, для этого в полиморфе выделяется спец. буфер); 
	va_code_addr					dd					?				;[0]; (virual address) виртуальный адрес, по которому будет лежать данный (в будущем) зашифрованный код для последующей расшифровки; 
	code_size						dd					?				;[0]; размер кода, который надо зашифровать
	decryptor_size					dd					?				;[0]; размер будущего декриптора; 
	decryptor_addr					dd					?				;[1]; адрес (в буфере) (1-ого aka стартового) созданного декриптора; 
	encrypt_code_addr				dd					?				;[1]; адрес (в буфере) шифрованного кода; 
	total_size						dd					?				;[1]; общий размер (стартового) декриптора + шифрованного кода (Decrypt + Encrypt Code (DEC)); 
	ep_polymorph_addr				dd					?				;[1]; address of entry point; точка входа в полиморфный код; 
	leave_num						dd					?				;[1]; сколько раз выполнить команду leave, чтобы сбалансировать стек (если в xmask был задан флаг создания перехода на расшифрованный код);
IRPE_POLYMORPH_GEN			ends 
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
IRPE_CONTROL_BLOCK_STRUCT	struct
	cur_addr						dd					?				;[0]; текущий адрес блока (или адрес текущего блока, похуй!) IRPE_BLOCK_DATA_STRUCT, который будет обрабатываться; 
	tnob							dd					?				;[0]; total number of blocks 
	used_regs						dd					?				;[0]; используемые декриптором (полезным кодом) реги (битовые флаги (маска)); 
	main_key						dd					?				;[0]; основной (базовый) ключ, которым будет шифроваться код
	slide_key						dd					?				;[0]; плавающий/скользящий ключ - основной ключ будет с помощью некоторого алгоритма изменять на значение плавающего ключа (ёба, так это скользящий ключ =)); 
	crypt_alg						dd					?				;[0]; битовая маска - флаг, указывающий, какой алгоритм декриптования применён; 
	chgkey_alg						dd					?				;[0]; битовая маска - флаг, указывающий, с помощью какого алгоса изменяется основной ключ (add/sub/etc); 
	cur_rec_level					dd					?				;[1]; (current recurs level) вспомогательное поле (необходимое для хранения текущего уровня рекурсии при построении функций (с прологами и т.п.)); 
	nopb							dd					?				;[1]; number of processed blocks; 
	dnobw							dd					?				;[1]; decryptor number of bytes written; кол-во записанных байтов декриптора (полезного кода); 
	label_addr						dd					?				;[1]; адрес метки, куда будет переход (jxx); это и другие поля можно юзать для других, своих значений (смотри в сорцы и в функу instr_constr!); etc; 
	func_level						dd					?				;[1]; номер функции, в которой записался код (в данной ситуации наш декриптор); 
	tmp_var1						dd					?				;[1]; вспомогательная переменная - хранит значение некоторого поля XTG_TRASH_GEN; 
	tmp_var2						dd					?				;[1]; etc;
	tmp_var3						dd					?				;[1]; etc; (смотри в функу add_useful_code); 
IRPE_CONTROL_BLOCK_STRUCT	ends
;--------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------
IRPE_BLOCK_DATA_STRUCT		struct
	instr_addr						dd					?				;[0]; адрес инструкции/конструкции в некотором буфере (можно хранить хоть одну команду, хоть целый блок команд (т.е. одна большая конструкта)); 
	instr_size						dd					?				;[0]; размер этой инструкции/конструкции
	instr_flags						dd					?				;[0]; битовая маска - тут хранятся различные флаги; 
IRPE_BLOCK_DATA_STRUCT		ends
;--------------------------------------------------------------------------------------------------------
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;структы для движка IRPE (+ xTG); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля IRPE_POLYMORPH_GEN.xmask
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
IRPE_CALL_DECRYPTED_CODE			equ			00000001b				;генерировать ли вызов (call -> 0xE8...) на расшифрованный код; 
IRPE_MULTIPLE_DECRYPTOR				equ			00000010b				;мультидекрипторность; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;допустимые значения для поля IRPE_POLYMORPH_GEN.xmask
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;различные дефайны/константы для iRPE; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MAX_NUM_BLOCK_DECRYPTOR				equ			50						;максимальное количество генерируемых блоков декриптора; 
MNBD								equ			MAX_NUM_BLOCK_DECRYPTOR	;etc; 
IRPE_ALLOC_BUFFER					equ			100000h					;выделяемый буфер для построения декриптора (с зашифрованным кодом); при необходимости увеличить данное значение; 
DECRYPTOR_MIN_SIZE					equ			func_size				;минимальный размер одного декриптора; если в структуру полиморфа передаётся размер, меньше этого числа, тогда на выход без генерации; 
DECRYPTOR_MAX_NUM					equ			3;5						;максимальное количество генерируемых декрипторов (число должно быть > 1); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;различные дефайны/константы для iRPE; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги для маски IRPE_BLOCK_DATA_STRUCT.instr_flags (битовая маска!);
;данные флаги описывают, что представляет собой полезный код, который надо записать вместе с трэшаком;
; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
IRPE_INSTR_NORMAL					equ			00000000000000000000000000000001b	;обычная команда (mov/xor/add - то есть, линейная, не переход, не вызов etc); 
IRPE_INSTR_JXX						equ			00000000000000000000000000000010b	;условный переход
IRPE_INSTR_JMP						equ			00000000000000000000000000000100b	;безусловный переход
IRPE_INSTR_CALL						equ			00000000000000000000000000001000b	;call
IRPE_INSTR_BAD						equ			00000000000000000000000000010000b	;негодная инструкция;
IRPE_GEN_TRASH						equ			00000000000000000000000000100000b	;можно ли генерировать трэш перед генерацией данной команды/конструкты; 
IRPE_INSTR_LABEL					equ			00000000000000000000000001000000b	;данная инструкция - это метка, то есть сюда будет прыгать команда перехода=); 
IRPE_BLOCK_BEGIN					equ			00000000000000000000000010000000b	;начало и конец блока - то есть если мы хотим, чтобы несколько команд представляли собой один блок (чтобы точно располагались в одной функе), 
IRPE_BLOCK_END						equ			00000000000000000000000100000000b	;и между ними можно было генерить мусор, то обрамляем самый первый блок, который начинает описывать нужные команды, флагом IRPE_BLOCK_BEGIN; 
																					;и обрамляем последний блок, описывающий последнюю конструкцию, флагом IRPE_BLOCK_END; 
																					;таким образом, все блоки, находящиеся между обрамлёнными блоками, а также сами обрамлённые блоки теперь представляют собой один блок (значение IRPE_BLOCK_DATA_STRUCT.tnob - увеличивается всего на +1, точно также и поле IRPE_BLOCK_DATA_STRUCT.nopb); 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги для маски IRPE_BLOCK_DATA_STRUCT.instr_flags (битовая маска!); 
;данные флаги описывают, что представляет собой полезный код, который надо записать вместе с трэшаком;
; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги для масок IRPE_CONTROL_BLOCK_STRUCT.crypt_alg и IRPE_CONTROL_BLOCK_STRUCT.chgkey_alg; 
; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
IRPE_ADD___R32__IMM32				equ			00000000000000000000000000000001b	; 
IRPE_SUB___R32__IMM32				equ			00000000000000000000000000000010b	;
IRPE_XOR___R32__IMM32				equ			00000000000000000000000000000100b	;
IRPE_XOR___M32__R32					equ			00000000000000000000000000001000b	;
IRPE_ADD___M32__R32					equ			00000000000000000000000000010000b	;
IRPE_SUB___M32__R32					equ			00000000000000000000000000100000b	;
IRPE_XOR___R32__IMM8				equ			00000000000000000000000001000000b	;
IRPE_ADD___R32__IMM8				equ			00000000000000000000000010000000b	;
IRPE_SUB___R32__IMM8				equ			00000000000000000000000100000000b	;
IRPE_INC___R32						equ			00000000000000000000001000000000b	;
IRPE_DEC___R32						equ			00000000000000000000010000000000b	;
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;флаги для масок IRPE_CONTROL_BLOCK_STRUCT.crypt_alg и IRPE_CONTROL_BLOCK_STRUCT.chgkey_alg
; 
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx





  

