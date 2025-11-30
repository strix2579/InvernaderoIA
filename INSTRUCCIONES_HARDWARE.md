# Guía de Integración de Hardware: ESP32 + Arduino MEGA

Esta guía detalla cómo conectar el módulo ESP32 (comunicación) con el Arduino MEGA (control y sensores) y cómo poner en marcha el sistema completo.

## 1. Conexiones Físicas

La comunicación entre el ESP32 y el Arduino MEGA se realiza mediante puerto Serial (UART).

### Diagrama de Conexión

| ESP32 (Pin) | Arduino MEGA (Pin) | Función | Nota Importante |
|-------------|--------------------|---------|-----------------|
| **GPIO 16 (RX2)** | **Pin 18 (TX1)** | ESP32 recibe datos del MEGA | *Recomendado usar divisor de voltaje (ver abajo)* |
| **GPIO 17 (TX2)** | **Pin 19 (RX1)** | ESP32 envía comandos al MEGA | Conexión directa OK |
| **GND** | **GND** | Tierra común | **OBLIGATORIO** para que funcione |
| **VIN / 5V** | **5V** | Alimentación | Solo si comparten fuente de poder |

### ⚠️ Protección de Niveles de Voltaje (Muy Recomendado)
El Arduino MEGA opera a **5V**, mientras que el ESP32 opera a **3.3V**. Conectar directamente el TX del MEGA (5V) al RX del ESP32 podría dañar el ESP32 a largo plazo.

**Circuito Divisor de Voltaje (MEGA TX -> ESP32 RX):**
1. Conecta **MEGA Pin 18 (TX1)** a una resistencia de **1kΩ**.
2. El otro extremo de la resistencia de 1kΩ va al **GPIO 16 (RX2)** del ESP32.
3. Desde el GPIO 16 del ESP32, conecta una resistencia de **2kΩ** a **GND**.

*Si no tienes resistencias, puedes conectar directo bajo tu propio riesgo, suele funcionar para pruebas cortas pero no se recomienda para uso continuo.*

---

## 2. Carga de Firmware

### Paso A: Arduino MEGA
1. Abre `firmware/arduino_mega_firmware.ino` en Arduino IDE.
2. Selecciona la placa **Arduino Mega or Mega 2560**.
3. Conecta el MEGA por USB.
4. Selecciona el puerto COM correspondiente.
5. Clic en **Subir**.

### Paso B: ESP32
1. Abre `firmware/esp32_config_firmware.ino` en Arduino IDE (o usa PlatformIO).
2. Si usas Arduino IDE, asegúrate de tener instaladas las librerías:
   - `ArduinoJson` (versión 6.x)
   - `WebSockets` (de Markus Sattler)
3. Selecciona tu placa ESP32 (ej. **DOIT ESP32 DEVKIT V1**).
4. Conecta el ESP32 por USB.
5. Clic en **Subir**.

---

## 3. Puesta en Marcha y Configuración

Una vez ambos dispositivos tengan el código cargado y estén conectados entre sí:

1. **Encendido:** Alimenta ambos dispositivos.
2. **Verificación Visual:**
   - El ESP32 debería crear una red WiFi llamada `GreenTech-XXXXXXXX`.
   - El MEGA debería estar leyendo sensores (puedes verificarlo en el Monitor Serial del MEGA a 115200 baudios).

3. **Configuración desde la App:**
   - Abre la aplicación Flutter (`flutter run -d chrome` o en tu móvil).
   - En el Dashboard, haz clic en el botón **"Add Device"** (icono + en la barra superior).
   - Sigue el asistente:
     1. Conéctate a la red WiFi `GreenTech-XXXX` con tu PC/Móvil (clave: `greenhouse123` o abierta según config).
     2. La app detectará el dispositivo.
     3. Selecciona tu red WiFi doméstica e introduce la contraseña.
     4. El ESP32 se reiniciará y se conectará a tu casa.

4. **Operación Normal:**
   - El ESP32 se conectará al Backend.
   - Comenzarás a ver datos reales de temperatura, humedad, etc. en el Dashboard.
   - Podrás controlar bombas y ventiladores desde la app.
