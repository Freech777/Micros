#define PIN_AUDIO  34
#define PIN_IR     25
#define LEDC_FREQ  38000
#define LEDC_RES   8
#define DUTY_50    128

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  ledcAttach(PIN_IR, LEDC_FREQ, LEDC_RES);
  ledcWrite(PIN_IR, 0);
  delay(100);
}

void loop() {
  int audio = analogRead(PIN_AUDIO);

  // Calcular promedio dinámico como punto de referencia (DC offset)
  static long promedio = 0;
  promedio = (promedio * 15 + audio) / 16;  // filtro IIR suave

  int diferencia = audio - promedio;  // señal AC pura, centrada en 0

  // Umbral: detectar cuando hay señal significativa
  if (abs(diferencia) > 10) {       // ajusta este valor según tu señal
    ledcWrite(PIN_IR, DUTY_50);     // IR ON
  } else {
    ledcWrite(PIN_IR, 0);           // IR OFF
  }

  static unsigned long ultimo = 0;
  if (millis() - ultimo > 10) {
    Serial.print("ADC: ");
    Serial.print(audio);
    Serial.print("  Prom: ");
    Serial.print(promedio);
    Serial.print("  Diff: ");
    Serial.println(diferencia);
    ultimo = millis();
  }
}