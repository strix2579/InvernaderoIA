# Sistema de Configuración WiFi ESP32 + Flutter

## 📋 Descripción General

Este sistema permite configurar dispositivos ESP32 de forma sencilla mediante una aplicación Flutter. El ESP32 crea un Access Point temporal donde la app se conecta para enviar las credenciales WiFi de la red doméstica.

## 🔧 Componentes del Sistema

### 1. Firmware ESP32 (`esp32_config_firmware.ino`)

#### Estados del Dispositivo

```cpp
enum DeviceState {
  STATE_AP_MODE,        // Modo Access Point (configuración)
  STATE_CONNECTING,     // Conectando a WiFi
  STATE_ONLINE,         // Conectado y operativo
  STATE_AP_FALLBACK     // Volver a AP por fallos
};
```

#### Flujo de Inicio

1. **Verificar NVS**: Busca credenciales WiFi guardadas
2. **Sin credenciales** → Modo AP
3. **Con credenciales** → Intentar conexión
4. **Conexión exitosa** → Modo Online
5. **Fallo (5 reintentos)** → Borrar credenciales y volver a AP

#### API HTTP en Modo AP

**Base URL**: `http://192.168.4.1`

##### GET `/status`
Retorna el estado actual del dispositivo.

**Respuesta (AP Mode)**:
```json
{
  "state": "ap_mode",
  "device_id": "A1B2C3D4",
  "mac": "AA:BB:CC:DD:EE:FF"
}
```

**Respuesta (Online)**:
```json
{
  "state": "online",
  "device_id": "A1B2C3D4",
  "mac": "AA:BB:CC:DD:EE:FF",
  "ip": "192.168.1.100",
  "ssid": "MiRedWiFi"
}
```

##### GET `/networks`
Escanea y retorna las redes WiFi disponibles.

**Respuesta**:
```json
{
  "networks": [
    {
      "ssid": "MiRedWiFi",
      "rssi": -45,
      "encryption": "encrypted"
    },
    {
      "ssid": "RedAbierta",
      "rssi": -67,
      "encryption": "open"
    }
  ]
}
```

##### POST `/configure`
Recibe y guarda la configuración WiFi.

**Request Body**:
```json
{
  "wifi_ssid": "MiRedWiFi",
  "wifi_password": "miContraseña123",
  "user_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." // Opcional
}
```

**Respuesta**:
```json
{
  "ok": true
}
```

**Comportamiento**: El ESP32 guarda en NVS y se reinicia en 2 segundos.

##### GET `/`
Interfaz web HTML para configuración manual (opcional).

#### Almacenamiento NVS

```cpp
Namespace: "greenhouse"
Keys:
  - wifi_ssid: String
  - wifi_pass: String
  - user_token: String
```

#### mDNS

Una vez conectado a WiFi, el dispositivo se anuncia como:
```
greentech-<device_id>.local
```

Ejemplo: `greentech-a1b2c3d4.local`

#### WebSocket (Modo Online)

Se conecta al backend en:
```
ws://<backend_ip>:8080/ws/device/<device_id>
```

Envía token de autenticación si existe.

---

### 2. Flutter App

#### Modelos (`lib/domain/entities/iot_device.dart`)

```dart
class IoTDevice {
  final String deviceId;
  final String mac;
  final String state;
  final String? ip;
  final String? ssid;
}

class WiFiNetwork {
  final String ssid;
  final int rssi;
  final String encryption;
}

class DeviceConfiguration {
  final String wifiSSID;
  final String wifiPassword;
  final String? userToken;
}
```

#### Servicio (`lib/data/services/device_config_service.dart`)

```dart
class DeviceConfigService {
  Future<IoTDevice> getDeviceStatus(String ip);
  Future<List<WiFiNetwork>> getAvailableNetworks(String ip);
  Future<bool> configureDevice(String ip, DeviceConfiguration config);
  Future<String?> discoverDeviceIP(String deviceId);
  Future<bool> isDeviceReachable(String ip);
}
```

#### Pantalla de Configuración (`lib/presentation/screens/device_setup_screen.dart`)

**Pasos del Wizard**:

1. **Connecting**: Conectando al AP del dispositivo
2. **Scanning Networks**: Escaneando redes WiFi
3. **Selecting Network**: Usuario selecciona red y contraseña
4. **Configuring**: Enviando configuración
5. **Success**: Configuración exitosa
6. **Error**: Manejo de errores

---

## 🚀 Flujo Completo de Configuración

### Paso 1: Preparación del Dispositivo

1. Usuario enciende el ESP32 por primera vez
2. ESP32 no tiene credenciales → Inicia modo AP
3. Crea red WiFi: `GreenTech-A1B2C3D4`
4. IP del AP: `192.168.4.1`

### Paso 2: Conexión desde Flutter

1. Usuario abre la app Flutter
2. Navega a "Agregar Dispositivo"
3. App muestra instrucciones:
   - "Conéctate a la red WiFi GreenTech-XXXX"
   - "Contraseña: greenhouse123"
4. Usuario conecta su teléfono/PC a esa red WiFi

### Paso 3: Detección del Dispositivo

```dart
final device = await configService.getDeviceStatus('192.168.4.1');
// device.deviceId = "A1B2C3D4"
// device.state = "ap_mode"
```

### Paso 4: Escaneo de Redes

```dart
final networks = await configService.getAvailableNetworks('192.168.4.1');
// Muestra lista de redes WiFi disponibles
```

### Paso 5: Selección y Configuración

1. Usuario selecciona su red WiFi doméstica
2. Ingresa contraseña
3. App envía configuración:

```dart
final config = DeviceConfiguration(
  wifiSSID: 'MiRedWiFi',
  wifiPassword: 'miContraseña123',
  userToken: authToken, // Si hay sesión activa
);

await configService.configureDevice('192.168.4.1', config);
```

