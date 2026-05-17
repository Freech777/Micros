LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

ORG 0x00

CBLOCK 0x20
CONT    ; Se usa para el conteo de 3 veces el parpadeo de el push
ENDC


CONFIGURACION
BSF STATUS,RP0

; Entradas de manera analogica RA0 (Axis X) y RA1 (Axis Y)
MOVLW 0x03      ;Aqui solo se declaran los pines entrada, aun falta la configuracion ADC
MOVWF TRISA

; PORTB
BCF TRISB,0 ; Bit salida para el centro del joystick, unico que no entra ni en Axis X y Axis Y
BSF TRISB,1 ; Bit entrada para AXIS X y AXIS Y

; Puerto de salida AXIS X
MOVLW 0x00
MOVWF TRISC

; Puerto de salida AXIS Y
MOVLW 0x00
MOVWF TRISD

; Configuracion de ADCON1 banco 0,1
MOVLW b'00001001'   ;Bit 7 Left justified ADRESL 
                    ;Bit 6 Fosc/64 para mejor captura
                    ;Bit 5-4 valen vg 
                    ;Bit 3-0 pone AN1-AN0 todo lo demas digital,Vref+ = Vdd y Vref- = Vss
MOVWF ADCON1

;Resgresamos al banco 0,0
BCF STATUS,RP0

;Esta mamada del pic no puede configurarse para leer 2 ADC por separado
;Se configurara primero AXIS X 

MOVLW b'10000001'   ;Bit 7-6 Fosc/64
                    ;Bit 5-3 Channel 0 (AN0)
                    ;Bit 2 GO/DONE A/D not in progress
                    ;Bit 1 vale vg
                    ;Bit 0 A/D modulo convertidor se levanta
MOVWF ADCON0

; Ya a la chingada se configuro todo lo inicial

MAIN                ;Hay de 3 sopas Bajo o Alto RB1  
                    ;Bajo se va a AXIS_X
                    ;Alto se va a AXIS_Y
                    ;Push boton de joystick
    BTFSS PORTB,1
    CALL AXIS_X
    BTFSC PORTB,1
    CALL AXIS_Y


GOTO MAIN



AXIS_X
    
    BTFSC PORTB,2
    CALL  PUSH_JOYSTICK

    BTFSS PORTB,1
    GOTO AXIS_X
RETURN  ;Me regresa a mi rutina MAIN




AXIS_Y
    BTFSC PORTB,2
    CALL  PUSH_JOYSTICK

    BTFSC PORTB,1
    GOTO AXIS_Y
RETURN  ;Me regresa a mi rutina MAIN





;Rutina de la pulsacion del joystick
PUSH_JOYSTICK

    MOVLW 0xFF
    MOVWF PORTC

    MOVLW 0xFF
    MOVWF PORTD

    BSF PORTB,0

    CALL Retardo_500ms

    MOVLW 0x00
    MOVWF PORTC

    MOVLW 0x00
    MOVWF PORTD

    BCF PORTB,0

    DECFSZ CONT,1
    GOTO PUSH_JOYSTICK

    MOVLW 0x03
    MOVWF CONT

RETURN

#include "Retardos.inc"

END