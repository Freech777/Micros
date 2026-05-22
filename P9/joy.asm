LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

ORG 0x00

CBLOCK 0x20
CONT            ; Se usa para el conteo de 3 veces el parpadeo de el push
VAR_CENTRO

ADRESLESSX
ADRESHIGHX

ADRESLESSY
ADRESHIGHY

; --- NUEVAS VARIABLES PARA LOS 74HC595 ---
LEDS_X          ; Registro sombra para el antiguo PORTC (Axis X)
LEDS_Y          ; Registro sombra para el antiguo PORTD (Axis Y)
SHIFT_COUNT     ; Contador para enviar los 16 bits
TEMP_X          ; Variable temporal para el desplazamiento
TEMP_Y          ; Variable temporal para el desplazamiento
ENDC


CONFIGURACION

    BSF STATUS,RP0

    ; Entradas de manera analogica RA0 (Axis X) y RA1 (Axis Y)
    MOVLW 0x03      
    MOVWF TRISA

    ; PORTB
    BCF TRISB,0     ; Salida para el centro del joystick
    BSF TRISB,1     ; Entrada para selector AXIS X / AXIS Y
    BSF TRISB,2     ; Entrada para el Push button (asumido por lógica)

    ; Puerto C: Solo RC0 (Data), RC1 (Clock) y RC2 (Latch) como salidas
    MOVLW b'11111000' 
    MOVWF TRISC

    ; Puerto D: Ya no se usa para LEDs, se puede dejar como entrada o salida
    MOVLW 0xFF
    MOVWF TRISD

    ; Configuracion de ADCON1
    MOVLW b'10001001'   
    MOVWF ADCON1

    ; Resgresamos al banco 0,0
    BCF STATUS,RP0

    MOVLW b'10000110'   
    MOVWF ADCON0

    BCF PORTB,0
    
    ; --- Inicializar Registros Sombra en 0 ---
    CLRF LEDS_X
    CLRF LEDS_Y
    CALL UPDATE_595     ; Actualizamos los chips para apagar todo

    MOVLW 0x03          ; Valor de 3 al cont
    MOVWF CONT

    MOVLW 0xFF
    MOVWF VAR_CENTRO

    CALL Retardo_20ms
    BSF ADCON0,2

MAIN                
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
    MOVWF ADRESLESSX        

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
    MOVWF LEDS_X
    CALL UPDATE_595
    CALL Retardo_200ms

    BCF STATUS,C
    RLF LEDS_X,0
    MOVWF LEDS_X
    CALL UPDATE_595
    CALL Retardo_200ms

    RLF LEDS_X,0
    MOVWF LEDS_X
    CALL UPDATE_595
    CALL Retardo_200ms

    RLF LEDS_X,0
    MOVWF LEDS_X
    CALL UPDATE_595
    CALL Retardo_200ms
RETURN

AXIS_X_LEFT
    BCF PORTB,0
    CLRF ADRESLESSX

    MOVLW 0x01
    MOVWF LEDS_X
    CALL UPDATE_595
    CALL Retardo_200ms
    
    RLF LEDS_X,0
    MOVWF LEDS_X
    CALL UPDATE_595
    CALL Retardo_200ms
    
    RLF LEDS_X,0
    MOVWF LEDS_X
    CALL UPDATE_595
    CALL Retardo_200ms
    
    RLF LEDS_X,0
    MOVWF LEDS_X
    CALL UPDATE_595
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
RETURN  

AXIS_Y_UP
    BCF PORTB,0
    CLRF ADRESHIGHY

    MOVLW 0x01
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms
    
    RLF LEDS_Y,0
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms
    
    RLF LEDS_Y,0
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms
    
    RLF LEDS_Y,0
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms
RETURN

AXIS_Y_DOWN
    BCF PORTB,0
    CLRF ADRESLESSY

    MOVLW b'00010000'
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms

    BCF STATUS,C
    RLF LEDS_Y,0
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms

    RLF LEDS_Y,0
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms

    RLF LEDS_Y,0
    MOVWF LEDS_Y
    CALL UPDATE_595
    CALL Retardo_200ms
RETURN


;Punto muerto del joystick
DEADPOINT
    MOVLW 0x00
    MOVWF LEDS_X
    MOVWF LEDS_Y
    CALL UPDATE_595

    BSF PORTB,0
RETURN


;Rutina de la pulsacion del joystick
PUSH_JOYSTICK

    MOVLW 0xFF      
    MOVWF LEDS_X
    MOVWF LEDS_Y
    CALL UPDATE_595     ; Enciende todos los LEDs a traves del 595

    BSF PORTB,0         ; Centro

    CALL Retardo_500ms  

    MOVLW 0x00      
    MOVWF LEDS_X
    MOVWF LEDS_Y
    CALL UPDATE_595     ; Apaga todos los LEDs a traves del 595

    BCF PORTB,0         ; Apaga centro

    CALL Retardo_500ms  

    DECFSZ CONT,1       
    GOTO PUSH_JOYSTICK  

    MOVLW 0x03          
    MOVWF CONT

RETURN


; -----------------------------------------------------------------
; NUEVA RUTINA: UPDATE_595
; Esta rutina toma las variables LEDS_X y LEDS_Y y las envia en serie
; a los registros de desplazamiento.
; Orden de envio: Primero sale LEDS_Y (terminara en el segundo 74HC595)
;                 Luego sale LEDS_X (se quedara en el primer 74HC595)
; -----------------------------------------------------------------
UPDATE_595
    BCF PORTC, 2        ; Pin RC2 (LATCH) en Bajo

    ; Hacemos copias de los registros para no destruir los originales al rotar
    MOVF LEDS_X, W
    MOVWF TEMP_X
    MOVF LEDS_Y, W
    MOVWF TEMP_Y

    MOVLW d'16'         ; Vamos a desplazar 16 bits
    MOVWF SHIFT_COUNT

    BCF STATUS, C       ; Limpiar carry para evitar basura en el primer bit

SHIFT_LOOP
    ; Desplazamos TEMP_X a la izquierda (El bit 7 de X pasa al Carry)
    RLF TEMP_X, F       
    
    ; Desplazamos TEMP_Y a la izquierda 
    ; (El bit 7 de Y pasa al Carry, y el bit 7 de X que estaba en Carry entra al bit 0 de Y)
    RLF TEMP_Y, F       

    ; Verificamos que quedo en el Carry (El MSB de Y) y lo sacamos por DATA (RC0)
    BTFSS STATUS, C     
    BCF PORTC, 0        ; Si Carry es 0, pon DATA en 0
    BTFSC STATUS, C     
    BSF PORTC, 0        ; Si Carry es 1, pon DATA en 1

    ; Damos un pulso al CLOCK (RC1) para que el 595 lea el DATA
    BSF PORTC, 1        
    NOP
    BCF PORTC, 1        

    DECFSZ SHIFT_COUNT, F
    GOTO SHIFT_LOOP

    ; Una vez enviados los 16 bits, subimos el LATCH para actualizar los LEDs visualmente
    BSF PORTC, 2        
RETURN

#include "Retardos.inc"

END