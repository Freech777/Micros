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

; --- Definición de variables para el retardo ---
    ; Usamos la memoria RAM a partir de la dirección 0x20
Contador1 equ 0x20
Contador2 equ 0x21
Contador3 equ 0x22

    ; --- Vector de Reset ---
    ORG 0x0000          ; El programa arranca aquí
    goto Inicio

    ; --- Programa Principal ---
    ORG 0x0020          ; Dejamos espacio por si luego usas interrupciones
Inicio:
    ; 1. Configurar pines del Puerto A y B como E/S digitales
    movlw 0x0F          ; Cargamos 0000 1111 (0x0F) en W
    movwf ADCON1        ; Lo pasamos a ADCON1 (apaga los canales analógicos)

    ; 2. Configurar puertos A y B como salidas (0 = Salida)
    clrf TRISA          ; Limpiamos TRISA (Todos los pines son salidas)
    clrf TRISB          ; Limpiamos TRISB (Todos los pines son salidas)

    ; 3. Inicializar los puertos apagados
    clrf LATA
    clrf LATB

Bucle_Principal:
    ; --- Encender Pines ---
    ; PA0 a PA5 (0x3F = 0011 1111)
    movlw 0x3F
    movwf LATA
    
    ; PB0 a PB7 (0xFF = 1111 1111)
    movlw 0xFF
    movwf LATB

    ; Llamar a la rutina de espera
    call Retardo

    ; --- Apagar Pines ---
    clrf LATA
    clrf LATB

    ; Llamar a la rutina de espera
    call Retardo

    ; Repetir el ciclo infinitamente
    goto Bucle_Principal


    ; --- Subrutina de Retardo ---
    ; Consiste en 3 bucles anidados para "perder el tiempo"
    ; y que el parpadeo sea visible al ojo humano.
Retardo:
    movlw d'100'        ; Carga el valor decimal 100
    movwf Contador3
Lazo3:
    movlw d'200'        ; Carga el valor decimal 200
    movwf Contador2
Lazo2:
    movlw d'200'        ; Carga el valor decimal 200
    movwf Contador1
Lazo1:
    decfsz Contador1, F ; Decrementa Contador1, salta si es 0
    goto Lazo1
    
    decfsz Contador2, F ; Decrementa Contador2, salta si es 0
    goto Lazo2
    
    decfsz Contador3, F ; Decrementa Contador3, salta si es 0
    goto Lazo3
    
    return              ; Regresa al Bucle_Principal

    END                 ; Fin del código