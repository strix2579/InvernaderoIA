# Guía de Integración ESP32 - Invernadero IoT

## Requisitos de Hardware

### Sensores
- **DHT22**: Sensor de temperatura y humedad
- **2x Sensores de Humedad de Suelo**: Capacitivos o resistivos
- **MQ-2**: Sensor de gas (humo, propano, metano)
- **MQ-5**: Sensor de gas (gas natural, GLP)
- **MQ-8**: Sensor de hidrógeno
- **Módulo WiFi**: Integrado en ESP32

### Actuadores
- **Ventilador**: Controlado por relé
- **Bomba de agua**: Controlada por relé
- **LED**: Para iluminación o indicadores

### Componentes Adicionales
- **ESP32 DevKit**: Microcontrolador principal
- **Módulo relé de 4 canales**: Para controlar actuadores
- **Fuente de alimentación 5V**: Para ESP32 y sensores
- **Protoboard y cables**: Para conexiones

---

## Instalación de Librerías Arduino

Abre el Arduino IDE y ve a **Sketch → Include Library → Manage Libraries**, luego instala:

1. **WiFi** (incluida en ESP32 core)
2. **WebSocketsClient** por Markus Sattler
3. **ArduinoJson** por Benoit Blanchon (versión 6.x)
4. **DHT sensor library** por Adafruit

---

## Configuración del Proyecto

### 1. Configurar WiFi y Servidor

Edita las siguientes líneas en `esp32_firmware.cpp`:

```cpp
const char* ssid = "TU_RED_WIFI";
const char* password = "TU_CONTRASEÑA";
const char* ws_server = "192.168.1.100"; // IP de tu servidor API
const int ws_port = 8000;
```

### 2. Configurar Pines

Ajusta los pines según tu conexión física:

```cpp
#define DHT_PIN 4
#define SOIL1_PIN 34
#define SOIL2_PIN 35
#define MQ2_PIN 32
#define MQ5_PIN 33
#define MQ8_PIN 25
#define FAN_PIN 26
#define PUMP_PIN 27
#define LED_PIN 14
```

### 3. Leer Sensores Reales

Reemplaza los valores simulados con lecturas reales:

```cpp
#include <DHT.h>

DHT dht(DHT_PIN, DHT22);

void setup() {
    dht.begin();
    pinMode(SOIL1_PIN, INPUT);
    pinMode(SOIL2_PIN, INPUT);
    // ... otros pines
}

void sendSensorUpdate() {
    // Leer DHT22
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    
    // Leer humedad de suelo (0-4095 en ESP32)
    int soil1_raw = analogRead(SOIL1_PIN);
    int soil2_raw = analogRead(SOIL2_PIN);
    float soil1 = map(soil1_raw, 0, 4095, 0, 100);
    float soil2 = map(soil2_raw, 0, 4095, 0, 100);
    
    // Leer sensores de gas
    int mq2 = analogRead(MQ2_PIN);
    int mq5 = analogRead(MQ5_PIN);
    int mq8 = analogRead(MQ8_PIN);
    
    // Calcular AQI (simplificado)
    int aqi = (mq2 + mq5 + mq8) / 3;
    
    // Enviar datos...
}
```

---

## Flujo de Trabajo Completo

### 1. Iniciar la API

```bash
cd InvernaderoIA/api
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Cargar Firmware en ESP32

1. Conecta el ESP32 a tu PC vía USB
2. Abre `esp32_firmware.cpp` en Arduino IDE
3. Selecciona la placa: **Tools → Board → ESP32 Dev Module**
4. Selecciona el puerto: **Tools → Port → COMx** (Windows) o **/dev/ttyUSBx** (Linux)
5. Haz clic en **Upload**

### 3. Monitorear Serial

Abre el **Serial Monitor** (115200 baud) para ver los logs:

```
WiFi connected
[WSc] Connected to url: /ws/iot/esp32_client_1
PREDICTION: NORMAL
COMMAND RECEIVED: fan -> ON for 60 seconds
```

---

## Pruebas

### Prueba 1: Conexión WebSocket

```bash
cd InvernaderoIA/tests
python manual_ws_test.py
```

### Prueba 2: Tests Automatizados

```bash
pip install pytest websockets
pytest test_iot_integration.py -v
```

---

## Control Bluetooth (Alternativa)

Para control directo desde la app sin WiFi:

### 1. Agregar BLE al ESP32

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

void setupBLE() {
    BLEDevice::init("Invernadero_ESP32");
    BLEServer *pServer = BLEDevice::createServer();
    BLEService *pService = pServer->createService(SERVICE_UUID);
    BLECharacteristic *pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
    );
    pCharacteristic->setValue("Hello BLE");
    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->start();
}
```

### 2. Conectar desde Flutter

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Escanear dispositivos
FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

// Conectar
await device.connect();

// Leer/escribir características
await characteristic.write([0x01, 0x02]);
```

---

## Solución de Problemas

### Error: "WiFi connected" pero no conecta al WebSocket

- Verifica que la IP del servidor sea correcta
- Asegúrate de que el firewall permita conexiones en el puerto 8000
- Usa `ping <server_ip>` desde el ESP32 para verificar conectividad

### Error: "deserializeJson() failed"

- Verifica que el JSON enviado sea válido
- Aumenta el tamaño del `DynamicJsonDocument` si es necesario

### Sensores devuelven valores incorrectos

- Calibra los sensores de humedad de suelo
- Verifica las conexiones físicas
- Usa resistencias pull-up/pull-down si es necesario

---

## Próximos Pasos

1. Implementar autenticación con tokens
2. Agregar OTA (Over-The-Air) updates
3. Implementar modo deep sleep para ahorro de energía
4. Crear dashboard en tiempo real en Flutter
