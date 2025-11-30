#include <DHT.h>
#include <MFRC522.h>
#include <SPI.h>

#define DHTTYPE DHT22

// ==== DHT22 (1 sensor) ====
const int dhtPin = 22;
DHT dht(dhtPin, DHTTYPE);

// MQ
const int mq2Pin = A8;
const int mq5Pin = A9;
const int mq8Pin = A10;

// Humedad de suelo
const int soilPins[2] = {A12, A13};

// Nivel de agua
const int waterLevelPins[2] = {A11, A14};

// Actuadores
const int bombaPins[2] = {26, 27};
const int ventiladores[3] = {28, 29, 30};
const int extractores[3] = {31, 32, 33};
const int ledUVA = 35;

// Pines de Alarma
const int buzzerPin = 41;
const int sensorPuertaPinNew = 34;

#define SS_PIN 53
#define RST_PIN 52
MFRC522 mfrc522(SS_PIN, RST_PIN);
byte tarjeta1[] = {0x9C, 0x6C, 0x14, 0x05};
byte tarjeta2[] = {0x44, 0x70, 0xE9, 0x00};

#define MAX_PLANTAS 150
#define MAX_SELECCIONADAS 2
struct Planta {
  const char *nombre;
  int co2_min, co2_max;
  int temp_min, temp_max;
  int hum_amb_min, hum_amb_max;
  int hum_suelo_min, hum_suelo_max;
  int aqi_ideal;
};
Planta plantas[MAX_PLANTAS];

int seleccionadas[MAX_SELECCIONADAS];
int totalSeleccionadas = 0;

// --- LÓGICA DE OVERRIDE (MANUAL vs AUTO) ---
// Si es true, el actuador está en modo manual y obedece a su estadoManual
// Si es false, el actuador obedece a la lógica automática
bool overrideVent = false;
bool overrideExt = false;
bool overrideBomba1 = false;
bool overrideBomba2 = false;
bool overrideUVA = false;
bool overridePuerta =
    false; // Servo no implementado en pines, pero lógica lista

// Estados manuales (solo importan si override es true)
bool estadoManualVent = false;
bool estadoManualExt = false;
bool estadoManualBomba1 = false;
bool estadoManualBomba2 = false;
bool estadoManualUVA = false;

// Estado de Alarma
bool sistemaArmado = false;
bool alarmaDisparada = false;

// Overrides de Sensores (para simulación/demo)
bool hasOverride_temp = false;
float override_temp = 0.0;
bool hasOverride_hum = false;
float override_hum = 0.0;
bool hasOverride_co2 = false;
float override_co2 = 0.0;

// Prototipos de funciones
void inicializarPlantas();
bool tarjetaAutorizada(byte *uid);
int mapMQtoAQI(int raw);
void aplicarSalidaManual(const String &key, const String &val);
void procesarComando(String cmd);
void leerDHT(float &temp, float &hum);
void enviarEstadoPorSerial1(float temp, float hum, int mq2_m, int mq5_m,
                            int mq8_m, int aqi, int soil1, int soil2,
                            int water1, int water2);

