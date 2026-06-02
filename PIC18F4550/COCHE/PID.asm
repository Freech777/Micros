; PIC18F4550 Configuration Bit Settings

; Assembly source line config statements


;Se van a definir los siguientes pines ADC para el modulo QTR-A8

;   QTR-8A      PIC18F4550      CHANNEL
;   PIN D1      PIN PB0          AN12
;   PIN D2      PIN PB1          AN10
;   PIN D3      PIN PB2          AN8
;   PIN D4      PIN PB4          AN11
;   PIN D5      PIN PA0          AN0
;   PIN D6      PIN PA1          AN1
;   PIN D7      PIN PA2          AN2
;   PIN D8      PIN PA3          AN3

;   PIN IR      PIN PB5


;============Modulos PWM para motores a driver===========
;   PWM                 PIC18F4550
;   (Simple ECCP)       PIN PC1
;   (CCP)               PIN PC2


;============Modulos de logica de los motores avanzar y retroceder=======
;   PIC18F4550       DRIVER TB717     
;   PIN PD0              AIN1
;   PIN PD1              AIN2
;   PIN PD2              BIN1
;   PIN PD3              BIN2
;   PIN PC1              PWMA
;   PIN PC2              PWMB 

;============Salidas de el driver a los motores=================
;   DRIVER TB717      MOTORES
;       A01           IZQUIERDO (IZQ)
;       A02           IZQUIERDO (DER)
;       B01           DERECHO (IZQ)
;       B02           DERECHO (DER)
    LIST P=18F4550
    #include "p18f4550.inc"

; --- CONFIGURACIÓN DE FUSIBLES (CRÍTICO) ---
    ; Configuración para cristal externo de 20MHz y núcleo a 48MHz
    
    CONFIG PLLDIV = 5         ; Divide el cristal de 20MHz entre 5 (para dar los 4MHz que requiere el PLL)
    CONFIG CPUDIV = OSC1_PLL2 ; Divide el reloj del PLL (96MHz) entre 2 = 48MHz de velocidad final
    CONFIG FOSC = HSPLL_HS    ; Enciende el oscilador High Speed y activa el PLL
    
    CONFIG WDT = OFF          ; APAGA el Watchdog Timer (Para que no se reinicie solo)
    CONFIG LVP = OFF          ; APAGA la programación en bajo voltaje (Evita reseteos fantasma)
    CONFIG PBADEN = OFF       ; Inicia el Puerto B como digital (Súper útil luego para tu QTR-8A)
    CONFIG MCLRE = ON         ; Activa el botón de Reset físico de tu placa Intesc

    ; --- Ajustes Defensivos para Competencia ---
    ;CONFIG BOREN = OFF         APAGA el reseteo por caída de voltaje (Inmunidad al ruido de motores)
    CONFIG XINST = OFF        ; APAGA instrucciones extendidas (Obligatorio para MPASM clásico)

    CBLOCK 0x20
; Variables para la lectura del QTR-8A
        Posicion_L
        Posicion_H
        
        ; Variables del PID
        Setpoint_L
        Setpoint_H
        Error_L
        Error_H
        Error_Anterior_L
        Error_Anterior_H
        
        ; Salida final al módulo CCP (PWM)
        Control_L
        Control_H

        ;Valores de los sensores
        Sens0
        Sens1
        Sens2
        Sens3
        Sens4
        Sens5
        Sens6
        Sens7

        ;Suma de derecha a izquierda para el error
        Suma_Der_L
        Suma_Der_H
        Suma_Izq_L
        Suma_Izq_H
        Peso        ; Variable temporal para cargar 10, 20, 30 o 40

        ;Terminos para la variable proporcional
        Kp              ; Variable de 8 bits (Configurable desde otra parte del código)
        Banderas        ; Registro de 1 byte. Usaremos el Bit 0 para guardar la dirección (0=Der, 1=Izq)
        Termino_P_L     ; 16 bits para el resultado final de P
        Termino_P_H

        ;Terminos para la variable derivativa
        Kd              ; Variable de 8 bits (Constante derivativa)
        Delta_Error_L   ; Variable temporal para (Error - Error_Anterior)
        Delta_Error_H
        Termino_D_L     ; Resultado final del término D
        Termino_D_H
        ; Nota: Usaremos el Bit 1 del registro 'Banderas' para guardar 
        ; la dirección de este "freno" (0=Suma a la derecha, 1=Suma a la izquierda) 

        ;Terminos para PWM de los motores
        Velocidad_Base
        PWM_Izq_Temp_L  ; Variables temporales de 16 bits para guardar
        PWM_Izq_Temp_H  ; el cálculo antes de pasarlo por los límites
        PWM_Der_Temp_L
        PWM_Der_Temp_H

        contador1
        contador2

    ENDC

