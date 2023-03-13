;
;		PIC16F628A		Clock = 4 MHz		Ciclo de m�quina = 1us
;
;		Este programa tem a fun��o de, a partir da interrup��o do timer0, fazer uma varredura de dois bot�es que, quando
;	clicados, ir�o inverter o estado de um led. Ser�o dois bot�es dois leds.
;
;		Timer 0
;
;		Overflow = (256 - TMR0) * prescaler * ciclo de m�quina
;		Overflow = 246 * 128 * 1us
;		Overflow = 31ms
;		
;		Na simula��o e na pr�tica, o circuito e o programa funcionaram como esperado. A base de tempo programada para a
;	varredura dos bot�es funcionou como esperado. O tempo � o tempo de overflow vezes o tempo de cont. 
;		Overflow * cont = 31ms * 6 = +-186ms	
;

	list		p=16f628a					; Informa o microcontrolador utilizado

; --- Inclus�o de arquivos ---

	#include	<p16f628a.inc>				; Inclui o arquivo com os registradores do Pic
	
; --- Fuse bits ---

	__config	_XT_OSC	& _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
	
;	Clock de 4MHz, Power Up Time e Master Clear habilitados

; --- Pagina��o de mem�ria ---

	#define		bank0	bcf	STATUS,RP0		; Cria mnem�nico para selecionar o banco 0 de mem�ria
	#define 	bank1	bsf	STATUS,RP0		; Cria mnem�nico para selecionar o banco 1 de mem�ria
	
; --- Sa�das ---

	#define 	led1	PORTA,3				; Cria um mnem�nico para led1 em RA3
	#define 	led2	PORTA,2				; Cria um mnem�nico para led2 em RA2
	
; --- Entradas ---

	#define 	botao1	PORTB,0				; Cria um mnem�nico para botao1 em RB0
	#define 	botao2	PORTB,1				; Cria um mnem�nico para botao2 em RB1
	
; --- Registadores de uso geral ---

	cblock		H'20'						; Cria registradores de uso geral a partir do endere�o 20h de mem�ria
	
	W_TEMP									; Armazena conte�do de W temporariamente
	STATUS_TEMP								; Armazena conte�do de STATUS temporariamente
	cont									; Base de tempo para o timer0
	
	endc

; --- Vetor de Reset ---

	org			H'0000'						; Origem do endere�o do vetor de Reset
	goto 		inicio						; Desvia para label inicio
	
; --- Vetor de Interrup��o
	org 		H'0004'						; Origem do endere�o do vetor de Interrup��o
	
; --- Salva contexto ---
	
	movwf		W_TEMP						; W_TEMP = w
	swapf		STATUS,w					; w = STATUS (com nibbles invertidos)
	bank0									; Seleciona o banco 0 de mem�ria
	movwf		STATUS_TEMP					; STATUS_TEMP = w = STATUS (com nibbles invertidos)
	
; --- Final do salvamento de contexto ---

	btfss		INTCON,T0IF					; Testa se T0IF setou, se sim, pula uma linha
	goto		exit_ISR					; Se n�o, sa� da interrup��o
	bcf			INTCON,T0IF					; Limpa flag T0IF, para uma nova interrup��o
	movlw		D'10'						; w = D'10'
	movwf		TMR0						; Recarrega TMR0 com 10d
	
	decfsz		cont,F						; Decrementa cont e testa se chegou a zero, se sim, pula uma linha
	goto		exit_ISR					; Se n�o, sa� da interrup��o
	
	movlw		D'6'						; w = 6d
	movwf		cont						; Recarrega cont com 6d
	
	btfss		botao1						; Testa se o botao1 foi pressionado, se foi, N�O pula uma linha
	goto		complementa_Led1			; Desvia para lebel complemente_Led1
	
	btfss		botao2						; Testa se o botao2 foi pressionado, se foi, N�O pula uma linha
	goto		complementa_Led2			; Desvia para label complementa_Led2
	
	goto 		exit_ISR					; Sai da interrup��o
	
complementa_Led1:

	movlw		B'00001000'					; Move m�scara para w, para complementar led1
	xorwf		PORTA,F						; Faz l�gica XOR entre W e porta, complementando RA3, logo, Led1
	goto		exit_ISR					; Sai da interrup��o
	
complementa_Led2:

	movlw		B'00000100'					; Move m�scara para w, para complementar led2
	xorwf		PORTA,F						; Faz l�gica XOR entre W e porta, complementando RA2, logo, led2

; --- Recupera contexto ---

exit_ISR:

	swapf		STATUS_TEMP,w				; w = STATUS_TEMP (nibbles invertidos) = STATUS (original)
	movwf		STATUS						; STATUS = w = STATUS (original)
	swapf		W_TEMP,F					; W_TEMP = W_TEMP (com nibbles invertidos)
	swapf		W_TEMP,w					; w = W_TEMP = w (original)
	
	retfie
	
; --- Fim da interrup��o
	
	
inicio:

	bank0									; Seleciona o banco 0 de mem�ria
	movlw		H'07'						; w = 07h
	movwf		CMCON						; CMCON = 07h, desabilita os comparadores internos
	movlw		H'A0'						; w = 'A0'
	movwf		INTCON						; INTCON = A0h, habilita interrup��o global e a interrup��o do timer0
	bank1									; Seleciona o banco 1 de mem�ria
	movlw		H'86'						; w = 86h
	movwf		OPTION_REG					; OPTION_REG = 86h, desabilita os pull-ups internos, associa o prescaler do timer 0 e configura para 1:128
	movlw		H'F3'						; w = F3h
	movwf		TRISA						; TRISA = F3h, configura RA3 e RA2 como sa�das digital
	movlw		H'FF'						; w = FFh
	movwf		TRISB						; TRISB = FFh, configura todo portb como entrada digital
	bank0									; Seleciona o banco 0 de mem�ria
	movlw		D'10'						; w = 10d
	movwf		TMR0						; TMR0 inicia sua contagem em 10d
	bcf			led1						; Inicia led1 em Low
	bcf			led2						; Inicia led2 em Low
	movlw		D'6'						; w = 6d
	movwf		cont						; cont = 6d
	
	
loop:										; Cria loop infinito


	goto	 	$							; Loop infinito sem rotina
	
	
end