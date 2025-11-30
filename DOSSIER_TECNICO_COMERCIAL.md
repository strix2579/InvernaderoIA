# InvernaderoIA — Greentech
## Dossier Técnico y Comercial - Sistema IoT de Invernadero Inteligente

---

## 1. RESUMEN EJECUTIVO

**InvernaderoIA — Greentech** es un sistema de automatización inteligente para invernaderos que combina sensores ambientales (DHT22), de suelo, de gases (MQ2/MQ5/MQ8) y control de acceso RFID con actuadores automatizados (riego, ventilación, iluminación) gestionados por Arduino Mega. El sistema monitorea en tiempo real temperatura, humedad, calidad del aire y humedad del suelo, tomando decisiones automáticas mediante algoritmos de IA para optimizar condiciones de cultivo, reducir consumo de agua hasta 40%, prevenir pérdidas por condiciones adversas y permitir gestión remota vía app móvil. **Beneficios concretos:** ahorro de 60% en mano de obra, incremento de 25-35% en productividad, alertas tempranas de riesgos (gases, sequía, heladas) y trazabilidad completa mediante logs y acceso RFID.

---

## 2. LISTA DE COMPONENTES

### 2.1 Componentes Principales

| Componente | Cantidad | Función | Voltaje Operación | Alternativas |
|------------|----------|---------|-------------------|--------------|
| **Arduino Mega 2560** | 1 | Controlador principal | 7-12V DC (recomendado 9V) | Arduino Mega compatible, ATmega2560 |
| **ESP32 DevKit V1** | 1 | Conectividad WiFi/BLE | 5V vía USB / 3.3V lógica | ESP32-WROOM-32, NodeMCU-32S |
| **DHT22** | 4-5 | Sensor temp/humedad ambiente | 3.3-5V | DHT11 (menor precisión), SHT31, BME280 |
| **Sensor Humedad Suelo Capacitivo** | 2 | Humedad de sustrato | 3.3-5V | Sensor resistivo (menos duradero), YL-69 |
| **MQ-2** | 1 | Detector gas combustible/humo | 5V | MQ-135 (multigas) |
| **MQ-5** | 1 | Detector GLP/gas natural | 5V | MQ-6 (propano) |
| **MQ-8** | 1 | Detector hidrógeno | 5V | MQ-135 |
| **MFRC522** | 1 | Lector RFID 13.56MHz | 3.3V | PN532, RC522 |
| **Módulo Relé 8 canales** | 1 | Control actuadores AC/DC | 5V señal / 250VAC-10A carga | Relés individuales, relé estado sólido |
| **Bomba de agua 12V** | 1-2 | Sistema de riego | 12V DC | Bomba 5V (menor caudal), electroválvula |
| **Ventiladores 12V** | 2 | Ventilación/circulación | 12V DC | Ventiladores 5V, extractores AC |
| **LED grow lights / tiras LED** | 1-2 | Iluminación suplementaria | 12V DC | Tiras 5V, focos LED AC |
| **Fuente 12V 5A** | 1 | Alimentación sistema | 110/220VAC → 12VDC | Fuente 12V 3A mínimo |
| **Fuente 5V 3A** | 1 | Alimentación Arduino/sensores | 110/220VAC → 5VDC | USB power bank (backup) |
| **Cables Jumper M-M, M-F** | 50+ | Conexiones | - | Cables AWG22-24 |
| **Protoboard / PCB personalizada** | 1-2 | Montaje circuito | - | Borneras de conexión |
| **Tarjetas RFID** | 5-10 | Control acceso | - | Tags RFID 13.56MHz |

### 2.2 Componentes de Protección y Seguridad

| Componente | Cantidad | Función | Especificación |
|------------|----------|---------|----------------|
| **Fusibles** | 3-5 | Protección sobrecorriente | 2A (Arduino), 5A (actuadores) |
| **Diodos 1N4007** | 8 | Protección inductiva relés | 1A, 1000V |
| **Optoacopladores 4N35** | 8 (opcional) | Aislamiento señal relés | - |
| **Regulador 7805** | 1 | Backup 5V | 1.5A mínimo con disipador |
| **Capacitores 100µF** | 3-5 | Filtrado alimentación | 16V electrolítico |

### 2.3 Rangos de Voltaje Recomendados