; --- VECTORES DE INICIO ---
    ORG 0x0000          ; Vector de Reset
    GOTO CONFIGURACION

    ORG 0x0008          ; Vector de Interrupción de ALTA Prioridad
    GOTO RUTINA_PID     ; Saltamos a la rutina principal del PID

    ; ORG 0x0018        ; Vector de baja prioridad (No lo usaremos por ahora)
    ; RETFIE

    ORG 0x0020
CONFIGURACION
    ; 1. Configurar Puertos según tu tabla
    ; (Aquí iría la configuración de TRISA, TRISB, TRISC, TRISD y ADCON1)

; --- PUERTO A (Sensores D5, D6, D7, D8 en PA0 a PA3) ---
    ; Necesitan ser ENTRADAS para leer el voltaje
    MOVLW b'00001111'
    MOVWF TRISA

    ; --- PUERTO B (Sensores D1-D4 en PB0, PB1, PB2, PB4) ---
    ; PB5 es el PIN IR (Salida para encender los LEDs del QTR-8A)
    MOVLW b'00011111'   ; PB4, PB2, PB1, PB0 como entradas. PB5 como salida.
    MOVWF TRISB

    MOVLW 0xFF
    MOVWF TRISC

    MOVLW 0xFF
    MOVWF TRISD

    CALL CONFIGURAR_ADC


    ; 2. Configurar Timer0 (Asumiendo 48MHz, Fosc/4 = 12MHz, ciclo de 83.3 ns)
    ; Usaremos Timer0 a 16 bits para tener resolución fina en el retardo
    MOVLW b'10000101'   ; TMR0 ON, 16 bits, Prescaler 1:64
    MOVWF T0CON
    

    CALL CONFIGURAR_PWM
    ; 3. Habilitar Interrupciones
    BSF INTCON, TMR0IE  ; Habilitar interrupción por desbordamiento del Timer0
    BCF INTCON, GIE     ; Habilitar interrupciones globales
    BSF INTCON, PEIE    ; Habilitar interrupciones periféricas

BUCLE_PRINCIPAL

    BTFSC PORTB, 3
    BRA BUCLE_PRINCIPAL

    CALL RETARDO_DEBOUNCE

    BTFSC PORTB, 3
    BRA BUCLE_PRINCIPAL

ESPERAR_LIBERACION
    BTFSS PORTB,3
    BRA ESPERAR_LIBERACION

    BSF INTCON,GIE

LAZO_CARRERA

    BRA LAZO_CARRERA

RUTINA_PID
    ; Verificamos si la interrupción fue causada por el Timer0
    BTFSS INTCON, TMR0IF
    BRA SALIR_INTERRUPCION ; Si no fue el Timer0, salimos

    ; --- INICIO DEL CICLO PID ---
    
    ; PASO 1: Leer los sensores QTR-8A (Puertos A y B) y calcular "Posicion"
    ; [Aquí irá la lógica del ADC y Promedio Ponderado]

    CALL Lectura_ADC 
    
    ; PASO 2: Calcular Error (Error = Setpoint - Posicion)
    ; [Aquí irá una rutina de RESTA de 16 bits]

    CALL CALCULAR_ERROR

    ; PASO 3: Calcular Término Derivativo (D = Kd * (Error - Error_Anterior))
    ; [Resta y Multiplicación]

    CALL CALCULAR_DERIVATIVO

    ; PASO 4: Calcular Término Proporcional (P = Kp * Error)
    ; [Aquí irá una rutina de MULTIPLICACIÓN 8x16 bits]

    CALL CALCULAR_PROPORCIONAL

    ; PASO 5: Sumar términos de Control = P + D
    ; [Suma de 16 bits]
    CALL SUMA_PD

    ; PASO 6: Aplicar el valor de 'Control' a los registros CCPR1L y CCPR2L (PWM)
    ; Ajustando la lógica de dirección en PORTD (TB6612FNG)
    CALL CONTROL_PWM

    ; PASO 7: Preparar para el siguiente ciclo
    ; Mover Error actual a Error_Anterior para la próxima derivada
    MOVFF Error_L, Error_Anterior_L
    MOVFF Error_H, Error_Anterior_H

