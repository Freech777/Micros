LIST p=16F877A
INCLUDE <p16F877A.inc>

__CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_OFF & _LVP_OFF


; Origen en donde parte el codigo
ORG		0x00


; Bloque de memoria para no andar declarando
CBLOCK  0x20
    nibble_bajo     ; Variable de nibbl bajo
    nibble_alto     ; Variable de nibble alto
    resultado       ; Variable para unir los 2 nibbles
    ENDC

CONFIGURACION
bsf     STATUS,RP0  ; Se cambia al banco 1 poniendo los bits 01
movlw   0xFF        ; Le damos la literal ceros al registro de trabajo
movwf   TRISB       ; Se le da la configuracion en ceros todos los bits DE PORTB para entrada
movlw   0x00        ; Literal ceros
movwf   TRISD       ; Se pasa al PORTD
bcf     STATUS,RP0  ; Regresamos al banco 0 poniendo bits 00
movlw   0xFF        ; Iniciamos el circuito con los leds apagados
movwf   PORTD       ; Se lo pasamos al PORTD

goto    MAIN        ; Se va a la subrutina MAIN

MAIN
movf    PORTB,W     ; Se lee lo que haya en el PORTB
andlw   0x0F        ; Se hace una "mascara" haciendo que quede tal ejemplo xxxx0101 
movwf   nibble_bajo ; Se guarda en la variable

movf    nibble_bajo,W ; Movemos nuestro resultado anterior al registro de trabajo
movwf   nibble_alto   ; Movemos nuestro w a la variable
swapf   nibble_alto,F ; Le hacemos un swapf(reves) tal que ejemplo 0101xxxx

movf    nibble_bajo,W ; Ya que tenemos ambas partes los unimos en la variables resultados
iorwf   nibble_alto,W
movwf   resultado

; Movemos los bits a el PORTD
movf    resultado,W
movwf   PORTD

nop
nop
nop

goto MAIN    

    END