- **Arduino Mega VIN:** 7-12V (óptimo 9V, max absoluto 20V)
- **Pin 5V Arduino:** Salida 5V 400mA máximo total
- **Pin 3.3V Arduino:** Salida 3.3V 50mA máximo
- **ESP32:** 5V entrada USB, 3.3V lógica GPIO (¡NO tolerante a 5V!)
- **Relés:** Señal 5V, carga según especificación (típico 250VAC 10A / 30VDC 10A)
- **Sensores MQ:** 5V, consumo 150-200mA c/u (precalentamiento)
- **DHT22:** 3.3-5V, consumo <2.5mA
- **RFID MFRC522:** 3.3V (usar divisor de voltaje si señal desde Arduino 5V)

---

## 3. DIAGRAMA DE CONEXIÓN Y DESCRIPCIÓN DE PINES

### 3.1 Arduino Mega - Alimentación

```
ALIMENTACIÓN:
  VIN (Jack barrel) ← Fuente 9V 2A
  5V → Distribución sensores DHT22, MQ, relés
  3.3V → RFID MFRC522 VCC (alternativamente usar fuente externa 3.3V)
  GND → Tierra común (todos los componentes)
```

### 3.2 Conexiones Sensores DHT22

| Sensor | Pin Arduino | VCC | GND | Notas |
|--------|-------------|-----|-----|-------|
| DHT22 #1 (zona 1) | Pin 22 | 5V | GND | Resistor 10kΩ pull-up DATA-VCC |
| DHT22 #2 (zona 2) | Pin 23 | 5V | GND | Resistor 10kΩ pull-up DATA-VCC |
| DHT22 #3 (zona 3) | Pin 24 | 5V | GND | Resistor 10kΩ pull-up DATA-VCC |
| DHT22 #4 (zona 4) | Pin 25 | 5V | GND | Resistor 10kΩ pull-up DATA-VCC |
| DHT22 #5 (exterior) | Pin 26 (opcional) | 5V | GND | Resistor 10kΩ pull-up DATA-VCC |

### 3.3 Conexiones Sensores de Humedad de Suelo

| Sensor | Pin Analógico | VCC | GND | Rango |
|--------|---------------|-----|-----|-------|
| Humedad Suelo #1 | A0 | 5V | GND | 0-1023 (calibrar seco/mojado) |
| Humedad Suelo #2 | A1 | 5V | GND | 0-1023 (calibrar seco/mojado) |

**Calibración típica:**
- Aire (seco): ~600-800
- Suelo húmedo: ~200-400
- Agua: ~100-200

### 3.4 Conexiones Sensores MQ (Gas)

| Sensor | Pin Analógico | Pin Digital | VCC | GND | Precalentamiento |
|--------|---------------|-------------|-----|-----|------------------|
| MQ-2 (humo/gas)| A2 | Pin 27 (D0) | 5V | GND | 24-48h óptimo, mín 2min |
| MQ-5 (GLP) | A3 | Pin 28 (D0) | 5V | GND | 24-48h óptimo, mín 2min |
| MQ-8 (H₂) | A4 | Pin 29 (D0) | 5V | GND | 24-48h óptimo, mín 2min |

**IMPORTANTE:** Los sensores MQ consumen ~150mA c/u. Usar fuente externa o distribuir carga.

### 3.5 Conexiones RFID MFRC522

| Pin MFRC522 | Pin Arduino | Notas |
|-------------|-------------|-------|
| SDA (SS) | Pin 53 | Chip Select |
| SCK | Pin 52 | SPI Clock |
| MOSI | Pin 51 | Master Out Slave In |
| MISO | Pin 50 | Master In Slave Out |
| IRQ | - | No usado |
| GND | GND | Tierra |
| RST | Pin 49 | Reset |
| 3.3V | 3.3V | **NO 5V** |

**⚠️ ADVERTENCIA:** MFRC522 es 3.3V. Si pines SPI Arduino (5V) dañan módulo, usar divisor resistivo (1kΩ/2kΩ) en SDA, SCK, MOSI.

### 3.6 Conexiones Módulo de Relés (8 canales)

| Canal Relé | Pin Arduino | Actuador Controlado | Voltaje Carga |
|------------|-------------|---------------------|---------------|
| IN1 | Pin 30 | Bomba riego zona 1 | 12V DC |
| IN2 | Pin 31 | Bomba riego zona 2 | 12V DC |
| IN3 | Pin 32 | Ventilador 1 | 12V DC |
| IN4 | Pin 33 | Ventilador 2 | 12V DC |
| IN5 | Pin 34 | Luces LED zona 1 | 12V DC |
| IN6 | Pin 35 | Luces LED zona 2 | 12V DC |
| IN7 | Pin 36 | Calefactor (opcional) | 110/220VAC |
| IN8 | Pin 37 | Reserva/Alarma | 12V DC |
| VCC | 5V | Alimentación lógica | - |
| GND | GND | Tierra común | - |

