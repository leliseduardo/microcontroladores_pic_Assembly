;
;		O objetivo deste programa � implementar um voltimetro a partir da leitura do conversor AD. Para isso, necessita-se
;	utilizar as opera��es de multiplica��o e divis�o, que ser�o obtidas da nota de aplica��o AN544, feira pela microchip.
;		No circuito deste programa, pode-se utilizar um divisor de tens�o que receba, por exemplo, at� 25V e entregue de
; 0V a 5V na entrada anal�gica do do Pic. Assim, mede-se indiretamente a tens�o de 0V a 25V.
;		Para fazer a convers�o do valor lido no ADC em tens�o, basta fazer uma regra de 3:
;
;		255 ----------  25V
;		ADC ---------- Tens�o
;			Tens�o = ( ADC * 25V) / 255
;
;		Para se ter fazer com que o resultado seja lido com casas decimais, multiplica-se o resultado por 100, para que,
;	caso se utilize um display, seja colocado um ponto para representar as casas decimais. Logo, multiplicando a tens�o
;	por 100, a equa��o fica
;	
;			Tens�o = (ADC * 250) / 255
;
;		Para fazer uma equa��o desta em Assembly, necessita-se criar as fun��es de multiplica��o e divis�o, trabalho j�
;	realizado pela Microchip em sua nota de aplica��o AN544.
;
;		No debug o programa funcionou como esperado.
;

	list p=16f876a							; Informa o microcontrolador utilizado
	
	
; --- Documenta��o ---


	#include	<p16f876a.inc>				; Inclui o arquivo que cont�m os registradores do Pic
	
	
; --- Fuse bits ---

	
	__config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _BOREN_OFF & _LVP_OFF  & _CP_OFF & _CPD_OFF
	
	; Configura clock  4MHz, liga o Power Up Timer e desliga o Master Clear
	
	
; --- Pagina��o de mem�ria ---

	
	#define 	bank0	bcf	STATUS,RP0		; Cria mnem�nico para selecionar o banco 0 de mem�ria
	#define		bank1	bsf	STATUS,RP0		; Cria mnem�nico para selecionar o banco 1 de mem�ria
	
	
; --- Mapeamento de hardware ---


	
	
; --- Registradores de uso geral ---


	cblock		H'20'						; Endere�o de inicio para configura��o de registradores de uso geral
	
	W_TEMP									; Armazena o conte�do de w temporariamente
	STATUS_TEMP								; Armazena o conte�do de STATUS temporariamente
	adc										; Armazena a leitura de ADC
	
	REG1H									;byte alto registrador 1 de 16 bits utilizado na rotina de divis�o
	REG1L									;byte baixo registrador 1 de 16 bits utilizado na rotina de divis�o
	REG2H									;byte alto registrador 2 de 16 bits utilizado na rotina de divis�o
	REG2L									;byte baixo registrador 2 de 16 bits utilizado na rotina de divis�o
	REG3H									;byte alto registrador 3 de 16 bits utilizado na rotina de divis�o
	REG3L									;byte baixo registrador 3 de 16 bits utilizado na rotina de divis�o
	REG4H									;byte alto registrador 4 de 16 bits utilizado na rotina de divis�o
	REG4L									;byte baixo registrador 4 de 16 bits utilizado na rotina de divis�o
	AUX_H									;byte baixo de registrador de 16 bits para retornar valor da div
	AUX_L									;byte baixo de registrador de 16 bits para retornar valor da div
	AUX_TEMP								;contador tempor�rio usado na rotina de divis�o
	REG_MULT1								;registrador 1 para multiplica��o
	REG_MULT2								;registrador 2 para multiplica��o
	REG_AUX									;registrador auxiliar
	UNI										;armazena unidade
	DEZ_A									;armazena unidade da dezena
	DEZ_B									;armazena dezena
	
	
	endc									; Fim da configura��o de registradores de uso geral
	
	cont1		equ		H'23'				; Contador auxiliar no banco 0 de mem�ria
	cont2		equ		H'A1'				; Contador auxiliar no banco 1 de mem�ria
	
