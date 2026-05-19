LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

ORG 0x00

CBLOCK 0x20

ENDC


CONFIGURACION
BSF STATUS,RP0

; RA0,RA1 y RA2 como entradas, aun no se declaran analogicas
MOVLW b'00000111'
MOVWF TRISA

; RC0,RC1 y RC2 como salidas para motores
MOVLW 0x00
MOVWF TRISC

; RD0 - RD4 salidas para LED's indicadores
MOVLW 0x00
MOVWF TRISD

; Configuracion de ADCON1 banco 0,1
MOVLW b'10001001'   ;Bit 7 RIGHT justified
                    ;Bit 6 Fosc/64 para mejor captura
                    ;Bit 5-4 valen vg 
                    ;Bit 3-0 pone AN1-AN0 todo lo demas digital,Vref+ = Vdd y Vref- = Vss
MOVWF ADCON1

;Resgresamos al banco 0,0
BCF STATUS,RP0

MOVLW b'10000110'   ;Bit 7-6 Fosc/64
                    ;Bit 5-3 Channel 0 (AN0)
                    ;Bit 2 GO/DONE A/D not in progress
                    ;Bit 1 vale vg
                    ;Bit 0 A/D modulo convertidor se levanta
MOVWF ADCON0

CLRF PORTC
CLRF PORTD

CALL Retardo_20ms
BSF ADCON0,2

;Lectura del sistema en general de manera inicial
MAIN

;Nuestra condicional va a ser la puerta abierta


CALL Retardo_20ms





LAVANDO



SECANDO


PUERTA_ABIERTA




ALARMA





#include "Retardos.inc"

END