**Protección Relés:**
- Soldar diodo 1N4007 antiparalelo en bobina de cada relé (cátodo a VCC)
- Fusible 5A en línea positiva 12V actuadores
- Considerar optoacopladores para aislar Arduino de circuito de potencia

### 3.7 Comunicación Arduino Mega ↔ ESP32

```
Arduino Mega → ESP32:
  TX1 (Pin 18) → RX (GPIO16) ESP32
  RX1 (Pin 19) → TX (GPIO17) ESP32
  GND → GND (tierra común OBLIGATORIA)
  
⚠️ IMPORTANTE: ESP32 es 3.3V lógica
  - Usar divisor resistivo 2kΩ/1kΩ en TX Arduino → RX ESP32
  - RX Arduino tolera 3.3V directo desde TX ESP32
```

### 3.8 Diagrama de Tierra y Alimentación

```
FUENTE 12V 5A:
  (+) → Fusible 5A → VIN relés → Actuadores 12V
  (-) → GND común
  
FUENTE 9V 2A (o regulador desde 12V):
  (+) → Arduino Mega VIN
  (-) → GND común
  
ARDUINO MEGA:
  5V → DHT22, MQ sensors, módulo relé VCC, ESP32 VIN (opcional)
  3.3V → MFRC522
  GND → **TIERRA COMÚN CON TODAS LAS FUENTES**
```

**⚠️ CRÍTICO:** Usar **tierra común única** para evitar diferencias de potencial. Punto estrella (star ground) recomendado.

### 3.9 Recomendaciones de Protección

1. **Fusibles:**
   - 2A en línea VIN Arduino
   - 5A en línea 12V actuadores
   - 1A en línea 5V sensores (opcional)

2. **Diodos protección:**
   - 1N4007 en cada bobina de relé
   - 1N4007 en cada motor/bomba (antiparalelo)

3. **Drivers para Relés:**
   - Considerar usar ULN2803 (Darlington array) entre Arduino y módulo relés
   - O usar módulo relés con optoacoplador integrado

4. **Capacitores de filtrado:**
   - 100µF en entrada VIN Arduino
   - 100µF en entrada fuente 12V
   - 0.1µF cerámico cerca de cada sensor (desacople)

5. **Reguladores de respaldo:**
   - 7805 + disipador para generar 5V desde 12V (backup)
   - AMS1117-3.3 para línea 3.3V si MFRC522 + ESP32 consumen mucho

---

## 4. DESCRIPCIÓN DEL SOFTWARE

### 4.1 Arquitectura General

```
[Sensores] → [Arduino Mega] → [ESP32] → [WiFi] → [FastAPI Backend] → [Base Datos]
                    ↓                                       ↓
                [Actuadores]                          [Modelo IA]
                [RFID]                                      ↓
                [Logs SD]                            [App Móvil]
```

### 4.2 Flujo Principal del Firmware Arduino Mega

#### Pseudocódigo Ciclo Principal

```cpp
// INICIALIZACIÓN
void setup() {
  // 1. Inicializar serial (monitor y ESP32)
  Serial.begin(115200);   // Debug
  Serial1.begin(115200);  // Comunicación ESP32
  
  // 2. Inicializar sensores
  inicializarDHT22(pin22, pin23, pin24, pin25);
  inicializarMQ(pinA2, pinA3, pinA4);
  inicializarRFID(pin53_SS, pin49_RST);
  
  // 3. Configurar pines de relés
  for (int i = 30; i <= 37; i++) {
    pinMode(i, OUTPUT);
    digitalWrite(i, HIGH); // Relés activos en BAJO
  }
  
  // 4. Cargar configuración desde EEPROM
  cargarConfiguracion();
  
  // 5. Precalentamiento sensores MQ
  if (primerArranque) {
    esperarPrecalentamientoMQ(120); // 2 minutos mínimo
  }
  
  // 6. Inicializar tarjeta SD para logs
  inicializarSD();
  
  Serial.println("Sistema InvernaderoIA iniciado");
}

// LOOP PRINCIPAL
void loop() {
  unsigned long ahora = millis();
  
  // 1. Lectura periódica de sensores (cada 2s)
  if (ahora - ultimaLectura > 2000) {
    leerTodosSensores();
    ultimaLectura = ahora;
  }
  
  // 2. Envío de datos a ESP32 (cada 5s)
  if (ahora - ultimoEnvio > 5000) {
    enviarDatosJSON_ESP32();
    ultimoEnvio = ahora;
  }
  
  // 3. Control automático por umbrales
  if (modoAutomatico) {
    controlarPorUmbrales();
  }
  
  // 4. Escuchar comandos desde ESP32
  if (Serial1.available()) {
    procesarComandoESP32();
  }
  
  // 5. Lectura RFID
  if (rfid.PICC_IsNewCardPresent()) {
    procesarTarjetaRFID();
  }
  
  // 6. Verificación de alarmas
  verificarAlarmas();
  
  // 7. Log periódico a SD (cada 10min)
  if (ahora - ultimoLog > 600000) {
    guardarLogSD();
    ultimoLog = ahora;
  }
}
```