; --- FIN DEL CICLO PID ---

    ; Recargar el Timer0 para mantener el tiempo exacto
    ; (Valores dependen del tiempo que elijas)
    MOVLW 0x00      ; Cargar parte alta del Timer
    MOVWF TMR0H
    MOVLW 0x00      ; Cargar parte baja del Timer
    MOVWF TMR0L

    ; Limpiar la bandera de interrupción para que pueda volver a ocurrir
    BCF INTCON, TMR0IF

SALIR_INTERRUPCION
    RETFIE FAST         ; Retorna de la interrupción restaurando registros vitales

CONFIGURAR_ADC
    ; --- ADCON1: Configurar pines analógicos ---
    ; PCFG = 0010: Configura desde AN0 hasta AN12 como analógicos.
    ; Vref+ y Vref- se conectan internamente a VDD (5V) y VSS (GND).
    MOVLW b'00000010'
    MOVWF ADCON1

    ; --- ADCON2: Formato y Tiempos del ADC ---
    ; Bit 7 (ADFM) = 0 -> Justificado a la Izquierda (Solo leeremos ADRESH)
    ; Bits 5-3 (ACQT) = 111 -> 20 TAD (Tiempo de adquisición automático máximo)
    ; Bits 2-0 (ADCS) = 110 -> Fosc/64 (El reloj correcto si trabajas a 48MHz)
    MOVLW b'00111110'   
    MOVWF ADCON2
    RETURN

; -------------------------------------------------------------------------
; RUTINA: LEER_CANAL_ADC
; Entradas: El registro W debe contener el comando del canal a leer.
; Salidas:  El registro W regresará con el valor del sensor (0 a 255).
; -------------------------------------------------------------------------
Lectura_ADC
; Leer Sensor D1 (Conectado a AN12 - PB0)
    ; Canal AN12 = 1100
    MOVLW b'00110001'   ; Comando para AN12
    CALL LEER_CANAL_ADC
    MOVWF Sens0         ; Guardar resultado en variable

; Leer Sensor D2 (Conectado a AN10 - PB1)
    ; Canal AN10 = 1010
    MOVLW b'00101001'   ; Comando para AN10
    CALL LEER_CANAL_ADC
    MOVWF Sens1         ; Guardar resultado en variable

; Leer Sensor D3 (Conectado a AN8 - PB2)
    ; Canal AN8 = 1000
    MOVLW b'00100001'   ; Comando para AN8
    CALL LEER_CANAL_ADC
    MOVWF Sens2         ; Guardar resultado en variable


; Leer Sensor D4 (Conectado a AN11 - PB4)
    ; Canal AN11 = 1011
    MOVLW b'00101101'   ; Comando para AN11
    CALL LEER_CANAL_ADC
    MOVWF Sens3         ; Guardar resultado en variable


; Leer Sensor D5 (Conectado a AN0 - PA0)
    ; Canal AN0 = 0000
    MOVLW b'00000001'   ; Comando para AN0
    CALL LEER_CANAL_ADC
    MOVWF Sens4         ; Guardar resultado en variable


; Leer Sensor D6 (Conectado a AN1 - PA1)
    ; Canal AN1 = 0001
    MOVLW b'00000101'   ; Comando para AN1
    CALL LEER_CANAL_ADC
    MOVWF Sens5         ; Guardar resultado en variable


; Leer Sensor D7 (Conectado a AN2 - PA2)
    ; Canal AN2 = 0010
    MOVLW b'00001001'   ; Comando para AN2
    CALL LEER_CANAL_ADC
    MOVWF Sens6         ; Guardar resultado en variable


; Leer Sensor D8 (Conectado a AN3 - PA3)
    ; Canal AN3 = 0011
    MOVLW b'00001101'   ; Comando para AN3
    CALL LEER_CANAL_ADC
    MOVWF Sens7         ; Guardar resultado en variable
    RETURN