; --- Vetor de Reset ---

	
	org			H'0000'						; Endere�o de origem do vetor de Reset
	
	goto 		inicio						; Desvia para o programa principal	
	
	
; --- Vetor de Interrup��o ---

	
	org			H'0004'						; Endere�o de origem do vetor de Interrup��o
	
; -- Salvamento de contexto --

	movwf		W_TEMP						; W_TEMP = w
	swapf		STATUS,w					; w = STATUS (com nibbles invertidos)
	bank0									; Seleciona o banco 0 de mem�ria
	movwf		STATUS_TEMP					; STATUS_TEMP = STATUS (com nibbles invertidos)
	
; -- Fim do salvamento de contexto

	; Desenvolvimento da ISR...
	
	
; -- Recupera��o de contexto --

exit_ISR:

	swapf		STATUS_TEMP,w				; w = STATUS (original)
	movwf		STATUS						; STATUS = STATUS (original)
	swapf		W_TEMP,F					; W_TEMP = w (com nibbles invertidos)
	swapf		W_TEMP,w					; W_TEMP = w (original)
	
	retfie									; Retorna para o endere�o que estava quando ocorreu a interrup��o
	
; -- Fim da recupera��o de contexto --


; --- Programa principal ---

inicio:										; Cria label do programa principal

	bank1									; Seleciona banco 1 de mem�ria
	movlw		H'FF'						; w = FF
	movwf		TRISA						; Configura todo PORTA como entrada
	movlw		H'00'						; w = 00
	movwf		TRISB						; Configura todo PORTB como sa�da digital
	call 		configura_ADC				; Chama subrotina configura_ADC


; -- Loop infinito --

loop:										; Cria label para loop infinito

	bsf			ADCON0,GO_DONE				; Inicia leitura do ADC
	
espera_leitura:

	btfsc		ADCON0,GO_DONE				; Testa se flag GO_DONE limpou, se sim, pula uma linha
	goto		espera_leitura				; Se n�o limpou, desvia para label espera_leitura
	
	movf		ADRESH,w					; w = ADRESH, armazena em w o conte�do lido pelo ADC
	movwf		REG_MULT1					; REG_MULT1 = w = ADRESH
	movlw		D'250'						; w = 250d
	movwf		REG_MULT2					; REG_MULT2 = 250d
	call		multip						; Chama a subrotina de multiplica��o
	movf		AUX_H,w						; w = AUX_H, armazena em w o conte�do mais significativo do resultado da mult
	movwf		REG2H						; REG2H = AUX_H
	movf		AUX_L,w						; w = AUX_L, armazena em w o conte�do menos significativo do resultado da mult
	movwf		REG2L						; REG2L = AUX_L
	clrf		REG1H						; Limpa REG1H
	movlw		D'255'						; w = 255d
	movwf		REG1L						; REG1L = 255d
	call 		divid						; Chama subrotina de divis�o
	movf		REG2L,w						; w = REG2L


	goto		loop						; Desvia para loop infinito
	
	
	
; --- SubRotinas ---

configura_ADC:

	bank1									; Seleciona o banco 1 de mem�ria
	movlw		H'0E'						; w = OEh
	movwf		ADCON1						; Justificado a esquerda, Fosc/2, apenas AN0 habilitado
	bank0									; Seleciona o banco 0 de mem�ria
	movlw		H'41'						; w = 41h
	movwf		ADCON0						; Fosc/8, canal 0 de convers�o e liga o conversor AD
	
	return									; Retorna para endere�o onde a subrotina foi chamada


;========================================================================================
; --- Sub rotina de multiplica��o (baseada na nota de aplica��o AN544 da Microchip) ---
mult    MACRO   bit							;Inicio da macro de multiplica��o

	btfsc		REG_MULT1,bit				;bit atual de REG_MULT1 limpo?
	addwf		AUX_H,F						;N�o. Acumula soma de AUX_H
	rrf			AUX_H,F						;rotaciona AUX_H para direita e armazena o resultado nele pr�prio
	rrf			AUX_L,F						;rotaciona AUX_L para direita e armazena o resultado nele pr�prio

	endm									;fim da macro


