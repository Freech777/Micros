LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF


CBLOCK 0x20
;Valores que necesitamos leer de los 8 canales del ADC del los sensores seguidores de linea
    VAL_AN0_H, VAL_AN0_L
    VAL_AN1_H, VAL_AN1_L
    VAL_AN2_H, VAL_AN2_L
    VAL_AN3_H, VAL_AN3_L
    VAL_AN4_H, VAL_AN4_L
    VAL_AN5_H, VAL_AN5_L
    VAL_AN6_H, VAL_AN6_L
    VAL_AN7_H, VAL_AN7_L
    CONTADOR_RETARDO   ;Retardo para espera de carga de la conversion del ADC

ENDC


CONFIGURACION
BSF STATUS,RP0
MOVLW 0xFF
MOVWF TRISA

BSF TRISE,0
BSF TRISE,1
BSF TRISE,2

MOVLW b'01000000'
MOVWF TRISB

MOVLW b'10000000'
MOVWF ADCON1
BCF STATUS,RP0




MAIN



CANALES_ADC
;========================================
;Rutina de lectura de los canales AN0-AN7
;========================================

;La lectura de los canales de manera individualmente se repiten
;La estructura es la siguiente
;1._Se pasa la configuracion correspondiente de ADCON0
;2._Se llama a la rutina de lectura de el canal activo
;3._Se espera 20us a que se haga la conversion
;4._Teniendo los valores en ADRESH y ADRESL se mueven a las variables temporales de cada canal
;5._Se repite la rutina hasta terminar todos los canales

    ;Lectura del canal 0 (AN0)
    MOVLW b'01000001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L

    ;Lectura del canal 1 (AN1)
    MOVLW b'01001001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L

    ;Lectura del canal 2 (AN2)
    MOVLW b'01010001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L
    ;Lectura del canal 3 (AN3)
    MOVLW b'01011001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L
    ;Lectura del canal 4 (AN4)
    MOVLW b'01100001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L
    ;Lectura del canal 5 (AN5)
    MOVLW b'01101001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L
    ;Lectura del canal 6 (AN6)
    MOVLW b'01110001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L
    ;Lectura del canal 7 (AN7)
    MOVLW b'01111001'
    MOVWF ADCON0
    CALL LECTURA_ADC

    MOVF ADRESH,0
    MOVWF VAL_AN0_H
    BSF STATUS,RP0
    MOVF ADRESL,0
    BCF STATUS,RP0
    MOVWF VAL_AN0_L

    RETURN

;========================================



;========================================
;Rutinas de lectura y espera del ADC
;========================================
LECTURA_ADC
    CALL RETARDO_20us
    BSF ADCON0,2
ESPERAR_ADC
    BTFSC ADCON0,2
    GOTO ESPERAR_ADC
    RETURN
;========================================





;======================================== RETARDOS GENERALES ========================================

;========================================
;Contador del capacitor interno del ADC
;========================================

RETARDO_20us
    MOVLW 0x06
    MOVWF CONTADOR_RETARDO
LOOP_20us
    DECFSZ CONTADOR_RETARDO, 1
    GOTO LOOP_20us
    RETURN
;========================================
END