### Paso 6: Reinicio y Conexión

1. ESP32 recibe configuración
2. Guarda en NVS
3. Se reinicia
4. Intenta conectar a `MiRedWiFi`
5. Si conecta exitosamente:
   - Obtiene IP de la red doméstica (ej: `192.168.1.100`)
   - Inicia mDNS: `greentech-a1b2c3d4.local`
   - Conecta a WebSocket del backend

### Paso 7: Descubrimiento en Red Local

Flutter puede encontrar el dispositivo de 3 formas:

#### Opción A: mDNS (Recomendado)
```dart
// Requiere paquete multicast_dns
final ip = await configService.discoverDeviceIP('A1B2C3D4');
// Busca greentech-a1b2c3d4.local
```

#### Opción B: Escaneo de Red
```dart
final ip = await configService.scanLocalNetwork('192.168.1.1', 'A1B2C3D4');
// Escanea 192.168.1.1-254 buscando el device_id
```

#### Opción C: Registro en Backend
El ESP32 envía su IP al backend cuando se conecta:
```json
{
  "type": "DEVICE_INFO",
  "device_id": "A1B2C3D4",
  "ip": "192.168.1.100"
}
```

Flutter consulta al backend:
```dart
GET /api/devices/A1B2C3D4/ip
```

---

## 🔒 Seguridad

### Recomendaciones Implementadas

1. **Token de Usuario**: Se envía al dispositivo para vincularlo a una cuenta
2. **HTTPS**: Usar certificados SSL en producción (requiere configuración adicional)
3. **Timeout de AP**: El AP se puede configurar para cerrarse después de X minutos
4. **Validación de Credenciales**: El ESP32 valida que el SSID no esté vacío

### Mejoras Futuras

- Cifrado de contraseñas en tránsito
- Autenticación del dispositivo con certificados
- OTA (Over-The-Air) updates
- Whitelist de dispositivos por MAC

---

## 📦 Dependencias

### ESP32 (PlatformIO/Arduino)

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino

lib_deps =
    bblanchon/ArduinoJson@^6.21.0
    links2004/WebSockets@^2.4.0
    ESP32 WebServer (built-in)
    Preferences (built-in)
    ESPmDNS (built-in)
```

### Flutter

```yaml
dependencies:
  http: ^1.1.0
  # Para mDNS (opcional):
  # multicast_dns: ^0.3.2
```

---

## 🧪 Testing

### Probar el ESP32

1. **Cargar firmware**:
   ```bash
   pio run -t upload
   ```

2. **Abrir monitor serial**:
   ```bash
   pio device monitor
   ```

3. **Conectar a AP**:
   - Red: `GreenTech-XXXX`
   - IP: `192.168.4.1`

4. **Probar endpoints**:
   ```bash
   curl http://192.168.4.1/status
   curl http://192.168.4.1/networks
   ```

5. **Configurar**:
   ```bash
   curl -X POST http://192.168.4.1/configure \
     -H "Content-Type: application/json" \
     -d '{"wifi_ssid":"MiRed","wifi_password":"pass123"}'
   ```

### Probar Flutter App

1. **Ejecutar app**:
   ```bash
   flutter run
   ```

2. **Conectar teléfono a AP del ESP32**

3. **Navegar a pantalla de configuración**:
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => DeviceSetupScreen(),
     ),
   );
   ```

---

## 🐛 Troubleshooting

### El ESP32 no crea el AP

- Verificar que no haya credenciales guardadas
- Borrar NVS: `preferences.clear()`
- Reiniciar el dispositivo

### Flutter no se conecta al dispositivo

- Verificar que el teléfono esté conectado al AP
- Verificar IP: debe ser `192.168.4.1`
- Verificar firewall/permisos de red

### El ESP32 no se conecta al WiFi

- Verificar credenciales
- Verificar señal WiFi
- Revisar logs en monitor serial
- Verificar que el router no tenga filtrado MAC

### No se encuentra el dispositivo después de configurar

- Esperar 10-15 segundos después del reinicio
- Verificar que el dispositivo esté en la misma red
- Usar escaneo de red si mDNS no funciona
- Verificar logs del backend

---

## 📝 Notas Adicionales

### Personalización del AP

Modificar en el firmware:

```cpp
#define AP_SSID_PREFIX "MiEmpresa-"
#define AP_PASSWORD "miPassword123"
```

### Cambiar IP del AP

```cpp
#define AP_IP IPAddress(192, 168, 10, 1)
```

### Configurar Backend

En `connectToBackend()`:

```cpp
const char* ws_server = "api.miempresa.com";
const int ws_port = 443;  // HTTPS
```

### Logs y Debug

Habilitar logs detallados:

```cpp
#define DEBUG_MODE 1

#if DEBUG_MODE
  Serial.println("Debug: " + mensaje);
#endif
```

---

## 🎯 Próximos Pasos

1. ✅ Implementar firmware ESP32
2. ✅ Implementar servicio Flutter
3. ✅ Implementar pantalla de configuración
4. ⏳ Agregar mDNS discovery
5. ⏳ Implementar registro en backend
6. ⏳ Agregar OTA updates
7. ⏳ Implementar cifrado SSL/TLS

---

## 📚 Referencias

- [ESP32 WiFi Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/network/esp_wifi.html)
- [Preferences Library](https://github.com/espressif/arduino-esp32/tree/master/libraries/Preferences)
- [mDNS Protocol](https://www.rfc-editor.org/rfc/rfc6762)
- [Flutter HTTP Package](https://pub.dev/packages/http)

---

**Versión**: 1.0.0  
**Última actualización**: 2025-11-27  
**Autor**: GreenTech IoT Team