CALCULAR_ERROR
    ; 1. Limpiar acumuladores antes de sumar
    CLRF Suma_Der_L
    CLRF Suma_Der_H
    CLRF Suma_Izq_L
    CLRF Suma_Izq_H

    ; ==========================================
    ; CÁLCULO DEL LADO DERECHO (S4 a S7)
    ; ==========================================
    
    ; --- Sensor S4 (Peso 10) ---
    MOVLW .10           ; Cargar el número 10 en decimal (.10) a W
    MULWF Sens4         ; Multiplicar W * Sens4. Resultado en PRODH:PRODL
    ; Sumar al acumulador Derecho de 16 bits
    MOVF PRODL, W       
    ADDWF Suma_Der_L, F ; Suma la parte baja
    MOVF PRODH, W
    ADDWFC Suma_Der_H, F; Suma la parte alta CON ACARREO (Carry)

    ; --- Sensor S5 (Peso 20) ---
    MOVLW .20
    MULWF Sens5
    MOVF PRODL, W
    ADDWF Suma_Der_L, F
    MOVF PRODH, W
    ADDWFC Suma_Der_H, F

    ; --- Sensor S6 (Peso 30) ---
    MOVLW .30
    MULWF Sens6
    MOVF PRODL, W
    ADDWF Suma_Der_L, F
    MOVF PRODH, W
    ADDWFC Suma_Der_H, F

    ; --- Sensor S7 (Peso 40) ---
    MOVLW .40
    MULWF Sens7
    MOVF PRODL, W
    ADDWF Suma_Der_L, F
    MOVF PRODH, W
    ADDWFC Suma_Der_H, F

; ==========================================
    ; CÁLCULO DEL LADO IZQUIERDO (S0 a S3)
    ; ==========================================
    ; (Es exactamente la misma estructura que arriba)
    
    ; --- Sensor S3 (Peso 10) ---
    MOVLW .10
    MULWF Sens3
    MOVF PRODL, W
    ADDWF Suma_Izq_L, F
    MOVF PRODH, W
    ADDWFC Suma_Izq_H, F

    ; --- Sensor S2 (Peso 20) ---
    MOVLW .20
    MULWF Sens2
    MOVF PRODL, W
    ADDWF Suma_Izq_L, F
    MOVF PRODH, W
    ADDWFC Suma_Izq_H, F

    ; --- Sensor S1 (Peso 30) ---
    MOVLW .30
    MULWF Sens1
    MOVF PRODL, W
    ADDWF Suma_Izq_L, F
    MOVF PRODH, W
    ADDWFC Suma_Izq_H, F

    ; --- Sensor S0 (Peso 40) ---
    MOVLW .40
    MULWF Sens0
    MOVF PRODL, W
    ADDWF Suma_Izq_L, F
    MOVF PRODH, W
    ADDWFC Suma_Izq_H, F

; ==========================================
    ; LA RESTA FINAL: Error = Suma_Der - Suma_Izq
    ; ==========================================
    MOVF Suma_Izq_L, W
    SUBWF Suma_Der_L, W     ; Resta partes bajas (Suma_Der_L - Suma_Izq_L). Guarda en W
    MOVWF Error_L           ; Guarda en tu variable Error_L
    
    MOVF Suma_Izq_H, W
    SUBWFB Suma_Der_H, W    ; Resta partes altas CON BORROW (Préstamo). Guarda en W
    MOVWF Error_H           ; Guarda en tu variable Error_H
    RETURN

; =========================================================================
; SUBRUTINA: CALCULAR_PROPORCIONAL
; Propósito: Multiplica Error (16 bits con signo) * Kp (8 bits sin signo)
; =========================================================================
CALCULAR_PROPORCIONAL
; ---------------------------------------------------------------------
    ; FASE 1: EXTRACCIÓN DEL SIGNO Y CONVERSIÓN A VALOR ABSOLUTO
    ; ---------------------------------------------------------------------
    BCF Banderas, 0         ; Asumimos por defecto que el Error es Positivo (Bit = 0)
    BTFSS Error_H, 7        ; Revisamos el bit 7 (Bit de Signo) de la parte alta
    BRA FASE_2_MULTIPLICAR  ; Si es 0 (positivo), saltamos directo a multiplicar

    ; Si el programa no saltó, significa que el Error es NEGATIVO.
    BSF Banderas, 0         ; Levantamos la bandera: ¡Hay que corregir hacia la Izquierda! (Bit = 1)
    
    ; Convertimos el número negativo a positivo (Operación de Complemento a 2)
    ; Matemáticamente es: Invertir todos los bits y sumar 1.
    COMF Error_L, F         ; Invertir bits de la parte baja
    COMF Error_H, F         ; Invertir bits de la parte alta
    
    MOVLW 1
    ADDWF Error_L, F        ; Sumamos 1 a la parte baja
    MOVLW 0
    ADDWFC Error_H, F       ; Sumamos el acarreo (Carry) a la parte alta si lo hubo

