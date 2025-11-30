# Protocolo WebSocket IoT - Especificación Completa

## Descripción General

Este documento define el protocolo de comunicación WebSocket entre los dispositivos ESP32 y la API Python para el sistema de invernadero inteligente.

**Endpoint WebSocket:** `ws://<server_ip>:<port>/ws/iot/{client_id}`

Ejemplo: `ws://192.168.1.100:8000/ws/iot/esp32_client_1`

## Tipos de Eventos

### 1. `heartbeat` (ESP32 → API)

**Propósito:** Mantener la conexión activa y verificar que el cliente sigue conectado.

**Frecuencia:** Cada 30 segundos.

**Formato:**
```json
{
  "type": "heartbeat"
}
```

**Respuesta esperada:**
```json
{
  "type": "heartbeat_ack"
}
```

---

### 2. `sensor_update` (ESP32 → API)

**Propósito:** Enviar lecturas de sensores para análisis y predicción.

**Frecuencia:** Cada 5 segundos (configurable).

**Formato:**
```json
{
  "type": "sensor_update",
  "payload": {
    "temp": 25.5,
    "hum": 60.0,
    "soil1": 70.2,
    "soil2": 72.5,
    "mq2": 120.0,
    "mq5": 110.0,
    "mq8": 130.0,
    "aqi": 45.0
  }
}
```

**Campos del payload:**
- `temp`: Temperatura en °C (float)
- `hum`: Humedad relativa en % (float)
- `soil1`: Humedad del suelo planta 1 en % (float)
- `soil2`: Humedad del suelo planta 2 en % (float)
- `mq2`: Lectura sensor MQ-2 (0-1023) (float)
- `mq5`: Lectura sensor MQ-5 (0-1023) (float)
- `mq8`: Lectura sensor MQ-8 (0-1023) (float)
- `aqi`: Índice de calidad del aire (0-500) (float)

**Respuesta esperada:**
```json
{
  "type": "prediction_result",
  "payload": {
    "predicciones": {
      "NORMAL": 0.85,
      "INCENDIO": 0.05,
      "FUGA_H2": 0.03,
      "FALLA_ELECTRICA": 0.04,
      "PLAGA": 0.03
    },
    "clase_predicha": "NORMAL"
  }
}
```

---

### 3. `command` (API → ESP32)

**Propósito:** Enviar comandos de control a los actuadores del ESP32.

**Formato:**
```json
{
  "type": "command",
  "payload": {
    "actuator": "fan",
    "action": "ON",
    "duration": 60
  }
}
```

**Actuadores soportados:**
- `fan`: Ventilador
- `water_pump`: Bomba de agua
- `led`: Luz LED
- `heater`: Calentador (si aplica)

**Acciones:**
- `ON`: Encender
- `OFF`: Apagar

**Campos opcionales:**
- `duration`: Duración en segundos (int, opcional)

**Respuesta esperada (ACK):**
```json
{
  "type": "ack",
  "message_id": "command_received"
}
```

---

### 4. `ack` (ESP32 → API)

**Propósito:** Confirmar la recepción y ejecución de un comando.

**Formato:**
```json
{
  "type": "ack",
  "message_id": "command_received",
  "status": "success"
}
```

**Campos opcionales:**
- `status`: `"success"` o `"error"`
- `error_message`: Descripción del error (si `status` es `"error"`)

---

### 5. `config_update` (API → ESP32)

**Propósito:** Actualizar la configuración del ESP32 (frecuencia de envío, umbrales, etc.).

**Formato:**
```json
{
  "type": "config_update",
  "payload": {
    "sensor_interval": 10000,
    "heartbeat_interval": 30000
  }
}
```

**Respuesta esperada:**
```json
{
  "type": "ack",
  "message_id": "config_updated"
}
```

---

## Lógica de Reconexión

El ESP32 debe implementar reconexión automática en caso de desconexión:

