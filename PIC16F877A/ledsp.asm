; ============================================================
; PIC16F877A - JElectronica JT40P-V1.0
; Cristal: 20 MHz
; Programador: PICkit2
; MPASM - CONFIG en hexadecimal
; ============================================================

    LIST        P=16F877A
    #INCLUDE    <P16F877A.INC>

    __CONFIG    0x3F32

;------------------------------------------------------------
; VARIABLES
;------------------------------------------------------------
    CBLOCK      0x20
        DEL1
        DEL2
        DEL3
    ENDC

;------------------------------------------------------------
; RESET VECTOR
;------------------------------------------------------------
    ORG         0x0000
    GOTO        INICIO

    ORG         0x0004
    RETFIE

;------------------------------------------------------------
; RETARDO ~500ms a 20MHz
;------------------------------------------------------------
    ORG         0x0010

RETARDO:
    MOVLW       0xFF
    MOVWF       DEL1
LOOP1:
    MOVLW       0xFF
    MOVWF       DEL2
LOOP2:
    MOVLW       0x05
    MOVWF       DEL3
LOOP3:
    DECFSZ      DEL3, F
    GOTO        LOOP3
    DECFSZ      DEL2, F
    GOTO        LOOP2
    DECFSZ      DEL1, F
    GOTO        LOOP1
    RETURN

;------------------------------------------------------------
; INICIO
;------------------------------------------------------------
INICIO:
    BSF         STATUS, RP0
    BCF         STATUS, RP1

    MOVLW       0x00
    MOVWF       TRISA
    MOVLW       0x00
    MOVWF       TRISB
    MOVLW       0x00
    MOVWF       TRISC
    MOVLW       0x00
    MOVWF       TRISD
    MOVLW       0x00
    MOVWF       TRISE

    MOVLW       0x06
    MOVWF       ADCON1

    BCF         STATUS, RP0

    CLRF        PORTA
    CLRF        PORTB
    CLRF        PORTC
    CLRF        PORTD
    CLRF        PORTE

;------------------------------------------------------------
; BUCLE PRINCIPAL
;------------------------------------------------------------
LOOP:
    MOVLW       0x0F
    MOVWF       PORTA
    CALL        RETARDO
    CLRF        PORTA

    MOVLW       0x0F
    MOVWF       PORTB
    CALL        RETARDO
    CLRF        PORTB

    MOVLW       0x0F
    MOVWF       PORTC
    CALL        RETARDO
    CLRF        PORTC

    MOVLW       0x0F
    MOVWF       PORTD
    CALL        RETARDO
    CLRF        PORTD

    MOVLW       0x07
    MOVWF       PORTE
    CALL        RETARDO
    CLRF        PORTE

    GOTO        LOOP

    END