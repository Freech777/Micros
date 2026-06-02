;Definimos los pines de salida del sistema

;   QTR 8A      PIC16F877A      CHANNEL
;   PIN D1      PIN RA0           AN0 (Sensor S7 - Izquierdo)
;   PIN D2      PIN RA1           AN1
;   PIN D3      PIN RA2           AN2
;   PIN D4      PIN RA3           AN3
;   PIN D5      PIN RA5           AN4
;   PIN D6      PIN RE0           AN5
;   PIN D7      PIN RE1           AN6
;   PIN D8      PIN RE2           AN7 (Sensor S0 - Derecho)
;   PIN IR      VCC 5V

;============Modulos PWM para motores a driver========
;   PWM     PIC16F877A      DRIVER TB6612FNG
;   CCP1       RC2          PWMB (Motor Derecho)
;   CCP2       RC1          PWMA (Motor Izquierdo)

;============Modulos de logica de los motores===================
;   PIC16F877A      DRIVER TB6612FNG
;   PIN RD0             AIN1 (Dir Motor Izquierdo)
;   PIN RD1             AIN2 (Dir Motor Izquierdo)
;   PIN RD2             BIN1 (Dir Motor Derecho)
;   PIN RD3             BIN2 (Dir Motor Derecho)
;   PIN RB0         Boton de inicio

    LIST p=16F877A
    INCLUDE <p16F877A.inc>

    __CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

    CBLOCK 0x20
;==========================================================================================
; Variables de los sensores (Solo usamos los 8 bits altos, justificado a la izquierda)
;==========================================================================================
    VAL_AN0_H
    VAL_AN1_H
    VAL_AN2_H
    VAL_AN3_H
    VAL_AN4_H
    VAL_AN5_H
    VAL_AN6_H
    VAL_AN7_H
    CONT_RETARDO_CAP   ; Retardo para espera de carga del capacitor del ADC
;==========================================================================================
; Variables para generar el retardo de 3 segundos
;==========================================================================================
    CONT_INT
    CONT_MID
    CONT_EXT
;==========================================================================================
; Variables para operaciones lógicas
;==========================================================================================
    UMBRAL_ADC      ; Valor de corte (Blanco/Negro)
    ESTADO_SENSORES ; Almacena el byte final (ej. b'01111110')
    ENDC

    ORG 0x0000
    GOTO CONFIGURACION

;========================================
; CONFIGURACIÓN DE PUERTOS Y MÓDULOS
;========================================
CONFIGURACION:
    BSF     STATUS, RP0     ; Cambiar al Banco 1
    
    ; Configuración de Entradas Analógicas
    MOVLW   0xFF
    MOVWF   TRISA
    BSF     TRISE, 0
    BSF     TRISE, 1
    BSF     TRISE, 2
    
    ; Configuración del Botón (Entrada)
    MOVLW   b'00000001'
    MOVWF   TRISB
    
    ; Configuración de Salidas para el Driver de Motores
    BCF     TRISC, 1        ; RC1/CCP2 Salida (PWMA)
    BCF     TRISC, 2        ; RC2/CCP1 Salida (PWMB)
    BCF     TRISD, 0        ; RD0 Salida (AIN1)
    BCF     TRISD, 1        ; RD1 Salida (AIN2)
    BCF     TRISD, 2        ; RD2 Salida (BIN1)
    BCF     TRISD, 3        ; RD3 Salida (BIN2)

    ; Configuración del ADC (Justificado a la IZQUIERDA = 0, Todos Analógicos)
    MOVLW   b'00000000'
    MOVWF   ADCON1
    
    ; Configurar Timer2 para los módulos PWM (~3.9 kHz de frecuencia)
    MOVLW   .255            ; Carga el periodo máximo
    MOVWF   PR2
    
    BCF     STATUS, RP0     ; Regresar al Banco 0

    ; Activar los módulos PWM en CCP1 y CCP2
    MOVLW   b'00001100'     ; Modo PWM
    MOVWF   CCP1CON
    MOVWF   CCP2CON
    BSF     T2CON, 2        ; Encender Timer2 (TMR2ON = 1)

    ; Cargar el valor del umbral (Ajustar en pista)
    MOVLW   .125            
    MOVWF   UMBRAL_ADC