multip:

	clrf		AUX_H						;limpa AUX_H
	clrf		AUX_L						;limpa AUX_L
	movf		REG_MULT2,W					;move o conte�do de REG_MULT2 para Work
	bcf			STATUS,C					;limpa o bit de carry

	mult    	0							;chama macro para cada um dos 7 bits
	mult    	1							;de REG_MULT1
	mult    	2							;
	mult    	3							;
	mult    	4							;
	mult    	5							;
	mult    	6							;
	mult    	7							;

	return									;retorna


;========================================================================================
; --- Sub rotina de divis�o (baseada na nota de aplica��o AN544 da Microchip) ---	
	
;========================================================================================
;                       Double Precision Division
;========================================================================================
;   Division : ACCb(16 bits) / ACCa(16 bits) -> ACCb(16 bits) with
;                                               Remainder in ACCc (16 bits)
;      (a) Load the Denominator in location ACCaHI & ACCaLO ( 16 bits )
;      (b) Load the Numerator in location ACCbHI & ACCbLO ( 16 bits )
;      (c) CALL D_divF
;      (d) The 16 bit result is in location ACCbHI & ACCbLO
;      (e) The 16 bit Remainder is in locations ACCcHI & ACCcLO
;****************************************************************************
divid:

	movlw		H'10'						;move 16d para Work
	movwf		AUX_TEMP					;carrega contador para divis�o

	movf		REG2H,W						;move conte�do de REG2H para Work
	movwf		REG4H						;armazena em REG4H
	movf		REG2L,W						;move conte�do de REG2L para Work
	movwf		REG4L						;armazena em REG4L
	clrf		REG2H						;limpa REG2H
	clrf		REG2L						;limpa REG2L
	clrf		REG3H						;limpa REG3H
	clrf		REG3L						;limpa REG3L

DIV
	bcf			STATUS,C					;limpa bit de carry
	rlf			REG4L,F						;rotaciona REG4L para esquerda e armazena nele pr�prio
	rlf			REG4H,F						;rotaciona REG4H para esquerda e armazena nele pr�prio
	rlf			REG3L,F						;rotaciona REG3L para esquerda e armazena nele pr�prio 
	rlf			REG3H,F						;rotaciona REG3H para esquerda e armazena nele pr�prio 
	movf		REG1H,W						;move conte�do de REG1H para Work
	subwf		REG3H,W						;Work = REG3H - REG1H
	btfss		STATUS,Z					;Resultado igual a zero?
	goto		NOCHK						;N�o. Desvia para NOCHK
	movf		REG1L,W						;Sim. Move conte�do de REG1L para Work
	subwf		REG3L,W						;Work = REG3L - REG1L
	 
NOCHK
	btfss		STATUS,C					;Carry setado?
	goto		NOGO						;N�o. Desvia para NOGO
	movf		REG1L,W						;Sim. Move conte�do de REG1L para Work
	subwf		REG3L,F						;Work = REG3L - REG1L
	btfss		STATUS,C					;Carry setado?
	decf		REG3H,F						;decrementa REG3H 
	movf		REG1H,W						;move conte�do de REG1H para Work
	subwf		REG3H,F						;Work = REG3H - REG1H
	bsf			STATUS,C					;seta carry
	 
NOGO
	rlf			REG2L,F						;rotaciona REG2L para esquerda e salva nele pr�prio
	rlf			REG2H,F						;rotaciona REG2H para esquerda e salva nele pr�prio
	decfsz		AUX_TEMP,F					;decrementa AUX_TEMP. Chegou em zero?
	goto		DIV							;N�o. Continua processo de divis�o
	return									;Sim. Retorna
	
	
	
;========================================================================================	


; --- Fim do programa ---

	end										; Final do programa