### 4.3 Lectura de Sensores

```cpp
void leerTodosSensores() {
  // DHT22 - Temperatura y Humedad
  for (int i = 0; i < NUM_DHT; i++) {
    sensorData.temperatura[i] = dht[i].readTemperature();
    sensorData.humedad[i] = dht[i].readHumidity();
    
    // Validación
    if (isnan(sensorData.temperatura[i]) || 
        sensorData.temperatura[i] < -40 || 
        sensorData.temperatura[i] > 80) {
      sensorData.temperatura[i] = ERROR_VALUE;
      errores.dht[i]++;
    }
  }
  
  // Humedad de Suelo (0-100% calibrado)
  for (int i = 0; i < NUM_SOIL; i++) {
    int valorCrudo = analogRead(PIN_SOIL[i]);
    sensorData.humedadSuelo[i] = map(valorCrudo, 
                                     calibracion.sueloSeco, 
                                     calibracion.sueloMojado, 
                                     0, 100);
    sensorData.humedadSuelo[i] = constrain(sensorData.humedadSuelo[i], 0, 100);
  }
  
  // Sensores MQ - Gases (PPM)
  sensorData.gasHumo = leerMQ2_PPM(A2);      // MQ-2
  sensorData.gasGLP = leerMQ5_PPM(A3);       // MQ-5
  sensorData.gasH2 = leerMQ8_PPM(A4);        // MQ-8
  
  // Nivel de agua (simulado o sensor ultrasónico)
  sensorData.nivelAgua = leerNivelAgua();
}

float leerMQ2_PPM(int pin) {
  int valorADC = analogRead(pin);
  float voltaje = valorADC * (5.0 / 1023.0);
  float RS = ((5.0 * RL) / voltaje) - RL;
  float ratio = RS / R0_MQ2;
  float ppm = pow(10, ((log10(ratio) - B_MQ2) / M_MQ2));
  return ppm;
}
```

### 4.4 Control Automático por Umbrales

```cpp
void controlarPorUmbrales() {
  // RIEGO: Humedad de suelo < 30% → Regar 60s
  for (int i = 0; i < NUM_SOIL; i++) {
    if (sensorData.humedadSuelo[i] < config.umbralRiegoMin) {
      if (!estadoRiego[i]) {
        activarRiego(i, config.duracionRiego); // 60000ms = 60s
        logEvento("Riego automático zona " + String(i+1));
      }
    } else if (sensorData.humedadSuelo[i] > config.umbralRiegoMax) {
      desactivarRiego(i);
    }
  }
  
  // VENTILACIÓN: Temperatura > 30°C o Humedad > 80%
  float tempPromedio = promedioTemperaturas();
  float humPromedio = promedioHumedad();
  
  if (tempPromedio > config.umbralTempMax || 
      humPromedio > config.umbralHumMax) {
    activarVentiladores();
    logEvento("Ventilación activada: T=" + String(tempPromedio) + 
              "°C, H=" + String(humPromedio) + "%");
  } else if (tempPromedio < config.umbralTempMin) {
    desactivarVentiladores();
  }
  
  // ILUMINACIÓN: Control por horario o luz insuficiente
  if (horaActual >= config.horaInicioLuz && 
      horaActual <= config.horaFinLuz) {
    activarIluminacion();
  } else {
    desactivarIluminacion();
  }
  
  // ALARMA GAS: MQ-2 > 1000 PPM (humo/gas combustible)
  if (sensorData.gasHumo > config.umbralGasAlarm) {
    activarAlarma();
    desactivarTodoMenosVentilacion();
    logEvento("ALARMA: Gas detectado " + String(sensorData.gasHumo) + " PPM");
  }
}

void activarRiego(int zona, unsigned long duracion) {
  int pinRele = 30 + zona; // IN1=30, IN2=31
  digitalWrite(pinRele, LOW); // Activar relé (lógica invertida)
  estadoRiego[zona] = true;
  tiempoRiego[zona] = millis();
  duracionRiego[zona] = duracion;
}
```

