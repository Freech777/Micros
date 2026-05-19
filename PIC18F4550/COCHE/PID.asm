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

#include "p18f4550.inc"


CBLOCK 0x00

ENDC

CONFIGURACION







END