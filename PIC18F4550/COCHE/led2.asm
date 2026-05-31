LIST P=18F4550
    #include <p18f4550.inc>



; --- CONFIGURACIÓN DE FUSIBLES (CRÍTICO) ---
    ; Configuración para cristal externo de 20MHz y núcleo a 48MHz
    
    CONFIG PLLDIV = 5         ; Divide el cristal de 20MHz entre 5 (para dar los 4MHz que requiere el PLL)
    CONFIG CPUDIV = OSC1_PLL2 ; Divide el reloj del PLL (96MHz) entre 2 = 48MHz de velocidad final
    CONFIG FOSC = HSPLL_HS    ; Enciende el oscilador High Speed y activa el PLL
    
    CONFIG WDT = OFF          ; APAGA el Watchdog Timer (Para que no se reinicie solo)
    CONFIG LVP = OFF          ; APAGA la programación en bajo voltaje (Evita reseteos fantasma)
    CONFIG PBADEN = OFF       ; Inicia el Puerto B como digital (Súper útil luego para tu QTR-8A)
    CONFIG MCLRE = ON         ; Activa el botón de Reset físico de tu placa Intesc
    CONFIG BORV = 3           ; Configura el voltaje de reseteo por baja batería al mínimo
    ; --- Reserva de memoria para las variables del retardo ---
    ; Usamos la memoria RAM a partir de la dirección 0x20
    CBLOCK 0x20
        contador1
        contador2
        contador3
    ENDC

    ; --- Vector de Reset ---
    ORG 0x0000          ; Dirección donde el PIC empieza al encender
    GOTO INICIO         ; Saltamos la zona de interrupciones

    ; --- Programa Principal ---
    ORG 0x0020
INICIO:
    ; 1. Configurar pines como digitales (El paso crítico)
    MOVLW 0x0F          ; Cargamos el valor hexadecimal 0F en el acumulador (W)
    MOVWF ADCON1        ; Lo movemos al registro ADCON1

    ; 2. Configurar el Puerto E como salida
    CLRF TRISE          ; Limpiamos (ponemos en 0) todo el registro TRISE
    CLRF LATE           ; Apagamos todos los pines de LATE para empezar limpios

BUCLE_PRINCIPAL:
    ; --- ESTADO 1: Color ROJO (RE0 = 1, RE1 = 0, RE2 = 0) ---
    MOVLW b'00000001'   ; En binario es más fácil ver qué pin estamos encendiendo
    MOVWF LATE          ; Escribimos en el puerto E
    CALL RETARDO_2S     ; Llamamos a la subrutina de tiempo

    ; --- ESTADO 2: Color VERDE (RE0 = 0, RE1 = 1, RE2 = 0) ---
    MOVLW b'00000010'
    MOVWF LATE
    CALL RETARDO_2S

    ; --- ESTADO 3: Color AZUL (RE0 = 0, RE1 = 0, RE2 = 1) ---
    MOVLW b'00000100'
    MOVWF LATE
    CALL RETARDO_2S

    BRA BUCLE_PRINCIPAL ; Salto relativo para repetir infinitamente


    ; -----------------------------------------------------------------
    ; SUBRUTINA DE RETARDO
    ; Genera una pausa usando 3 bucles anidados.
    ; Los valores cargados (0x5A, 0xFF, 0xFF) están calculados de forma 
    ; aproximada para 2 segundos asumiendo un reloj de 48 MHz.
    ; -----------------------------------------------------------------
RETARDO_2S:
    MOVLW 0x5A          ; Carga el contador principal (ajustar si es muy rápido/lento)
    MOVWF contador3
Lazo3:
    MOVLW 0xFF
    MOVWF contador2
Lazo2:
    MOVLW 0xFF
    MOVWF contador1
Lazo1:
    DECFSZ contador1, F ; Decrementa contador1, salta la siguiente si llega a 0
    BRA Lazo1           ; Si no es 0, repite Lazo1
    
    DECFSZ contador2, F ; Decrementa contador2
    BRA Lazo2           ; Si no es 0, recarga contador1 y repite
    
    DECFSZ contador3, F ; Decrementa contador3
    BRA Lazo3           ; Si no es 0, recarga contador2 y repite
    
    RETURN              ; Regresa al BUCLE_PRINCIPAL cuando todos llegan a 0

    END                 ; Fin del código fuente