### 4.5 Comunicación con ESP32 (Formato JSON)

```cpp
void enviarDatosJSON_ESP32() {
  StaticJsonDocument<512> doc;
  
  doc["tipo"] = "sensor_data";
  doc["timestamp"] = millis();
  
  // Temperaturas
  JsonArray temp = doc.createNestedArray("temperatura");
  for (int i = 0; i < NUM_DHT; i++) {
    temp.add(sensorData.temperatura[i]);
  }
  
  // Humedad ambiente
  JsonArray hum = doc.createNestedArray("humedad");
  for (int i = 0; i < NUM_DHT; i++) {
    hum.add(sensorData.humedad[i]);
  }
  
  // Humedad suelo
  JsonArray soil = doc.createNestedArray("humedad_suelo");
  for (int i = 0; i < NUM_SOIL; i++) {
    soil.add(sensorData.humedadSuelo[i]);
  }
  
  // Gases
  doc["gas_humo"] = sensorData.gasHumo;
  doc["gas_glp"] = sensorData.gasGLP;
  doc["gas_h2"] = sensorData.gasH2;
  
  // Estados actuadores
  JsonObject estados = doc.createNestedObject("actuadores");
  estados["riego1"] = estadoRiego[0];
  estados["riego2"] = estadoRiego[1];
  estados["ventilador"] = estadoVentiladores;
  estados["luz"] = estadoLuces;
  
  serializeJson(doc, Serial1);
  Serial1.println(); // Delimitador
}

void procesarComandoESP32() {
  String comando = Serial1.readStringUntil('\n');
  StaticJsonDocument<256> doc;
  
  DeserializationError error = deserializeJson(doc, comando);
  if (error) {
    Serial.println("Error parsing JSON desde ESP32");
    return;
  }
  
  String tipo = doc["tipo"];
  
  if (tipo == "comando") {
    String accion = doc["accion"];
    int zona = doc["zona"] | 0;
    
    if (accion == "riego_on") {
      activarRiego(zona, 60000);
      enviarACK(true, "Riego activado");
    } else if (accion == "riego_off") {
      desactivarRiego(zona);
      enviarACK(true, "Riego desactivado");
    } else if (accion == "ventilador_on") {
      activarVentiladores();
      enviarACK(true, "Ventiladores activados");
    } else if (accion == "modo_auto") {
      modoAutomatico = doc["valor"];
      enviarACK(true, "Modo automático: " + String(modoAutomatico));
    }
  } else if (tipo == "config") {
    actualizarConfiguracion(doc);
  }
}
```

### 4.6 Manejo de Errores y Logging

```cpp
void verificarAlarmas() {
  // Error sensor: Más de 5 lecturas fallidas consecutivas
  for (int i = 0; i < NUM_DHT; i++) {
    if (errores.dht[i] > 5) {
      alarmas.sensorFallo[i] = true;
      logEvento("ALARMA: DHT22 #" + String(i+1) + " no responde");
    }
  }
  
  // Nivel de agua bajo
  if (sensorData.nivelAgua < 20) {
    alarmas.aguaBaja = true;
    logEvento("ALARMA: Nivel de agua bajo: " + String(sensorData.nivelAgua) + "%");
    desactivarRiego(0);
    desactivarRiego(1);
  }
  
  // Temperatura extrema
  if (tempPromedio > 45 || tempPromedio < 5) {
    alarmas.tempExtrema = true;
    logEvento("ALARMA: Temperatura extrema: " + String(tempPromedio) + "°C");
  }
  
  // Detector de cortocircuito (voltaje pin anómalo)
  if (analogRead(A5) < 50) { // <0.25V cuando esperábamos 5V
    alarmas.cortocircuito = true;
    desactivarTodosActuadores();
    logEvento("ALARMA CRÍTICA: Posible cortocircuito detectado");
  }
}

void guardarLogSD() {
  File archivo = SD.open("logs.txt", FILE_WRITE);
  if (archivo) {
    archivo.print(obtenerTimestamp());
    archivo.print(",");
    archivo.print(promedioTemperaturas());
    archivo.print(",");
    archivo.print(promedioHumedad());
    archivo.print(",");
    archivo.print(sensorData.humedadSuelo[0]);
    archivo.print(",");
    archivo.print(sensorData.gasHumo);
    archivo.print(",");
    archivo.println(estadoRiego[0] + estadoRiego[1] + estadoVentiladores);
    archivo.close();
  } else {
    errores.sd++;
  }
}
```