;========================================
; ESPERA DEL BOTÓN DE INICIO
;========================================
INICIO:
    BTFSC   PORTB, 0        ; ¿Se presionó el botón? (Asumiendo lógica positiva)
    GOTO    ESPERA_3s
    GOTO    INICIO          ; Si no, sigue esperando

ESPERA_3s:
    CALL    RETARDO_3s

;========================================
; BUCLE PRINCIPAL
;========================================
MAIN:
    CALL    CANALES_ADC        ; 1. Leer voltajes analógicos
    CALL    BINARIZAR_SENSORES ; 2. Convertir voltajes a ceros y unos
    CALL    TOMAR_DECISION     ; 3. Analizar byte y mover motores
    GOTO    MAIN               ; Repetir infinitamente

;========================================
; RUTINA: LEER LOS 8 CANALES ADC
;========================================
CANALES_ADC:
    ; AN0
    MOVLW   b'01000001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN0_H

    ; AN1
    MOVLW   b'01001001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN1_H

    ; AN2
    MOVLW   b'01010001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN2_H

    ; AN3
    MOVLW   b'01011001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN3_H

    ; AN4
    MOVLW   b'01100001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN4_H

    ; AN5
    MOVLW   b'01101001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN5_H

    ; AN6
    MOVLW   b'01110001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN6_H

    ; AN7
    MOVLW   b'01111001'
    MOVWF   ADCON0
    CALL    LECTURA_ADC
    MOVF    ADRESH, W
    MOVWF   VAL_AN7_H

    RETURN

LECTURA_ADC:
    CALL    RETARDO_20us
    BSF     ADCON0, 2       ; Iniciar conversión (GO/DONE)
ESPERAR_ADC:
    BTFSC   ADCON0, 2
    GOTO    ESPERAR_ADC     ; Esperar a que termine
    RETURN

;========================================
; RUTINA: BINARIZAR (CREAR EL BYTE MÁGICO)
;========================================
BINARIZAR_SENSORES:
    CLRF    ESTADO_SENSORES

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN0_H, W
    RLF     ESTADO_SENSORES, F

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN1_H, W
    RLF     ESTADO_SENSORES, F

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN2_H, W
    RLF     ESTADO_SENSORES, F

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN3_H, W
    RLF     ESTADO_SENSORES, F

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN4_H, W
    RLF     ESTADO_SENSORES, F

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN5_H, W
    RLF     ESTADO_SENSORES, F

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN6_H, W
    RLF     ESTADO_SENSORES, F

    MOVF    UMBRAL_ADC, W
    SUBWF   VAL_AN7_H, W
    RLF     ESTADO_SENSORES, F

    RETURN

;========================================
; RUTINA: TOMA DE DECISIONES (LÍNEA 4 CM)
;========================================
TOMAR_DECISION:
    ; === CASO 1: CENTRADO PERFECTO ===
    MOVF    ESTADO_SENSORES, W
    XORLW   b'01111110'
    BTFSC   STATUS, Z
    GOTO    ACCION_AVANZAR

    ; === CASO 2: DESVÍO LEVE IZQUIERDA ===
    MOVF    ESTADO_SENSORES, W
    XORLW   b'11111100'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_IZQ_LEVE

    MOVF    ESTADO_SENSORES, W
    XORLW   b'11111000'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_IZQ_LEVE

    ; === CASO 3: DESVÍO FUERTE IZQUIERDA ===
    MOVF    ESTADO_SENSORES, W
    XORLW   b'11100000'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_IZQ_FUERTE

    MOVF    ESTADO_SENSORES, W
    XORLW   b'11000000'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_IZQ_FUERTE

    ; === CASO 4: DESVÍO LEVE DERECHA ===
    MOVF    ESTADO_SENSORES, W
    XORLW   b'00111111'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_DER_LEVE

    MOVF    ESTADO_SENSORES, W
    XORLW   b'00011111'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_DER_LEVE

    ; === CASO 5: DESVÍO FUERTE DERECHA ===
    MOVF    ESTADO_SENSORES, W
    XORLW   b'00000111'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_DER_FUERTE

    MOVF    ESTADO_SENSORES, W
    XORLW   b'00000011'
    BTFSC   STATUS, Z
    GOTO    ACCION_GIRO_DER_FUERTE

    ; === CASO POR DEFECTO: SE PERDIÓ O SE CRUZÓ ===
    GOTO    ACCION_PERDIDO