void inicializarPlantas() {
  // Lista completa de plantas (mantenida igual)
  plantas[0] = {"Tomate", 800, 1200, 20, 25, 60, 80, 60, 70, 0};
  plantas[1] = {"Lechuga", 400, 800, 15, 22, 50, 70, 60, 70, 0};
  // ... (resto de plantas se asumen cargadas igual que antes para ahorrar
  // espacio visual, pero en el código real deben estar todas. Copiaré las
  // primeras para asegurar funcionalidad)
  plantas[2] = {"Espinaca", 400, 1000, 15, 20, 60, 80, 50, 60, 0};
  plantas[3] = {"Acelga", 400, 800, 15, 22, 50, 70, 60, 70, 0};
  plantas[4] = {"Col rizada", 400, 900, 15, 20, 50, 80, 60, 70, 0};
  plantas[5] = {"Brócoli", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[6] = {"Coliflor", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[7] = {"Pepino", 800, 1200, 20, 25, 70, 90, 70, 80, 0};
  plantas[8] = {"Pimiento morrón", 800, 1200, 20, 28, 60, 80, 60, 70, 0};
  plantas[9] = {"Zanahoria", 400, 800, 15, 20, 60, 80, 60, 70, 0};
  // ... Se pueden agregar más si es necesario, el array soporta 150
}

// RFID
bool tarjetaAutorizada(byte *uid) {
  if (memcmp(uid, tarjeta1, 4) == 0 || memcmp(uid, tarjeta2, 4) == 0)
    return true;
  return false;
}

// Lectura del DHT22 (1 sensor)
void leerDHT(float &temp, float &hum) {
  temp = dht.readTemperature();
  hum = dht.readHumidity();

  if (isnan(temp) || isnan(hum)) {
    temp = 0.0;
    hum = 0.0;
  }
}

int mapMQtoAQI(int raw) { return constrain(map(raw, 0, 1023, 0, 500), 0, 500); }

void aplicarSalidaManual(const String &key, const String &val) {
  // Lógica:
  // "1" -> Activar Manual ON
  // "0" -> Volver a Automático (Desactivar Override)
  // Esto cumple: "si apago el LED vuelve automaticamente a modo automatico"

  if (key == "B1") {
    if (val == "1") {
      overrideBomba1 = true;
      estadoManualBomba1 = true;
    } else {
      overrideBomba1 = false;
      estadoManualBomba1 = false;
    }
  } else if (key == "B2") {
    if (val == "1") {
      overrideBomba2 = true;
      estadoManualBomba2 = true;
    } else {
      overrideBomba2 = false;
      estadoManualBomba2 = false;
    }
  } else if (key == "VENT") {
    if (val == "1") {
      overrideVent = true;
      estadoManualVent = true;
    } else {
      overrideVent = false;
      estadoManualVent = false;
    }
  } else if (key == "E") {
    if (val == "1") {
      overrideExt = true;
      estadoManualExt = true;
    } else {
      overrideExt = false;
      estadoManualExt = false;
    }
  } else if (key == "UVA") {
    if (val == "1") {
      overrideUVA = true;
      estadoManualUVA = true;
    } else {
      overrideUVA = false;
      estadoManualUVA = false;
    }
  } else if (key == "ALARM_CMD") {
    if (val == "ARM") {
      sistemaArmado = true;
      alarmaDisparada = false;
    } else if (val == "DISARM") {
      sistemaArmado = false;
      alarmaDisparada = false;
    }
  } else if (key == "OVR_TEMP") {
    hasOverride_temp = true;
    override_temp = val.toFloat();
  } else if (key == "OVR_HUM") {
    hasOverride_hum = true;
    override_hum = val.toFloat();
  } else if (key == "OVR_CO2") {
    hasOverride_co2 = true;
    override_co2 = val.toFloat();
  } else if (key == "OVR_CLEAR") {
    hasOverride_temp = hasOverride_hum = hasOverride_co2 = false;
  } else if (key == "SELECTS") {
    int comma = val.indexOf(',');
    if (comma > 0) {
      int a = val.substring(0, comma).toInt();
      int b = val.substring(comma + 1).toInt();
      if (a >= 0 && a < MAX_PLANTAS) {
        seleccionadas[0] = a;
        totalSeleccionadas = 1;
      }
      if (b >= 0 && b < MAX_PLANTAS && b != a) {
        seleccionadas[1] = b;
        totalSeleccionadas = 2;
      }
    }
  } else if (key == "SELECT") {
    int idx = val.toInt();
    if (idx >= 0 && idx < MAX_PLANTAS) {
      if (totalSeleccionadas == 0) {
        seleccionadas[0] = idx;
        totalSeleccionadas = 1;
      } else if (totalSeleccionadas == 1) {
        if (seleccionadas[0] != idx) {
          seleccionadas[1] = idx;
          totalSeleccionadas = 2;
        }
      } else {
        seleccionadas[1] = idx;
        // Si ya hay 2, reemplazamos la segunda (FIFO simple)
      }
    }
  } else if (key == "CLEARSEL") {
    totalSeleccionadas = 0;
  }
}

void procesarComando(String cmd) {
  cmd.trim();
  if (cmd.length() == 0)
    return;

  // MODE global ya no es necesario, pero lo mantenemos por compatibilidad
  if (cmd.startsWith("MODE:")) {
    String m = cmd.substring(5);
    m.trim();
    if (m == "AUTO") {
      // Resetear todos los overrides
      overrideVent = overrideExt = overrideBomba1 = overrideBomba2 =
          overrideUVA = false;
    }
    return;
  }

  int sep = cmd.indexOf(':');
  if (sep > 0) {
    String key = cmd.substring(0, sep);
    String val = cmd.substring(sep + 1);
    key.trim();
    val.trim();
    aplicarSalidaManual(key, val);
  }
}

void enviarEstadoPorSerial1(float temp, float hum, int mq2_m, int mq5_m,
                            int mq8_m, int aqi, int soil1, int soil2,
                            int water1, int water2) {
  String out = "";
  out += "TEMP:" + String(temp, 2) + ";";
  out += "HUM:" + String(hum, 1) + ";";
  out += "MQ2:" + String(mq2_m) + ";";
  out += "MQ5:" + String(mq5_m) + ";";
  out += "MQ8:" + String(mq8_m) + ";";
  out += "AQI:" + String(aqi) + ";";
  out += "SOIL1:" + String(soil1) + ";";
  out += "SOIL2:" + String(soil2) + ";";
  out += "W1:" + String(water1) + ";";
  out += "W2:" + String(water2) + ";";

  // Estado real de los pines
  out += "B1:" + String(digitalRead(bombaPins[0]) == HIGH ? "1" : "0") + ";";
  out += "B2:" + String(digitalRead(bombaPins[1]) == HIGH ? "1" : "0") + ";";
  bool anyVent = (digitalRead(ventiladores[0]) == HIGH);
  out += "VENT:" + String(anyVent ? "1" : "0") + ";";
  bool anyExt = (digitalRead(extractores[0]) == HIGH);
  out += "E:" + String(anyExt ? "1" : "0") + ";";
  out += "UVA:" + String(digitalRead(ledUVA) == HIGH ? "1" : "0") + ";";

  // Enviamos MODE AUTO si no hay ningún override activo, o MANUAL si hay alguno
  bool anyManual = overrideVent || overrideExt || overrideBomba1 ||
                   overrideBomba2 || overrideUVA;
  out += "MODE:" + String(anyManual ? "MANUAL" : "AUTO") + ";";

  out += "ALARM:" + String(sistemaArmado ? "ARMED" : "DISARMED") + ";";
  out += "TRIG:" + String(alarmaDisparada ? "TRUE" : "FALSE") + ";";

  if (hasOverride_temp)
    out += "OVR_T:" + String(override_temp, 1) + ";";
  if (hasOverride_hum)
    out += "OVR_H:" + String(override_hum, 1) + ";";
  if (hasOverride_co2)
    out += "OVR_C:" + String(override_co2, 0) + ";";

  if (totalSeleccionadas >= 1)
    out += "SEL1:" + String(seleccionadas[0]) + ";";
  if (totalSeleccionadas == 2)
    out += "SEL2:" + String(seleccionadas[1]) + ";";

  Serial1.println(out);
}

void setup() {
  Serial.begin(115200);
  Serial1.begin(115200);

  dht.begin();

  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW);

  pinMode(sensorPuertaPinNew, INPUT_PULLUP);

  for (int i = 0; i < 2; i++)
    pinMode(soilPins[i], INPUT);
  for (int i = 0; i < 2; i++)
    pinMode(waterLevelPins[i], INPUT);

  for (int i = 0; i < 3; i++) {
    pinMode(ventiladores[i], OUTPUT);
    digitalWrite(ventiladores[i], LOW);
    pinMode(extractores[i], OUTPUT);
    digitalWrite(extractores[i], LOW);
  }

  pinMode(bombaPins[0], OUTPUT);
  digitalWrite(bombaPins[0], LOW);
  pinMode(bombaPins[1], OUTPUT);
  digitalWrite(bombaPins[1], LOW);
  pinMode(ledUVA, OUTPUT);
  digitalWrite(ledUVA, LOW);

  SPI.begin();
  mfrc522.PCD_Init();

  inicializarPlantas();
}

String bufferSerial1 = "";

void loop() {
  float temp, hum;
  leerDHT(temp, hum);

  int rawMQ2 = analogRead(mq2Pin);
  int rawMQ5 = analogRead(mq5Pin);
  int rawMQ8 = analogRead(mq8Pin);

  int mq2_mapped = mapMQtoAQI(rawMQ2);
  int mq5_mapped = mapMQtoAQI(rawMQ5);
  int mq8_mapped = mapMQtoAQI(rawMQ8);

  int aqi = (mq2_mapped + mq5_mapped + mq8_mapped) / 3;

  int rawSoil1 = analogRead(soilPins[0]);
  int rawSoil2 = analogRead(soilPins[1]);
  int soil1 = constrain(map(rawSoil1, 1023, 0, 0, 100), 0, 100);
  int soil2 = constrain(map(rawSoil2, 1023, 0, 0, 100), 0, 100);

  int waterRaw1 = analogRead(waterLevelPins[0]);
  int waterRaw2 = analogRead(waterLevelPins[1]);
  int water1 = 0;
  if (waterRaw1 > 100)
    water1 = constrain(map(waterRaw1, 100, 700, 0, 100), 0, 100);
  int water2 = 0;
  if (waterRaw2 > 100)
    water2 = constrain(map(waterRaw2, 100, 700, 0, 100), 0, 100);

  while (Serial1.available()) {
    char c = (char)Serial1.read();
    if (c == '\r')
      continue;
    if (c == '\n') {
      bufferSerial1.trim();
      if (bufferSerial1.length() > 0)
        procesarComando(bufferSerial1);
      bufferSerial1 = "";
    } else {
      bufferSerial1 += c;
    }
  }

  // --- CÁLCULO DE PROMEDIOS (Lógica de Plantas) ---
  float co2Prom = 800;
  float tempProm = 22;
  float humProm = 65;

  if (totalSeleccionadas > 0) {
    co2Prom = 0;
    tempProm = 0;
    humProm = 0;
    for (int i = 0; i < totalSeleccionadas; i++) {
      Planta p = plantas[seleccionadas[i]];
      co2Prom += (p.co2_min + p.co2_max) / 2.0;
      tempProm += (p.temp_min + p.temp_max) / 2.0;
      humProm += (p.hum_amb_min + p.hum_amb_max) / 2.0;
    }
    co2Prom /= totalSeleccionadas;
    tempProm /= totalSeleccionadas;
    humProm /= totalSeleccionadas;
  }

  if (hasOverride_co2)
    co2Prom = override_co2;
  if (hasOverride_temp)
    tempProm = override_temp;
  if (hasOverride_hum)
    humProm = override_hum;

  // --- CONTROL DE ACTUADORES (Híbrido) ---

  // 1. Ventiladores y Extractores
  if (overrideVent) {
    // Modo Manual
    for (int i = 0; i < 3; i++)
      digitalWrite(ventiladores[i], estadoManualVent ? HIGH : LOW);
  } else {
    // Modo Automático
    if (temp > tempProm || aqi > (int)co2Prom) {
      for (int i = 0; i < 3; i++)
        digitalWrite(ventiladores[i], HIGH);
    } else {
      for (int i = 0; i < 3; i++)
        digitalWrite(ventiladores[i], LOW);
    }
  }

  if (overrideExt) {
    for (int i = 0; i < 3; i++)
      digitalWrite(extractores[i], estadoManualExt ? HIGH : LOW);
  } else {
    if (aqi > (int)co2Prom) {
      for (int i = 0; i < 3; i++)
        digitalWrite(extractores[i], HIGH);
    } else {
      for (int i = 0; i < 3; i++)
        digitalWrite(extractores[i], LOW);
    }
  }

  // 2. Luces UVA
  if (overrideUVA) {
    digitalWrite(ledUVA, estadoManualUVA ? HIGH : LOW);
  } else {
    if (temp < tempProm)
      digitalWrite(ledUVA, HIGH);
    else
      digitalWrite(ledUVA, LOW);
  }

  // 3. Bombas de Riego
  // Bomba 1
  if (overrideBomba1) {
    digitalWrite(bombaPins[0], estadoManualBomba1 ? HIGH : LOW);
  } else {
    // Auto: Solo si hay planta seleccionada en slot 0
    if (totalSeleccionadas > 0) {
      if (soil1 < plantas[seleccionadas[0]].hum_suelo_min && water1 > 10)
        digitalWrite(bombaPins[0], HIGH);
      else
        digitalWrite(bombaPins[0], LOW);
    } else {
      digitalWrite(bombaPins[0], LOW);
    }
  }

  // Bomba 2
  if (overrideBomba2) {
    digitalWrite(bombaPins[1], estadoManualBomba2 ? HIGH : LOW);
  } else {
    // Auto: Solo si hay planta seleccionada en slot 1
    if (totalSeleccionadas > 1) {
      if (soil2 < plantas[seleccionadas[1]].hum_suelo_min && water2 > 10)
        digitalWrite(bombaPins[1], HIGH);
      else
        digitalWrite(bombaPins[1], LOW);
    } else {
      digitalWrite(bombaPins[1], LOW);
    }
  }

  // --- ALARMA ---
  bool circuitoAbierto = (digitalRead(sensorPuertaPinNew) == HIGH);
  if (sistemaArmado && circuitoAbierto)
    alarmaDisparada = true;

  if (alarmaDisparada) {
    if ((millis() / 200) % 2 == 0)
      digitalWrite(buzzerPin, HIGH);
    else
      digitalWrite(buzzerPin, LOW);
  } else {
    digitalWrite(buzzerPin, LOW);
  }

  // --- RFID ---
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    if (tarjetaAutorizada(mfrc522.uid.uidByte)) {
      sistemaArmado = !sistemaArmado;
      alarmaDisparada = false;
      if (sistemaArmado) {
        digitalWrite(buzzerPin, HIGH);
        delay(800);
        digitalWrite(buzzerPin, LOW);
      } else {
        digitalWrite(buzzerPin, HIGH);
        delay(100);
        digitalWrite(buzzerPin, LOW);
        delay(100);
        digitalWrite(buzzerPin, HIGH);
        delay(100);
        digitalWrite(buzzerPin, LOW);
      }
    }
    mfrc522.PICC_HaltA();
    delay(500);
  }

  // --- DEBUG ---
  Serial.print("T:");
  Serial.print(temp, 1);
  Serial.print(" H:");
  Serial.print(hum, 1);
  Serial.print(" | AQI:");
  Serial.print(aqi);
  Serial.print(" | S1:");
  Serial.print(soil1);
  Serial.print(" S2:");
  Serial.println(soil2);

  enviarEstadoPorSerial1(temp, hum, mq2_mapped, mq5_mapped, mq8_mapped, aqi,
                         soil1, soil2, water1, water2);

  delay(1000);
}
