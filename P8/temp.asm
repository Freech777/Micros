    LIST        P=16F877A
    #INCLUDE    <P16F877A.INC>

    __CONFIG    _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF & _CP_OFF

    CBLOCK  0x20
        LED_STATE   
        CONT1       
        CONT2
        CONT3
    ENDC

    ORG     0x0000
    GOTO    INICIO


INICIO
    BSF     STATUS, RP0    
    CLRF    TRISC           
    MOVLW   0xFF
    MOVWF   TRISB           
    BCF     STATUS, RP0    

    CLRF    PORTC          
    
    MOVLW   b'00000001'     
    MOVWF   LED_STATE

ESPERAR_INICIO
    BTFSC   PORTB, 1        
    GOTO    DETENER

    BTFSS   PORTB, 0        
    GOTO    ESPERAR_INICIO  

ESPERAR_SOLTAR_RB0
    BTFSC   PORTB, 0
    GOTO    ESPERAR_SOLTAR_RB0


BARRIDO_LOOP
    MOVF    LED_STATE, W
    MOVWF   PORTC

    CALL    DELAY_500MS_CHECK_STOP

    XORLW   0x01
    BTFSC   STATUS, Z
    GOTO    DETENER         

    BCF     STATUS, C       
    RLF     LED_STATE, F   

    MOVF    LED_STATE, W
    BTFSC   STATUS, Z
    GOTO    REINICIAR_RC0
    
    GOTO    BARRIDO_LOOP    

REINICIAR_RC0
    MOVLW   b'00000001'     
    MOVWF   LED_STATE
    GOTO    BARRIDO_LOOP

DETENER
    CLRF    PORTC           
    
    MOVLW   b'00001000'     
    MOVWF   LED_STATE

ESPERAR_SOLTAR_RB1
    BTFSC   PORTB, 1        
    GOTO    ESPERAR_SOLTAR_RB1
    
    GOTO    ESPERAR_INICIO  

DELAY_500MS_CHECK_STOP
    MOVLW   .50             
    MOVWF   CONT3
LOOP_500
    BTFSC   PORTB, 1       
    RETLW   0x01            

    MOVLW   .40             
    MOVWF   CONT2
LOOP_10
    MOVLW   .82             
    MOVWF   CONT1
LOOP_1
    NOP
    DECFSZ  CONT1, F
    GOTO    LOOP_1
    
    DECFSZ  CONT2, F
    GOTO    LOOP_10

    DECFSZ  CONT3, F
    GOTO    LOOP_500

    RETLW   0x00            
    END