### 4.7 Gestión de RFID

```cpp
void procesarTarjetaRFID() {
  if (!rfid.PICC_ReadCardSerial()) return;
  
  String uidString = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    uidString += String(rfid.uid.uidByte[i], HEX);
  }
  uidString.toUpperCase();
  
  // Verificar si tarjeta autorizada
  int usuario = verificarTarjeta(uidString);
  
  if (usuario >= 0) {
    accesos.usuario[usuario]++;
    accesos.ultimoAcceso = millis();
    
    logEvento("Acceso concedido: Usuario " + String(usuario) + 
              " UID:" + uidString);
    
    // Permitir control manual temporal (5 min)
    habilitarControlManual(300000);
    
    // LED/Buzzer confirmación
    parpadearLED(LED_ACCESO, 3);
  } else {
    logEvento("Acceso DENEGADO: UID desconocido " + uidString);
    parpadearLED(LED_ALARMA, 5);
  }
  
  rfid.PICC_HaltA();
}
```

### 4.8 Ejemplo de Configuración

```cpp
// Umbrales por defecto (guardados en EEPROM)
struct Configuracion {
  // Riego
  uint8_t umbralRiegoMin = 30;      // % - Activar riego
  uint8_t umbralRiegoMax = 60;      // % - Desactivar riego
  uint32_t duracionRiego = 60000;   // ms - 60 segundos
  uint16_t intervaloRiego = 3600;   // s - 1 hora mínimo entre riegos
  
  // Temperatura
  float umbralTempMin = 18.0;       // °C - Activar calefacción
  float umbralTempMax = 30.0;       // °C - Activar ventilación
  
  // Humedad ambiente
  uint8_t umbralHumMin = 60;        // %
  uint8_t umbralHumMax = 80;        // %
  
  // Iluminación
  uint8_t horaInicioLuz = 6;        // 6:00 AM
  uint8_t horaFinLuz = 20;          // 8:00 PM
  uint16_t intensidadLuz = 80;      // % PWM
  
  // Alarmas
  uint16_t umbralGasAlarm = 1000;   // PPM
  uint8_t umbralAguaBaja = 20;      // %
  
  // Calibración sensores suelo
  uint16_t sueloSeco = 700;         // Valor ADC en aire
  uint16_t sueloMojado = 300;       // Valor ADC en agua
} config;
```

### 4.9 Firmware ESP32 (WiFi/WebSocket)

```cpp
// ESP32 - Puente de comunicación
void setup() {
  Serial.begin(115200);  // Debug
  Serial2.begin(115200); // Arduino Mega
  
  conectarWiFi();
  conectarWebSocket();
}

void loop() {
  // Recibir datos de Arduino
  if (Serial2.available()) {
    String json = Serial2.readStringUntil('\n');
    enviarWebSocket(json);
  }
  
  // Recibir comandos de Backend
  webSocket.loop();
}

void onWebSocketEvent(WStype_t type, uint8_t *payload, size_t length) {
  if (type == WStype_TEXT) {
    // Reenviar comando a Arduino
    Serial2.println((char*)payload);
  }
}
```

---

## 5. CONFIGURACIONES DE EJEMPLO

### Perfil 1: Cultivo de Tomate
```json
{
  "cultivo": "tomate",
  "umbralRiegoMin": 35,
  "umbralRiegoMax": 65,
  "duracionRiego": 90000,
  "tempOptima": 24,
  "tempMin": 18,
  "tempMax": 28,
  "humedadMin": 60,
  "humedadMax": 75,
  "horasLuz": 14
}
```

### Perfil 2: Lechuga
```json
{
  "cultivo": "lechuga",
  "umbralRiegoMin": 40,
  "umbralRiegoMax": 70,
  "duracionRiego": 45000,
  "tempOptima": 18,
  "tempMin": 12,
  "tempMax": 22,
  "humedadMin": 70,
  "humedadMax": 85,
  "horasLuz": 12
}
```

---

*Continúa en MANUAL_USUARIO.md*
