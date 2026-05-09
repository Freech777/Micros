#define PIN_AUDIO  34
#define PIN_IR     25
#define LEDC_RES   8
#define SAMPLE_US  100   // 10kHz muestreo

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  ledcAttach(PIN_IR, 20000, 8);
  ledcWrite(PIN_IR, 128);
  delay(500);
}

void loop() {
  unsigned long t = micros();

  int audio = (analogRead(PIN_AUDIO) + analogRead(PIN_AUDIO) +
               analogRead(PIN_AUDIO) + analogRead(PIN_AUDIO)) / 4;

  static long promedio = 0;
  if (promedio == 0) promedio = (long)audio << 9;
  promedio = promedio - (promedio >> 9) + audio;
  int dc = (int)(promedio >> 9);

  int diff = audio - dc;
  if (abs(diff) < 3) diff = 0;

  int duty = constrain(128 + diff / 6, 0, 255);
  ledcWrite(PIN_IR, duty);

  // Esperar resto del periodo de muestreo
  while (micros() - t < SAMPLE_US);
}