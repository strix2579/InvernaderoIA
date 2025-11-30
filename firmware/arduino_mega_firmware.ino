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

bool modoAutomatico = true;

// Estado de Alarma
bool sistemaArmado = false;
bool alarmaDisparada = false;

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
  plantas[0] = {"Tomate", 800, 1200, 20, 25, 60, 80, 60, 70, 0};
  plantas[1] = {"Lechuga", 400, 800, 15, 22, 50, 70, 60, 70, 0};
  plantas[2] = {"Espinaca", 400, 1000, 15, 20, 60, 80, 50, 60, 0};
  plantas[3] = {"Acelga", 400, 800, 15, 22, 50, 70, 60, 70, 0};
  plantas[4] = {"Col rizada", 400, 900, 15, 20, 50, 80, 60, 70, 0};
  plantas[5] = {"Brócoli", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[6] = {"Coliflor", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[7] = {"Pepino", 800, 1200, 20, 25, 70, 90, 70, 80, 0};
  plantas[8] = {"Pimiento morrón", 800, 1200, 20, 28, 60, 80, 60, 70, 0};
  plantas[9] = {"Zanahoria", 400, 800, 15, 20, 60, 80, 60, 70, 0};
  plantas[10] = {"Maranta", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[11] = {"Aglaonema", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[12] = {"Schefflera", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[13] = {"Croton", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[14] = {"Trigo", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[15] = {"Cebada", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[16] = {"Avena", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[17] = {"Arroz", 400, 800, 22, 28, 60, 80, 70, 80, 0};
  plantas[18] = {"Maíz dulce", 400, 800, 22, 28, 60, 80, 60, 70, 0};
  plantas[19] = {"Frijol", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[20] = {"Soya", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[21] = {"Girasol comestible", 400, 800, 20, 28, 60, 80, 60, 70, 0};
  plantas[22] = {"Amaranto", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[23] = {"Lenteja", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[24] = {"Árnica", 400, 800, 15, 22, 50, 70, 50, 60, 0};
  plantas[25] = {"Diente de león", 400, 800, 15, 22, 50, 70, 50, 60, 0};
  plantas[26] = {"Valeriana", 400, 800, 15, 22, 50, 70, 50, 60, 0};
  plantas[27] = {"Equinácea", 400, 800, 15, 22, 50, 70, 50, 60, 0};
  plantas[28] = {"Ginseng", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[29] = {"Moringa", 400, 800, 22, 28, 60, 80, 60, 70, 0};
  plantas[30] = {"Hierba luisa", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[31] = {"Stevia", 400, 800, 20, 28, 50, 70, 50, 60, 0};
  plantas[32] = {"Bugambilia", 400, 800, 18, 24, 50, 70, 60, 70, 0};
  plantas[33] = {"Cuna de Moisés", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[34] = {"Bromelia", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[35] = {"Ave del paraíso", 400, 800, 20, 28, 60, 80, 60, 70, 0};
  plantas[36] = {"Plumeria", 400, 800, 20, 28, 60, 80, 60, 70, 0};
  plantas[37] = {"Coleo", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[38] = {"Impatiens", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[39] = {"Vinca", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[40] = {"Gardenia", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[41] = {"Loto", 400, 800, 22, 28, 60, 80, 70, 80, 0};
  plantas[42] = {"Helecho de Boston", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[43] = {"Ficus benjamina", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[44] = {"Monstera deliciosa", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[45] = {"Pothos", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[46] = {"Calathea", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[47] = {"Dieffenbachia", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[48] = {"Dracaena", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[49] = {"Spathiphyllum", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[50] = {"Anthurium", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[51] = {"Philodendron", 400, 800, 18, 24, 50, 70, 50, 60, 0};
  plantas[52] = {"Alocasia", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[53] = {"Maranta", 400, 800, 18, 24, 60, 80, 60, 70, 0};
  plantas[54] = {"Echeveria", 400, 800, 20, 28, 30, 50, 20, 40, 0};
  plantas[55] = {"Aloe vera", 400, 800, 20, 28, 30, 50, 20, 40, 0};
  plantas[56] = {"Haworthia", 400, 800, 20, 28, 30, 50, 20, 40, 0};
  plantas[57] = {"Lithops", 400, 800, 20, 28, 20, 40, 10, 20, 0};
  plantas[58] = {"Sedum", 400, 800, 20, 28, 30, 50, 20, 40, 0};
  plantas[59] = {"Kalanchoe", 400, 800, 20, 28, 30, 50, 30, 50, 0};
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

  // Si la lectura falla (NaN), devolver 0 para indicar error
  if (isnan(temp) || isnan(hum)) {
    temp = 0.0;
    hum = 0.0;
  }
}

int mapMQtoAQI(int raw) { return constrain(map(raw, 0, 1023, 0, 500), 0, 500); }

void aplicarSalidaManual(const String &key, const String &val) {
  if (key == "B1")
    digitalWrite(bombaPins[0], val == "1" ? HIGH : LOW);
  else if (key == "B2")
    digitalWrite(bombaPins[1], val == "1" ? HIGH : LOW);
  else if (key == "VENT") {
    if (val == "1")
      for (int i = 0; i < 3; i++)
        digitalWrite(ventiladores[i], HIGH);
    else
      for (int i = 0; i < 3; i++)
        digitalWrite(ventiladores[i], LOW);
  } else if (key == "E") {
    if (val == "1")
      for (int i = 0; i < 3; i++)
        digitalWrite(extractores[i], HIGH);
    else
      for (int i = 0; i < 3; i++)
        digitalWrite(extractores[i], LOW);
  } else if (key == "UVA")
    digitalWrite(ledUVA, val == "1" ? HIGH : LOW);
  else if (key == "ALARM_CMD") {
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

  if (cmd.startsWith("MODE:")) {
    String m = cmd.substring(5);
    m.trim();
    if (m == "AUTO")
      modoAutomatico = true;
    else if (m == "MANUAL")
      modoAutomatico = false;
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
  out += "B1:" + String(digitalRead(bombaPins[0]) == HIGH ? "1" : "0") + ";";
  out += "B2:" + String(digitalRead(bombaPins[1]) == HIGH ? "1" : "0") + ";";
  bool anyVent = (digitalRead(ventiladores[0]) == HIGH);
  out += "VENT:" + String(anyVent ? "1" : "0") + ";";
  bool anyExt = (digitalRead(extractores[0]) == HIGH);
  out += "E:" + String(anyExt ? "1" : "0") + ";";
  out += "UVA:" + String(digitalRead(ledUVA) == HIGH ? "1" : "0") + ";";
  out += "MODE:" + String(modoAutomatico ? "AUTO" : "MANUAL") + ";";

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
  Serial1.begin(115200); // Comunicación con ESP32 a 115200 baud

  // Inicializar DHT22
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
  // Leer DHT22
  float temp, hum;
  leerDHT(temp, hum);

  int rawMQ2 = analogRead(mq2Pin);
  int rawMQ5 = analogRead(mq5Pin);
  int rawMQ8 = analogRead(mq8Pin);

  int mq2_mapped = mapMQtoAQI(rawMQ2);
  int mq5_mapped = mapMQtoAQI(rawMQ5);
  int mq8_mapped = mapMQtoAQI(rawMQ8);

  int aqi = (mq2_mapped + mq5_mapped + mq8_mapped) / 3;

  // Leer Humedad de Suelo
  int rawSoil1 = analogRead(soilPins[0]);
  int rawSoil2 = analogRead(soilPins[1]);

  // Mapeo INVERTIDO para sensores de suelo (Resistivos)
  // Aire (~1023) -> 0% | Agua (~0) -> 100%
  int soil1 = map(rawSoil1, 1023, 0, 0, 100);
  soil1 = constrain(soil1, 0, 100);

  int soil2 = map(rawSoil2, 1023, 0, 0, 100);
  soil2 = constrain(soil2, 0, 100);

  // Leer Nivel de Agua
  int waterRaw1 = analogRead(waterLevelPins[0]);
  int waterRaw2 = analogRead(waterLevelPins[1]);

  // Mapeo con Umbral de Ruido para Agua
  // Si es < 100 (ruido en aire), forzamos a 0%
  int water1 = 0;
  if (waterRaw1 > 100)
    water1 = map(waterRaw1, 100, 700, 0, 100);
  water1 = constrain(water1, 0, 100);

  int water2 = 0;
  if (waterRaw2 > 100)
    water2 = map(waterRaw2, 100, 700, 0, 100);
  water2 = constrain(water2, 0, 100);

  // Leer comandos del ESP32
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

  // Lógica de Control Automático
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

  if (modoAutomatico) {
    // Control de Ventilación por AQI
    if (aqi > (int)co2Prom) {
      for (int i = 0; i < 3; i++) {
        digitalWrite(extractores[i], HIGH);
        digitalWrite(ventiladores[i], HIGH);
      }
    } else {
      // Control de Ventilación por Temperatura
      if (temp > tempProm) {
        for (int i = 0; i < 3; i++)
          digitalWrite(ventiladores[i], HIGH);
        for (int i = 0; i < 3; i++)
          digitalWrite(extractores[i], LOW);
      } else {
        for (int i = 0; i < 3; i++)
          digitalWrite(ventiladores[i], LOW);
        for (int i = 0; i < 3; i++)
          digitalWrite(extractores[i], LOW);
      }
    }

    // Control de UVA
    if (temp < tempProm)
      digitalWrite(ledUVA, HIGH);
    else
      digitalWrite(ledUVA, LOW);

    // Control de Riego
    for (int i = 0; i < 2; i++) {
      int humS = (i == 0) ? soil1 : soil2;
      int wLvl = (i == 0) ? water1 : water2;

      // Solo regar si hay planta seleccionada para esa zona
      if (totalSeleccionadas > i) {
        // Regar si humedad baja Y hay agua suficiente (>10%)
        if (humS < plantas[seleccionadas[i]].hum_suelo_min && wLvl > 10)
          digitalWrite(bombaPins[i], HIGH);
        else
          digitalWrite(bombaPins[i], LOW);
      } else {
        digitalWrite(bombaPins[i], LOW);
      }
    }
  }

  // --- LÓGICA DE ALARMA ---
  bool circuitoAbierto = (digitalRead(sensorPuertaPinNew) == HIGH);

  if (sistemaArmado && circuitoAbierto) {
    alarmaDisparada = true;
  }

  if (alarmaDisparada) {
    if ((millis() / 200) % 2 == 0)
      digitalWrite(buzzerPin, HIGH);
    else
      digitalWrite(buzzerPin, LOW);
  } else {
    digitalWrite(buzzerPin, LOW);
  }

  // --- LÓGICA RFID ---
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    if (tarjetaAutorizada(mfrc522.uid.uidByte)) {
      sistemaArmado = !sistemaArmado;
      alarmaDisparada = false;

      if (sistemaArmado) {
        // Sonido de Armado (Largo)
        digitalWrite(buzzerPin, HIGH);
        delay(800);
        digitalWrite(buzzerPin, LOW);
      } else {
        // Sonido de Desarmado (Dos cortos)
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

  // --- IMPRESIÓN DE DEPURACIÓN (MONITOR SERIAL) ---
  Serial.print("T:");
  Serial.print(temp, 1);
  Serial.print("C H:");
  Serial.print(hum, 1);
  Serial.print("% | MQ2:");
  Serial.print(rawMQ2);
  Serial.print(" MQ5:");
  Serial.print(rawMQ5);
  Serial.print(" MQ8:");
  Serial.print(rawMQ8);
  Serial.print(" | S1(Raw):");
  Serial.print(rawSoil1);
  Serial.print("->");
  Serial.print(soil1);
  Serial.print("% S2(Raw):");
  Serial.print(rawSoil2);
  Serial.print("->");
  Serial.print(soil2);
  Serial.print("% | W1(Raw):");
  Serial.print(waterRaw1);
  Serial.print("->");
  Serial.print(water1);
  Serial.print("% W2(Raw):");
  Serial.print(waterRaw2);
  Serial.print("->");
  Serial.println(water2);

  enviarEstadoPorSerial1(temp, hum, mq2_mapped, mq5_mapped, mq8_mapped, aqi,
                         soil1, soil2, water1, water2);

  delay(1000);
}
