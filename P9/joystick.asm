LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

ORG 0x00

CBLOCK 0x20
CONT        ; Contador para el parpadeo del push
ADRESHIGHX  ; Guarda la lectura de 8 bits del ADC
ENDC

CONFIGURACION
    BSF STATUS,RP0
BCF OPTION_REG, 7
    ; Puerto A: RA0 como entrada (Analogica)
    MOVLW 0x01
    MOVWF TRISA

    ; Puerto B: RB0 como salida (Centro), RB2 como entrada (Push button)
    MOVLW b'00000100'
    MOVWF TRISB

    ; Puerto C: RC0-RC7 todos como salidas (Derecha e Izquierda)
    CLRF TRISC

    ; Configuracion de ADCON1 (Justificado a la Izquierda, solo AN0 analogico)
    MOVLW b'00001110'
    MOVWF ADCON1

    BCF STATUS,RP0

    ; Configuracion ADCON0 (Fosc/64, Canal 0, Modulo Encendido)
    MOVLW b'10000001'
    MOVWF ADCON0

    ; Limpiar puertos de salida iniciales
    CLRF PORTC
    BCF PORTB,0

    MOVLW 0x03
    MOVWF CONT

    CALL Retardo_20ms

MAIN
    ; 1. Revisar boton PUSH
    BTFSS PORTB,2
    CALL PUSH_JOYSTICK

    ; 2. Iniciar lectura del ADC (Eje X)
    BSF ADCON0, 2       ; Levantar bandera GO/DONE
WAIT_ADC:
    CALL Retardo_20ms


    BTFSC ADCON0, 2
    GOTO WAIT_ADC       ; Esperar a que termine la conversion

    MOVF ADRESH, W
    MOVWF ADRESHIGHX    ; Guardar solo los 8 bits mas altos (0 a 255)

    ; 3. Logica de umbrales con Ventana de Histeresis
    
    ; ¿Es menor a 100? (Voltaje bajo, aprox 0V -> Derecha)
    MOVLW d'100'
    SUBWF ADRESHIGHX, W
    BTFSS STATUS, C     
    GOTO GO_RIGHT

    ; ¿Es mayor a 150? (Voltaje alto, aprox 5V -> Izquierda)
    MOVF ADRESHIGHX, W
    SUBLW d'150'
    BTFSS STATUS, C     
    GOTO GO_LEFT

    ; Si esta entre 100 y 150, el joystick esta en el centro
    CALL DEADPOINT
    GOTO MAIN

GO_RIGHT:
    CALL AXIS_X_RIGHT
    GOTO MAIN

GO_LEFT:
    CALL AXIS_X_LEFT
    GOTO MAIN


;---------------RUTINAS DE MOVIMIENTO-------------------

AXIS_X_RIGHT
    BCF PORTB, 0        ; Apaga el led del centro
    CLRF PORTC          ; Limpia el puerto completo
    
    MOVLW b'00000001'   ; Enciende RC0
    MOVWF PORTC
    CALL Retardo_200ms

    MOVLW b'00000010'   ; Enciende RC1
    MOVWF PORTC
    CALL Retardo_200ms

    MOVLW b'00000100'   ; Enciende RC2
    MOVWF PORTC
    CALL Retardo_200ms

    MOVLW b'00001000'   ; Enciende RC3
    MOVWF PORTC
    CALL Retardo_200ms
    
    CLRF PORTC          ; Limpia para el siguiente ciclo
RETURN

AXIS_X_LEFT
    BCF PORTB, 0        ; Apaga el led del centro
    CLRF PORTC          ; Limpia el puerto completo
    
    MOVLW b'00010000'   ; Enciende RC4
    MOVWF PORTC
    CALL Retardo_200ms

    MOVLW b'00100000'   ; Enciende RC5
    MOVWF PORTC
    CALL Retardo_200ms

    MOVLW b'01000000'   ; Enciende RC6
    MOVWF PORTC
    CALL Retardo_200ms

    MOVLW b'10000000'   ; Enciende RC7
    MOVWF PORTC
    CALL Retardo_200ms
    
    CLRF PORTC          ; Limpia para el siguiente ciclo
RETURN

DEADPOINT
    CLRF PORTC          ; Apaga todos los leds de los lados
    BSF PORTB,0         ; Enciende solo el led del centro (RB0)
RETURN

PUSH_JOYSTICK
    ; Enciende absolutamente todos los LEDs
    MOVLW b'11111111'
    MOVWF PORTC
    BSF PORTB,0

    CALL Retardo_500ms

    ; Apaga todos los LEDs
    CLRF PORTC
    BCF PORTB,0

    CALL Retardo_500ms

    DECFSZ CONT,1
    GOTO PUSH_JOYSTICK

    MOVLW 0x03          ; Restablecer contador para el proximo push
    MOVWF CONT
RETURN

#include "Retardos.inc"
END