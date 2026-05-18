LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

ORG 0x00

CBLOCK 0x20
CONT    ; Se usa para el conteo de 3 veces el parpadeo de el push
VAR_CENTRO

ADRESLESSX
ADRESHIGHX

ADRESLESSY
ADRESHIGHY

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
MOVLW b'10001001'   ;Bit 7 RIGHT justified
                    ;Bit 6 Fosc/64 para mejor captura
                    ;Bit 5-4 valen vg 
                    ;Bit 3-0 pone AN1-AN0 todo lo demas digital,Vref+ = Vdd y Vref- = Vss
MOVWF ADCON1

;Resgresamos al banco 0,0
BCF STATUS,RP0

;Esta mamada del pic no puede configurarse para leer 2 ADC por separado
;Se configurara primero AXIS X 

MOVLW b'10000110'   ;Bit 7-6 Fosc/64
                    ;Bit 5-3 Channel 0 (AN0)
                    ;Bit 2 GO/DONE A/D not in progress
                    ;Bit 1 vale vg
                    ;Bit 0 A/D modulo convertidor se levanta
MOVWF ADCON0

BCF PORTB,0
CLRF    PORTC
CLRF    PORTD

MOVLW 0x03  ; Le damos un valor de 3 al cont
MOVWF CONT

MOVLW 0xFF
MOVWF VAR_CENTRO


; Ya a la chingada se configuro todo lo inicial


    CALL Retardo_20ms
    BSF ADCON0,2

MAIN                ;Hay de 3 sopas Bajo o Alto RB1  
                    ;Bajo se va a AXIS_X
                    ;Alto se va a AXIS_Y
                    ;Push boton de joystick

    BTFSS PORTB,1
    CALL AXIS_X
    BTFSC PORTB,1
    CALL AXIS_Y


GOTO MAIN


;---------------Bloque de rutinas para AXIS X-------------------
AXIS_X
    
    BTFSC PORTB,2
    CALL  PUSH_JOYSTICK

    MOVLW b'10000001'
    MOVWF ADCON0

    CALL Retardo_20ms

    BSF  ADCON0, 2
    BTFSC ADCON0, 2
    GOTO $-1

    MOVF  ADRESH, W
    MOVWF ADRESHIGHX

    BSF   STATUS, RP0
    MOVF  ADRESL, W
    BCF   STATUS, RP0
    MOVWF ADRESLESSX        ; 8 bits bajos → PORTD (aunque solo 2 bits importan)


    MOVF VAR_CENTRO,0
    SUBWF ADRESLESSX,0
    BTFSS STATUS,Z
    CALL DEADPOINT


    BTFSC ADRESHIGHX,1
    CALL AXIS_X_RIGHT

    MOVF ADRESLESSX, 1
    BTFSC STATUS,Z
    CALL AXIS_X_LEFT

    MOVLW 0xFF
    MOVWF VAR_CENTRO

    BTFSS PORTB,1
    GOTO AXIS_X
RETURN


AXIS_X_RIGHT
    BCF PORTB,0
    CLRF ADRESHIGHX

    MOVLW b'00010000'
    MOVWF PORTC
    CALL Retardo_200ms

    BCF STATUS,C
    RLF PORTC,0
    MOVWF PORTC
    CALL Retardo_200ms

    RLF PORTC,0
    MOVWF PORTC
    CALL Retardo_200ms

    RLF PORTC,0
    MOVWF PORTC

    CALL Retardo_200ms
RETURN

AXIS_X_LEFT
    BCF PORTB,0
    CLRF ADRESLESSX

    MOVLW 0x01
    MOVWF PORTC
    CALL Retardo_200ms
    RLF PORTC,0
    MOVWF PORTC

    CALL Retardo_200ms
    RLF PORTC,0
    MOVWF PORTC

    CALL Retardo_200ms
    RLF PORTC,0
    MOVWF PORTC

    CALL Retardo_200ms
RETURN


;---------------Final de rutinas para AXIS X-------------------



;---------------Bloque de rutinas para AXIS Y------------------
AXIS_Y
    BTFSC PORTB,2
    CALL  PUSH_JOYSTICK
    
    MOVLW b'10001001'
    MOVWF ADCON0
    CALL Retardo_20ms

    BSF ADCON0,2
    BTFSC ADCON0,2
    GOTO $-1

    MOVF ADRESH,0
    MOVWF ADRESHIGHY
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF ADRESLESSY

    MOVF VAR_CENTRO,0
    SUBWF ADRESLESSY,0
    BTFSS STATUS,Z
    CALL DEADPOINT

    BTFSC ADRESHIGHY,1
    CALL AXIS_Y_UP

    MOVF ADRESLESSY, 1
    BTFSC STATUS,Z
    CALL AXIS_Y_DOWN

    MOVLW 0xFF
    MOVWF VAR_CENTRO

    BTFSC PORTB,1
    GOTO AXIS_Y
RETURN  ;Me regresa a mi rutina MAIN

AXIS_Y_UP
    BCF PORTB,0
    CLRF ADRESHIGHY

    MOVLW 0x01
    MOVWF PORTD
    CALL Retardo_200ms
    RLF PORTD,0
    MOVWF PORTD

    CALL Retardo_200ms
    RLF PORTD,0
    MOVWF PORTD

    CALL Retardo_200ms
    RLF PORTD,0
    MOVWF PORTD

    CALL Retardo_200ms
RETURN


AXIS_Y_DOWN
    BCF PORTB,0
    CLRF ADRESLESSY

    MOVLW b'00010000'
    MOVWF PORTD
    CALL Retardo_200ms

    BCF STATUS,C
    RLF PORTD,0
    MOVWF PORTD
    CALL Retardo_200ms

    RLF PORTD,0
    MOVWF PORTD
    CALL Retardo_200ms

    RLF PORTD,0
    MOVWF PORTD

    CALL Retardo_200ms
RETURN


;Punto muerto del joystick (ningun movimiento)
DEADPOINT
    MOVLW 0x00
    MOVWF PORTC

    MOVLW 0x00
    MOVWF PORTD

    BSF PORTB,0
RETURN


;Rutina de la pulsacion del joystick
PUSH_JOYSTICK

    MOVLW 0xFF      ;Se enciende todos los leds del PORTC
    MOVWF PORTC

    MOVLW 0xFF      ;Se enciende todos los leds del PORTD
    MOVWF PORTD

    BSF PORTB,0     ;Se enciende el centro de la cruz

    CALL Retardo_500ms  ;Retardo para mantenerlo encendido 0.5s

    MOVLW 0x00      ;Se apagan todos los leds del PORTC
    MOVWF PORTC

    MOVLW 0x00      ;Se apagan todos los leds del PORTD
    MOVWF PORTD

    BCF PORTB,0     ;Se apaga el led del centro

    CALL Retardo_500ms  ;Retardo para mantenerlo apagado 0.5s

    DECFSZ CONT,1       ;Decrementa de uno en uno CONT hasta llegar a 0, asi contamos los parpadeos
    GOTO PUSH_JOYSTICK  ;Una vez llega a 0 deja el bucle

    MOVLW 0x03          ;Volvemos a restablecer el contador
    MOVWF CONT

RETURN

#include "Retardos.inc"

END