FASE_2_MULTIPLICAR
    ; A partir de este punto, Error_H : Error_L es un valor POSITIVO absoluto.
    ; La dirección a girar está a salvo guardada en "Banderas, 0".

    ; ---------------------------------------------------------------------
    ; FASE 2: MULTIPLICACIÓN 16x8 BITS USANDO HARDWARE (MULWF)
    ; ---------------------------------------------------------------------
    
    ; PASO A: Multiplicar la Parte Baja (Error_L * Kp)
    MOVF Kp, W              ; Cargar la constante/variable Kp en W
    MULWF Error_L           ; Multiplicar. El resultado de 16 bits cae en PRODH:PRODL
    
    ; Guardamos este primer resultado
    MOVFF PRODL, Termino_P_L ; La parte baja de P ya está lista
    MOVFF PRODH, Termino_P_H ; Guardamos temporalmente el acarreo en la parte alta de P

    ; PASO B: Multiplicar la Parte Alta (Error_H * Kp)
    MOVF Kp, W
    MULWF Error_H           ; Multiplicar. Resultado cae nuevamente en PRODH:PRODL
    
    ; Acomodo matemático cruzado:
    ; La parte baja de este nuevo resultado (PRODL) tiene el "peso" de la parte alta.
    ; Por lo tanto, se la sumamos a la parte alta que guardamos en el Paso A.
    MOVF PRODL, W
    ADDWF Termino_P_H, F    ; Sumar al registro final Termino_P_H
    
    ; (Nota: Ignoramos PRODH de esta segunda multiplicación. Asumimos que 
    ;  tu Kp estará escalado para que el resultado de 'P' no exceda los 16 bits,
    ;  que es el límite natural para los módulos PWM de los motores).

    RETURN                  ; Regresamos al lazo PID principal

CALCULAR_DERIVATIVO
    ; ---------------------------------------------------------------------
    ; FASE 1: LA RESTA (Delta Error = Error Actual - Error Anterior)
    ; ---------------------------------------------------------------------
    ; Restamos las partes bajas (Error_L - Error_Anterior_L)
    MOVF Error_Anterior_L, W
    SUBWF Error_L, W
    MOVWF Delta_Error_L

    ; Restamos las partes altas CON PRÉSTAMO (Borrow)
    MOVF Error_Anterior_H, W
    SUBWFB Error_H, W
    MOVWF Delta_Error_H

    ; ---------------------------------------------------------------------
    ; FASE 2: EXTRACCIÓN DEL SIGNO (El sentido del freno)
    ; ---------------------------------------------------------------------
    BCF Banderas, 1         ; Asumimos que Delta_Error es positivo (Bit 1 = 0)
    BTFSS Delta_Error_H, 7  ; Revisamos el bit de signo
    BRA FASE_3_MULTIPLICAR_D ; Si es 0 (positivo), saltamos directo a multiplicar

    ; Si es negativo, levantamos la bandera (Bit 1 = 1)
    BSF Banderas, 1         
    
    ; Convertimos Delta_Error a positivo (Complemento a 2) para poder multiplicarlo
    COMF Delta_Error_L, F   
    COMF Delta_Error_H, F   
    MOVLW 1
    ADDWF Delta_Error_L, F  
    MOVLW 0
    ADDWFC Delta_Error_H, F 

FASE_3_MULTIPLICAR_D
    ; ---------------------------------------------------------------------
    ; FASE 3: MULTIPLICACIÓN 16x8 BITS (Hardware)
    ; ---------------------------------------------------------------------
    
    ; PASO A: Multiplicar Parte Baja (Delta_Error_L * Kd)
    MOVF Kd, W
    MULWF Delta_Error_L     
    
    MOVFF PRODL, Termino_D_L ; Guardamos parte baja final
    MOVFF PRODH, Termino_D_H ; Guardamos el acarreo en la parte alta
    
    ; PASO B: Multiplicar Parte Alta (Delta_Error_H * Kd)
    MOVF Kd, W
    MULWF Delta_Error_H     
    
    ; Sumamos el resultado cruzado a la parte alta
    MOVF PRODL, W
    ADDWF Termino_D_H, F    

    RETURN