1. Detectar desconexión mediante el evento `WStype_DISCONNECTED`.
2. Intentar reconectar cada 5 segundos.
3. Usar `webSocket.setReconnectInterval(5000)` en la librería `WebSocketsClient`.

---

## Manejo de Comandos Pendientes

Si el ESP32 se desconecta mientras hay comandos pendientes:

1. La API puede almacenar comandos en una cola por `client_id`.
2. Al reconectarse, la API envía los comandos pendientes.
3. El ESP32 confirma cada comando con un `ack`.

---

## Control Automático desde la IA

La API puede enviar comandos automáticamente basados en las predicciones:

**Ejemplo 1: Detección de Incendio**
```json
// Predicción
{
  "type": "prediction_result",
  "payload": {
    "clase_predicha": "INCENDIO"
  }
}

// Comando automático
{
  "type": "command",
  "payload": {
    "actuator": "water_pump",
    "action": "ON",
    "duration": 10
  }
}
```

**Ejemplo 2: Detección de Plaga**
```json
// Comando automático
{
  "type": "command",
  "payload": {
    "actuator": "fan",
    "action": "ON",
    "duration": 60
  }
}
```

---

## Alternativa: Control Bluetooth

Para control directo desde la app móvil sin pasar por la API:

1. El ESP32 implementa un servidor Bluetooth Low Energy (BLE).
2. La app Flutter se conecta directamente al ESP32 vía BLE.
3. Usa el mismo formato JSON para comandos.

**Ventajas:**
- No requiere conexión a internet.
- Menor latencia.

**Desventajas:**
- No hay registro en la API.
- No hay predicciones automáticas.

---

## Ejemplos de Flujo Completo

### Flujo 1: Envío de Datos y Predicción Normal

```
ESP32 → API: {"type": "sensor_update", "payload": {...}}
API → ESP32: {"type": "prediction_result", "payload": {"clase_predicha": "NORMAL"}}
```

### Flujo 2: Detección de Incendio y Activación Automática

```
ESP32 → API: {"type": "sensor_update", "payload": {"temp": 45.0, "mq2": 800.0, ...}}
API → ESP32: {"type": "prediction_result", "payload": {"clase_predicha": "INCENDIO"}}
API → ESP32: {"type": "command", "payload": {"actuator": "water_pump", "action": "ON"}}
ESP32 → API: {"type": "ack", "message_id": "command_received"}
```

### Flujo 3: Heartbeat

```
ESP32 → API: {"type": "heartbeat"}
API → ESP32: {"type": "heartbeat_ack"}
```

---

## Consideraciones de Seguridad

1. **Autenticación:** Implementar tokens de autenticación en el `client_id` o en headers.
2. **Encriptación:** Usar `wss://` (WebSocket Secure) en producción.
3. **Validación:** La API valida todos los datos de sensores antes de procesarlos.

---

## Librerías Recomendadas

**ESP32:**
- `WiFi.h`: Conexión WiFi
- `WebSocketsClient.h`: Cliente WebSocket
- `ArduinoJson.h`: Serialización/deserialización JSON

**Python (API):**
- `fastapi`: Framework web
- `websockets`: Soporte WebSocket (incluido en FastAPI)

---

## Configuración de Pines (Ejemplo)

```cpp
// Sensores
#define DHT_PIN 4        // DHT22 (temp/hum)
#define SOIL1_PIN 34     // Sensor humedad suelo 1
#define SOIL2_PIN 35     // Sensor humedad suelo 2
#define MQ2_PIN 32       // MQ-2
#define MQ5_PIN 33       // MQ-5
#define MQ8_PIN 25       // MQ-8

// Actuadores
#define FAN_PIN 26
#define PUMP_PIN 27
#define LED_PIN 14
```

---

## Próximos Pasos

1. Implementar autenticación con tokens.
2. Agregar persistencia de comandos pendientes.
3. Implementar modo BLE para control offline.
4. Crear dashboard en tiempo real en la app Flutter.
