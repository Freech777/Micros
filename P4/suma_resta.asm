LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF



ORG 0x00


CONFIGURACION
BSF STATUS, RP0
MOVLW b'00011111'
MOVFW TRISB
CLRF  TRISC
BCF STATUS, RP0

MAIN



goto MAIN

;Suma de 3 en 3 en hexadecimal para pasarlo a binario y mostrarlo en el puerto C
RB0_SUMA3

;Resta lo que haya en el puerto C de 2 en 2
RB1_RESTA2



;Apaga todos los leds de el puerto C
RB2_OFF
CLRF PORTC
goto MAIN

;Enciende led por led en el puerto C
RB3_ON1

;Apaga led por led en el puerto C
RB4_OFF1


END