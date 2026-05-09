LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

; Origen en donde parte el codigo
ORG		0x00

MASCARA_PARES  EQU     0x55

CONFIGURACION
    ; Configurar puertos
    BSF STATUS, RP0        ; Banco 1


    CLRF TRISB

    MOVLW 0xFF
    MOVWF TRISC

    BCF STATUS, RP0

    CLRF    PORTB


goto    MAIN        

MAIN

MOVF    PORTC, W
XORLW   MASCARA_PARES

MOVWF   PORTB

goto MAIN    

    END
