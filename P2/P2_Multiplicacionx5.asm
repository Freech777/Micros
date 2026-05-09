LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF


; Origen en donde parte el codigo
ORG		0x00


; Bloque de memoria para no andar declarando
CBLOCK  0x20
    VALOR
    TEMP
    ENDC

CONFIGURACION
    ; Configurar puertos
    BSF STATUS, RP0        ; Banco 1

    MOVLW 0xF0
    MOVWF TRISB

    CLRF TRISD             ; Puerto D como salida

    BCF STATUS, RP0        ; Banco 0  

goto    MAIN        

MAIN
    ; Leer PORTB
    MOVF PORTB, W
    ANDLW 0xF0             ; Mascara RB7-RB4

    MOVWF TEMP
    SWAPF TEMP, W          ; Ahora en bits bajos

    MOVWF TEMP        ; Guardar en TEMP
    COMF TEMP, W      ; Invertir

    ANDLW 0x0F             ; Solo 4 bits

    MOVWF VALOR            ; Guardar valor original

    ; Multiplicar por 5
    MOVF VALOR, W
    MOVWF TEMP 

    RLF TEMP, F
    RLF TEMP, F

    MOVF VALOR, W
    ADDWF TEMP, F

    ; Enviar a PORTD
    MOVF TEMP, W
    MOVWF PORTD
goto MAIN    

    END
