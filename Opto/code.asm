LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF

ORG 0x00

CBLOCK 0x20
    TEMP
ENDC

;========================
; CONFIGURACIÓN INICIAL
;========================

BSF STATUS, RP0        ; Banco 1

; RA0 entrada (audio)
MOVLW b'00000001'
MOVWF TRISA

; RC2 salida (PWM)
BCF TRISC, 2

; ADCON1: AN0 analógico, resto digital
MOVLW b'10000000'
MOVWF ADCON1

; Frecuencia PWM (~2–5 kHz con tu config actual)
MOVLW .124
MOVWF PR2

BCF STATUS, RP0        ; Banco 0

;========================
; CONFIG ADC
;========================

MOVLW b'10000001'      ; ADC ON, canal AN0
MOVWF ADCON0

;========================
; CONFIG PWM
;========================

MOVLW b'00001100'      ; CCP1 en modo PWM
MOVWF CCP1CON

MOVLW .62              ; Duty inicial (~50%)
MOVWF CCPR1L

; Timer2 ON, prescaler 1:4
MOVLW b'00000101'
MOVWF T2CON

CALL DELAY_ADC         ; estabilización

;========================
; LOOP PRINCIPAL
;========================

MAIN:

    CALL DELAY_ADC     ; tiempo de adquisición

    BSF ADCON0, GO     ; iniciar conversión

WAIT_ADC:
    BTFSC ADCON0, GO
    GOTO WAIT_ADC

    ; Leer audio
    MOVF ADRESH, W

    ; Enviar a PWM (modulación)
    MOVWF CCPR1L

    GOTO MAIN

;========================
; DELAY ADC (~estable)
;========================

DELAY_ADC:
    MOVLW .50
    MOVWF TEMP
D1:
    NOP
    NOP
    DECFSZ TEMP, F
    GOTO D1
    RETURN

END