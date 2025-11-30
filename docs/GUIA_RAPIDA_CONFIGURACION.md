# 🚀 Guía Rápida: Configuración de Dispositivos ESP32

## Para el Usuario Final

### 1. Preparar el Dispositivo

1. Conecta el ESP32 a la corriente
2. Espera 10 segundos
3. El LED debería parpadear indicando modo configuración

### 2. Conectar desde la App

1. Abre la app **GreenTech**
2. Ve a **Configuración** → **Agregar Dispositivo**
3. Sigue las instrucciones en pantalla:
   - Conecta tu teléfono a la red WiFi `GreenTech-XXXX`
   - Contraseña: `greenhouse123`
4. Espera a que la app detecte el dispositivo

### 3. Configurar WiFi

1. Selecciona tu red WiFi de la lista
2. Ingresa la contraseña
3. Toca **Configurar Dispositivo**
4. Espera 30 segundos

### 4. Verificar Conexión

1. El dispositivo se reiniciará automáticamente
2. Vuelve a conectar tu teléfono a tu WiFi normal
3. La app mostrará el dispositivo como **Conectado**

---

## Para Desarrolladores

### Setup Rápido

#### ESP32

```bash
# 1. Instalar PlatformIO
pip install platformio

# 2. Compilar firmware
cd firmware
pio run

# 3. Subir al ESP32
pio run -t upload

# 4. Ver logs
pio device monitor
```

#### Flutter

```bash
# 1. Instalar dependencias
cd app_invernadero
flutter pub get

# 2. Ejecutar app
flutter run

# 3. Para testing
flutter test
```

### Probar Configuración Manual

```bash
# 1. Conectar a AP del ESP32
# Red: GreenTech-XXXX

# 2. Verificar estado
curl http://192.168.4.1/status

# 3. Ver redes disponibles
curl http://192.168.4.1/networks

# 4. Configurar
curl -X POST http://192.168.4.1/configure \
  -H "Content-Type: application/json" \
  -d '{
    "wifi_ssid": "MiRedWiFi",
    "wifi_password": "miPassword123",
    "user_token": "optional_token"
  }'
```

### Resetear Dispositivo

```cpp
// Método 1: Desde código
preferences.begin("greenhouse", false);
preferences.clear();
preferences.end();
ESP.restart();

// Método 2: Botón físico (si está implementado)
// Mantener presionado 5 segundos
```

### Debug

```bash
# Ver logs en tiempo real
pio device monitor --baud 115200

# Logs comunes:
# "=== INICIANDO MODO ACCESS POINT ===" → Modo AP activo
# "WiFi connected" → Conectado exitosamente
# "Timeout conectando a WiFi" → Credenciales incorrectas
```

---

## Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| No veo la red GreenTech-XXXX | Reinicia el ESP32, espera 15 segundos |
| App no detecta dispositivo | Verifica que estés conectado al AP (192.168.4.1) |
| Configuración falla | Verifica contraseña WiFi, señal fuerte |
| Dispositivo no aparece después | Espera 30s, verifica que esté en la misma red |
| "Error de conexión" | Reinicia app y dispositivo |

---

## Arquitectura Simplificada

```
┌─────────────┐
│   ESP32     │
│  (Sin WiFi) │
└──────┬──────┘
       │
       │ Crea AP
       ▼
┌─────────────────┐
│  GreenTech-XXXX │ ◄─── Usuario conecta teléfono
│  192.168.4.1    │
└────────┬────────┘
         │
         │ Flutter envía config
         ▼
┌─────────────┐
│   ESP32     │
│ Guarda NVS  │
│  Reinicia   │
└──────┬──────┘
       │
       │ Conecta a WiFi
       ▼
┌─────────────────┐
│  Red Doméstica  │
│  192.168.1.100  │ ◄─── Flutter descubre
└─────────────────┘
       │
       │ WebSocket
       ▼
┌─────────────┐
│   Backend   │
│  API Server │
└─────────────┘
```

---

## Checklist de Implementación

### ESP32
- [x] Modo Access Point
- [x] HTTP Server
- [x] Endpoints /status, /networks, /configure
- [x] Almacenamiento NVS
- [x] Reconexión automática
- [x] Fallback a AP
- [x] mDNS
- [x] WebSocket client
- [ ] OTA updates
- [ ] SSL/TLS

### Flutter
- [x] Modelos de datos
- [x] Servicio de configuración
- [x] Pantalla de setup
- [x] Wizard paso a paso
- [x] Manejo de errores
- [ ] mDNS discovery
- [ ] Escaneo de red local
- [ ] Integración con backend
- [ ] Persistencia de dispositivos

### Backend
- [ ] Endpoint de registro de dispositivos
- [ ] WebSocket para dispositivos
- [ ] Base de datos de dispositivos
- [ ] Vinculación usuario-dispositivo
- [ ] API de descubrimiento

---

## Próximas Mejoras

1. **Bluetooth LE**: Configuración sin WiFi
2. **QR Code**: Escanear código del dispositivo
3. **Provisioning**: Múltiples dispositivos a la vez
4. **Cloud Backup**: Respaldo de configuraciones
5. **Geolocalización**: Detectar dispositivos cercanos

---

## Contacto y Soporte

- **Documentación completa**: `docs/CONFIGURACION_DISPOSITIVOS.md`
- **Issues**: GitHub Issues
- **Email**: support@greentech.io

---

**Happy Coding! 🌱**