; =========================================================================
; SUBRUTINA: APLICAR_CONTROL_MOTORES
; Propósito: Suma/Resta el Control (P+D) a la Velocidad_Base, satura los
;            límites a 0-255 y actualiza los registros CCP y el Puerto D.
; =========================================================================
APLICAR_CONTROL_MOTORES
; 1. Sumar los términos P y D (Asumiendo que ya están calculados y
    ;    que la lógica de si se suman o restan entre sí ya se resolvió, 
    ;    dando un valor final guardado en "Control_L" y "Control_H", y 
    ;    una bandera final de dirección en "Banderas, 2")

    ; 2. Cargar la Velocidad Base a las variables temporales
    MOVF Velocidad_Base, W
    MOVWF PWM_Izq_Temp_L
    CLRF PWM_Izq_Temp_H      ; Limpiamos parte alta
    
    MOVF Velocidad_Base, W
    MOVWF PWM_Der_Temp_L
    CLRF PWM_Der_Temp_H      ; Limpiamos parte alta

    ; ---------------------------------------------------------------------
    ; FASE 3: MEZCLA DE MOTORES (MOTOR MIXING)
    ; ---------------------------------------------------------------------
    ; Revisamos la bandera final de dirección (Bit 2: 0=Der, 1=Izq)
    BTFSC Banderas, 2
    BRA MEZCLA_GIRA_IZQUIERDA

MEZCLA_GIRA_DERECHA
    ; Gira Derecha -> Motor Izq Acelera, Motor Der Frena
    ; PWM_Izq = Velocidad_Base + Control
    MOVF Control_L, W
    ADDWF PWM_Izq_Temp_L, F
    MOVF Control_H, W
    ADDWFC PWM_Izq_Temp_H, F

    ; PWM_Der = Velocidad_Base - Control
    MOVF Control_L, W
    SUBWF PWM_Der_Temp_L, F
    MOVF Control_H, W
    SUBWFB PWM_Der_Temp_H, F
    BRA FASE_4_SATURACION

MEZCLA_GIRA_IZQUIERDA
    ; Gira Izquierda -> Motor Izq Frena, Motor Der Acelera
    ; PWM_Izq = Velocidad_Base - Control
    MOVF Control_L, W
    SUBWF PWM_Izq_Temp_L, F
    MOVF Control_H, W
    SUBWFB PWM_Izq_Temp_H, F

    ; PWM_Der = Velocidad_Base + Control
    MOVF Control_L, W
    ADDWF PWM_Der_Temp_L, F
    MOVF Control_H, W
    ADDWFC PWM_Der_Temp_H, F

FASE_4_SATURACION
    ; ---------------------------------------------------------------------
    ; FASE 4: SATURACIÓN (CLAMPING) PARA PROTEGER EL PWM (0 a 255)
    ; ---------------------------------------------------------------------

    ; --- LÍMITE SUPERIOR (Max 255) ---
    ; Si la parte alta (_H) es mayor a 0, significa que el número es mayor a 255.
    ; Saturación Motor Izquierdo:
    MOVF PWM_Izq_Temp_H, F  ; Actualiza la bandera Z
    BTFSS STATUS, Z         ; ¿Es cero?
    SETF PWM_Izq_Temp_L     ; Si no es cero (es >255), fuerza la parte baja a 255 (0xFF)

    ; Saturación Motor Derecho:
    MOVF PWM_Der_Temp_H, F
    BTFSS STATUS, Z
    SETF PWM_Der_Temp_L

    ; --- LÍMITE INFERIOR (Min 0) ---
    ; En ensamblador, si restaste y dio negativo, el número se volvió enorme 
    ; (ej. 0 - 5 = 251 en 8 bits). Pero, en 16 bits, la parte alta (_H) 
    ; se llena de unos (0xFF). Usaremos esto para detectar números negativos.
    
    ; Saturación Inferior Motor Izquierdo:
    BTFSC PWM_Izq_Temp_H, 7 ; Revisa el bit de signo de la parte alta
    CLRF PWM_Izq_Temp_L     ; Si es 1 (negativo), fuerza la velocidad a 0

    ; Saturación Inferior Motor Derecho:
    BTFSC PWM_Der_Temp_H, 7
    CLRF PWM_Der_Temp_L

    ; ---------------------------------------------------------------------
    ; FASE 5: ESCRITURA EN HARDWARE (EL FINAL DEL CICLO PID)
    ; ---------------------------------------------------------------------
    
    ; 1. Asegurar que ambos motores estén configurados "Hacia Adelante"
    ; Recordando tu tabla: PD0/PD1 son AIN, PD2/PD3 son BIN.
    ; Para adelante en el TB6612FNG: IN1=1, IN2=0
    MOVLW b'00000101'   ; 0000_0101
    MOVWF LATD          ; Escribe la dirección de giro

    ; 2. Escribir los valores finales a los registros PWM del PIC
    ; (CCPR1L controla el pin RC2, CCPR2L controla el pin RC1)
    MOVF PWM_Izq_Temp_L, W
    MOVWF CCPR1L        ; Actualiza Duty Cycle Motor Izquierdo
    
    MOVF PWM_Der_Temp_L, W
    MOVWF CCPR2L        ; Actualiza Duty Cycle Motor Derecho

    RETURN


