# Ejemplos de Payloads JSON - Protocolo WebSocket IoT

Este documento contiene ejemplos completos de todos los tipos de mensajes del protocolo WebSocket.

---

## 1. Heartbeat

### ESP32 → API
```json
{
  "type": "heartbeat"
}
```

### API → ESP32
```json
{
  "type": "heartbeat_ack"
}
```

---

## 2. Sensor Update - Condiciones Normales

### ESP32 → API
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

### API → ESP32
```json
{
  "type": "prediction_result",
  "payload": {
    "predicciones": {
      "NORMAL": 0.92,
      "INCENDIO": 0.02,
      "FUGA_H2": 0.02,
      "FALLA_ELECTRICA": 0.02,
      "PLAGA": 0.02
    },
    "clase_predicha": "NORMAL"
  }
}
```

---

## 3. Sensor Update - Detección de Incendio

### ESP32 → API
```json
{
  "type": "sensor_update",
  "payload": {
    "temp": 45.0,
    "hum": 30.0,
    "soil1": 40.0,
    "soil2": 40.0,
    "mq2": 800.0,
    "mq5": 700.0,
    "mq8": 600.0,
    "aqi": 350.0
  }
}
```

### API → ESP32 (Predicción)
```json
{
  "type": "prediction_result",
  "payload": {
    "predicciones": {
      "NORMAL": 0.05,
      "INCENDIO": 0.85,
      "FUGA_H2": 0.03,
      "FALLA_ELECTRICA": 0.04,
      "PLAGA": 0.03
    },
    "clase_predicha": "INCENDIO"
  }
}
```

### API → ESP32 (Comando Automático)
```json
{
  "type": "command",
  "payload": {
    "actuator": "water_pump",
    "action": "ON",
    "duration": 10
  }
}
```

### ESP32 → API (ACK)
```json
{
  "type": "ack",
  "message_id": "command_received",
  "status": "success"
}
```

---

## 4. Sensor Update - Detección de Plaga

### ESP32 → API
```json
{
  "type": "sensor_update",
  "payload": {
    "temp": 28.0,
    "hum": 80.0,
    "soil1": 85.0,
    "soil2": 85.0,
    "mq2": 150.0,
    "mq5": 140.0,
    "mq8": 145.0,
    "aqi": 120.0
  }
}
```

### API → ESP32 (Comando Automático)
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

---

## 5. Comando Manual desde App

### API → ESP32
```json
{
  "type": "command",
  "payload": {
    "actuator": "led",
    "action": "ON"
  }
}
```

### ESP32 → API
```json
{
  "type": "ack",
  "message_id": "command_received",
  "status": "success"
}
```

---

## 6. Actualización de Configuración

### API → ESP32
```json
{
  "type": "config_update",
  "payload": {
    "sensor_interval": 10000,
    "heartbeat_interval": 30000,
    "auto_mode": true
  }
}
```

### ESP32 → API
```json
{
  "type": "ack",
  "message_id": "config_updated",
  "status": "success"
}
```

---

## 7. Error en Comando

### ESP32 → API
```json
{
  "type": "ack",
  "message_id": "command_received",
  "status": "error",
  "error_message": "Actuator 'water_pump' is offline"
}
```

---

## 8. Sensor Update - Fuga de Hidrógeno

### ESP32 → API
```json
{
  "type": "sensor_update",
  "payload": {
    "temp": 26.0,
    "hum": 55.0,
    "soil1": 68.0,
    "soil2": 70.0,
    "mq2": 200.0,
    "mq5": 180.0,
    "mq8": 900.0,
    "aqi": 280.0
  }
}
```

### API → ESP32
```json
{
  "type": "prediction_result",
  "payload": {
    "predicciones": {
      "NORMAL": 0.05,
      "INCENDIO": 0.10,
      "FUGA_H2": 0.75,
      "FALLA_ELECTRICA": 0.05,
      "PLAGA": 0.05
    },
    "clase_predicha": "FUGA_H2"
  }
}
```

---

## 9. Múltiples Comandos Secuenciales

### API → ESP32 (Comando 1)
```json
{
  "type": "command",
  "payload": {
    "actuator": "fan",
    "action": "ON",
    "duration": 30
  }
}
```

### API → ESP32 (Comando 2)
```json
{
  "type": "command",
  "payload": {
    "actuator": "led",
    "action": "ON",
    "duration": 60
  }
}
```

### ESP32 → API (ACK 1)
```json
{
  "type": "ack",
  "message_id": "command_1_received",
  "status": "success"
}
```

### ESP32 → API (ACK 2)
```json
{
  "type": "ack",
  "message_id": "command_2_received",
  "status": "success"
}
```

---

## 10. Estado de Actuadores (Opcional)

### ESP32 → API
```json
{
  "type": "actuator_status",
  "payload": {
    "fan": "ON",
    "water_pump": "OFF",
    "led": "ON",
    "heater": "OFF"
  }
}
```

---

## Notas de Implementación

1. **Timestamps**: Puedes agregar un campo `timestamp` a cada mensaje para registro:
   ```json
   {
     "type": "sensor_update",
     "timestamp": "2025-11-25T10:30:00Z",
     "payload": {...}
   }
   ```

2. **Message IDs**: Para tracking de mensajes:
   ```json
   {
     "type": "command",
     "message_id": "cmd_12345",
     "payload": {...}
   }
   ```

3. **Prioridad**: Para comandos urgentes:
   ```json
   {
     "type": "command",
     "priority": "high",
     "payload": {...}
   }
   ```