;========================================
; RUTINAS DE ACCIÓN DE MOTORES (TB6612FNG)
;========================================
; Motores hacia adelante: AIN1=1, AIN2=0 / BIN1=1, BIN2=0
; Motores en reversa:     AIN1=0, AIN2=1 / BIN1=0, BIN2=1
; Velocidad (0 a 255) cargada en CCPR2L (Motor A - Izq) y CCPR1L (Motor B - Der)

ACCION_AVANZAR:
    BSF     PORTD, 0        ; AIN1
    BCF     PORTD, 1        ; AIN2
    BSF     PORTD, 2        ; BIN1
    BCF     PORTD, 3        ; BIN2
    MOVLW   .255            ; Velocidad Izquierda (100%)
    MOVWF   CCPR2L
    MOVLW   .255            ; Velocidad Derecha (100%)
    MOVWF   CCPR1L
    RETURN

ACCION_GIRO_IZQ_LEVE:
    BSF     PORTD, 0
    BCF     PORTD, 1
    BSF     PORTD, 2
    BCF     PORTD, 3
    MOVLW   .100            ; Velocidad Izquierda reducida
    MOVWF   CCPR2L
    MOVLW   .255            ; Velocidad Derecha a tope
    MOVWF   CCPR1L
    RETURN

ACCION_GIRO_IZQ_FUERTE:
    BCF     PORTD, 0        ; Frena o invierte motor izquierdo
    BSF     PORTD, 1
    BSF     PORTD, 2
    BCF     PORTD, 3
    MOVLW   .150            ; Izquierdo en reversa moderada
    MOVWF   CCPR2L
    MOVLW   .255            ; Derecho adelante
    MOVWF   CCPR1L
    RETURN

ACCION_GIRO_DER_LEVE:
    BSF     PORTD, 0
    BCF     PORTD, 1
    BSF     PORTD, 2
    BCF     PORTD, 3
    MOVLW   .255            ; Velocidad Izquierda a tope
    MOVWF   CCPR2L
    MOVLW   .100            ; Velocidad Derecha reducida
    MOVWF   CCPR1L
    RETURN

ACCION_GIRO_DER_FUERTE:
    BSF     PORTD, 0
    BCF     PORTD, 1
    BCF     PORTD, 2        ; Frena o invierte motor derecho
    BSF     PORTD, 3
    MOVLW   .255            ; Izquierdo adelante
    MOVWF   CCPR2L
    MOVLW   .150            ; Derecho en reversa moderada
    MOVWF   CCPR1L
    RETURN

ACCION_PERDIDO:
    ; Detener motores temporalmente
    BCF     PORTD, 0
    BCF     PORTD, 1
    BCF     PORTD, 2
    BCF     PORTD, 3
    CLRF    CCPR2L
    CLRF    CCPR1L
    RETURN

;========================================
; RUTINAS DE RETARDO
;========================================
RETARDO_20us:
    MOVLW   0x06
    MOVWF   CONT_RETARDO_CAP
LOOP_20us:
    DECFSZ  CONT_RETARDO_CAP, F
    GOTO    LOOP_20us
    RETURN

RETARDO_3s:
    MOVLW   0x12
    MOVWF   CONT_EXT
LOOP2:
    MOVLW   .250            
    MOVWF   CONT_MID
LOOP1:
    MOVLW   .250
    MOVWF   CONT_INT
LOOP0:
    NOP
    DECFSZ  CONT_INT, F
    GOTO    LOOP0
    DECFSZ  CONT_MID, F
    GOTO    LOOP1
    DECFSZ  CONT_EXT, F
    GOTO    LOOP2
    RETURN

    END