SUMA_PD
; =========================================================================
; PASO 5: CONSOLIDACIÓN DE TÉRMINOS (Control = P + D)
; =========================================================================
; Se evalúa si P y D empujan en la misma dirección o en direcciones opuestas.
    
    MOVF Banderas, W
    ANDLW b'00000011'       ; Aislamos los bits de dirección de P (bit 0) y D (bit 1)
    XORLW b'00000000'       ; Comprobamos si ambos son 0 (Dirección Derecha)
    BZ SUMAR_TERMINOS
    
    MOVF Banderas, W
    ANDLW b'00000011'
    XORLW b'00000011'       ; Comprobamos si ambos son 1 (Dirección Izquierda)
    BZ SUMAR_TERMINOS

RESTAR_TERMINOS
    ; P y D tienen direcciones opuestas. Se restan (P - D). 
    ; Se asume que P > D en magnitud para este diseño base.
    MOVF Termino_D_L, W
    SUBWF Termino_P_L, W
    MOVWF Control_L
    
    MOVF Termino_D_H, W
    SUBWFB Termino_P_H, W
    MOVWF Control_H
    
    ; La dirección final dominante (Bit 2) será la del término Proporcional
    BTFSC Banderas, 0
    BSF Banderas, 2         
    BTFSS Banderas, 0
    BCF Banderas, 2         
    RETURN

SUMAR_TERMINOS
    ; P y D van en la misma dirección. Se suman las magnitudes de 16 bits.
    MOVF Termino_D_L, W
    ADDWF Termino_P_L, W
    MOVWF Control_L
    
    MOVF Termino_D_H, W
    ADDWFC Termino_P_H, W
    MOVWF Control_H
    
    ; La dirección final hereda la dirección compartida
    BTFSC Banderas, 0
    BSF Banderas, 2
    BTFSS Banderas, 0
    BCF Banderas, 2
    RETURN

CONTROL_PWM
; =========================================================================
; PASO 6: ESCRITURA EN HARDWARE Y MEZCLA DE MOTORES
; =========================================================================
; Configuración inicial de la Velocidad Base en variables temporales
    MOVF Velocidad_Base, W
    MOVWF PWM_Izq_Temp_L
    CLRF PWM_Izq_Temp_H
    MOVF Velocidad_Base, W
    MOVWF PWM_Der_Temp_L
    CLRF PWM_Der_Temp_H

    ; Bifurcación basada en la bandera final (Bit 2)
    BTFSC Banderas, 2
    BRA MEZCLA_IZQ

MEZCLA_DER
    ; Motor Izquierdo (+) y Motor Derecho (-)
    MOVF Control_L, W
    ADDWF PWM_Izq_Temp_L, F
    MOVF Control_H, W
    ADDWFC PWM_Izq_Temp_H, F

    MOVF Control_L, W
    SUBWF PWM_Der_Temp_L, F
    MOVF Control_H, W
    SUBWFB PWM_Der_Temp_H, F
    BRA SATURACION_HARDWARE

MEZCLA_IZQ
    ; Motor Izquierdo (-) y Motor Derecho (+)
    MOVF Control_L, W
    SUBWF PWM_Izq_Temp_L, F
    MOVF Control_H, W
    SUBWFB PWM_Izq_Temp_H, F

    MOVF Control_L, W
    ADDWF PWM_Der_Temp_L, F
    MOVF Control_H, W
    ADDWFC PWM_Der_Temp_H, F

SATURACION_HARDWARE
    ; Límite Superior: Prevención de Overflow (>255)
    MOVF PWM_Izq_Temp_H, F
    BTFSS STATUS, Z
    SETF PWM_Izq_Temp_L
    MOVF PWM_Der_Temp_H, F
    BTFSS STATUS, Z
    SETF PWM_Der_Temp_L

    ; Límite Inferior: Prevención de Underflow (<0)
    BTFSC PWM_Izq_Temp_H, 7
    CLRF PWM_Izq_Temp_L
    BTFSC PWM_Der_Temp_H, 7
    CLRF PWM_Der_Temp_L

    ; Dirección de Puente H TB6612FNG (Hacia Adelante)
    MOVLW b'00000101'   
    MOVWF LATD          

    ; Transmisión a registros CCP
    MOVF PWM_Izq_Temp_L, W
    MOVWF CCPR1L        
    MOVF PWM_Der_Temp_L, W
    MOVWF CCPR2L
    RETURN

LEER_CANAL_ADC
    ; 1. Seleccionar el canal y encender el módulo ADC
    MOVWF ADCON0        

    ; 2. Iniciar la conversión (Poner el bit GO/DONE en 1)
    BSF ADCON0, GO_DONE 

ESPERAR_ADC
    ; 3. Esperar a que el hardware termine (El bit GO/DONE se hará 0 solo)
    BTFSC ADCON0, GO_DONE
    BRA ESPERAR_ADC     ; Si sigue en 1, repite esta línea

    ; 4. Guardar el resultado
    ; Como está justificado a la izquierda, ignoramos ADRESL y leemos ADRESH
    MOVF ADRESH, W      ; Movemos la lectura a W para devolverla
    RETURN

CONFIGURAR_PWM
; =========================================================================
; SUBRUTINA: CONFIGURAR_PWM
; Propósito: Inicializa Timer2 y los módulos CCP1/CCP2 para generar señales 
;            PWM a 46.8 kHz con resolución de 8 bits.
; =========================================================================
; 1. Configurar los pines físicos como salidas (El paso vital)
    ; Según tu tabla: RC1 es PWM_Motor_Derecho, RC2 es PWM_Motor_Izquierdo
    BCF TRISC, 1        ; Limpiamos el bit 1 de TRISC (RC1 como salida)
    BCF TRISC, 2        ; Limpiamos el bit 2 de TRISC (RC2 como salida)

    ; 2. Establecer la Frecuencia (El periodo de la señal)
    ; Cargar 0xFF (255) nos da la resolución de 8 bits exacta para tus cálculos
    MOVLW 0xFF
    MOVWF PR2

    ; 3. Inicializar el Duty Cycle a 0 (Seguridad ante todo)
    ; Esto asegura que el robot no arranque disparado apenas lo enciendes
    CLRF CCPR1L         ; Motor Izquierdo a 0%
    CLRF CCPR2L         ; Motor Derecho a 0%

    ; 4. Configurar los módulos CCP en modo PWM estándar
    ; Los bits 3-0 en '1100' encienden la función PWM
    ; Los bits 5-4 en '00' son los bits menos significativos del Duty Cycle (los ignoramos)
    MOVLW b'00001100'
    MOVWF CCP1CON       
    MOVWF CCP2CON

    ; 5. Encender el Motor del PWM (Timer2)
    ; Bit 2 (TMR2ON) = 1 -> Enciende el Timer2
    ; Bits 1-0 (T2CKPS) = 00 -> Prescaler de 1:1
    MOVLW b'00000100'
    MOVWF T2CON

    RETURN


RETARDO_DEBOUNCE
    ; Retardo simple de aprox 20ms a 48MHz para absorber el ruido mecánico
    MOVLW .100
    MOVWF contador2
L_Debounce2
    MOVLW .250
    MOVWF contador1
L_Debounce1
    DECFSZ contador1, F
    BRA L_Debounce1
    DECFSZ contador2, F
    BRA L_Debounce2
    RETURN

    END