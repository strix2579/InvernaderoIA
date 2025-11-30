# 🚀 GUÍA DE DESPLIEGUE COMPLETO - SISTEMA INVERNADERO IoT

## 📋 ÍNDICE
1. [Arquitectura del Sistema](#arquitectura)
2. [Configuración del Backend (API Python)](#backend)
3. [Configuración del Hardware (Arduino MEGA + ESP32)](#hardware)
4. [Instalación de la App en Celular](#app-celular)
5. [Despliegue de la App en Web](#app-web)
6. [Pruebas Finales](#pruebas)

---

## 🏗️ ARQUITECTURA DEL SISTEMA {#arquitectura}

```
┌─────────────────┐
│  Arduino MEGA   │ ← Sensores (DHT22, MQ, Soil, Water)
│  (Firmware)     │ ← Actuadores (Bombas, Ventiladores, LEDs)
└────────┬────────┘
         │ Serial (TX1/RX1, 9600 baud)
         ▼
┌─────────────────┐
│     ESP32       │ ← WiFi
│  (Firmware)     │ ← WebSocket
└────────┬────────┘
         │ WebSocket (ws://IP:8080/ws/connect)
         ▼
┌─────────────────┐
│  Backend API    │ ← FastAPI + Python
│  (main.py)      │ ← Puerto 8080
└────────┬────────┘
         │ HTTP/WebSocket
         ▼
┌─────────────────┐
│  App Flutter    │ ← Android/iOS/Web
│  (Celular/Web)  │
└─────────────────┘
```

---

## 🐍 PASO 1: CONFIGURACIÓN DEL BACKEND (API PYTHON) {#backend}

### 1.1 Verificar Python y Dependencias

```bash
# Abrir PowerShell en: c:\Users\emmae\Desktop\InvernaderoIA

# Activar entorno virtual
.\venv\Scripts\Activate

# Verificar instalación
python --version
pip list
```

### 1.2 Configurar IP del Servidor

**IMPORTANTE:** Necesitas saber la IP de tu PC en la red local.

```bash
# En PowerShell, ejecuta:
ipconfig
```

Busca la línea que dice `IPv4 Address` en tu adaptador WiFi/Ethernet. Ejemplo:
```
IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

**Anota esta IP**, la necesitarás para configurar el ESP32.

### 1.3 Iniciar el Backend

```bash
# En PowerShell (con venv activado):
cd c:\Users\emmae\Desktop\InvernaderoIA
uvicorn api.main:app --host 0.0.0.0 --port 8080 --reload
```

Deberías ver:
```
INFO:     Uvicorn running on http://0.0.0.0:8080 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

**✅ El backend está corriendo en: `http://TU_IP:8080`**

### 1.4 Verificar que el Backend Funciona

Abre un navegador y ve a:
```
http://localhost:8080/docs
```

Deberías ver la documentación interactiva de la API (Swagger UI).

---

## 🔌 PASO 2: CONFIGURACIÓN DEL HARDWARE {#hardware}

### 2.1 Conexiones Físicas

#### Arduino MEGA ↔ ESP32 (Comunicación Serial)
- **MEGA TX1 (pin 18)** → **ESP32 RX2 (GPIO 16)**
- **MEGA RX1 (pin 19)** → **ESP32 TX2 (GPIO 17)**
- **MEGA GND** → **ESP32 GND**

#### Sensores en Arduino MEGA
- **DHT22 (4 sensores):** Pines 22, 23, 24, 25
- **MQ2:** A8
- **MQ5:** A9
- **MQ8:** A10
- **Soil 1:** A12
- **Soil 2:** A13
- **Water 1:** A11
- **Water 2:** A14

#### Actuadores en Arduino MEGA
- **Bombas:** 26, 27
- **Ventiladores:** 28, 29, 30
- **Extractores:** 31, 32, 33
- **LED UVA:** 35
- **Buzzer:** 41
- **Sensor Puerta:** 34

#### RFID en Arduino MEGA
- **SDA:** 53
- **SCK:** 52
- **MOSI:** 51
- **MISO:** 50
- **RST:** 52

### 2.2 Subir Firmware al Arduino MEGA

1. Abre Arduino IDE
2. Abre: `c:\Users\emmae\Desktop\InvernaderoIA\firmware\arduino_mega_firmware.ino`
3. Selecciona:
   - **Placa:** Arduino Mega or Mega 2560
   - **Puerto:** El puerto COM del MEGA
4. **Subir** (Ctrl+U)
5. Abre el Monitor Serial (115200 baud)
6. Deberías ver:
   ```
   Temp Prom:XX.XXC Hum Prom:XX.XX% W1:XX% W2:XX%
   ```

### 2.3 Subir Firmware al ESP32

1. Abre Arduino IDE
2. Abre: `c:\Users\emmae\Desktop\InvernaderoIA\firmware\esp32_config_firmware.ino`
3. Selecciona:
   - **Placa:** ESP32 Dev Module
   - **Puerto:** El puerto COM del ESP32
4. **ANTES DE SUBIR:** Actualiza la IP del backend en el código:

```cpp
// Línea ~471 en esp32_config_firmware.ino
const char *ws_server = "192.168.1.100"; // ← CAMBIA ESTO POR TU IP
const int ws_port = 8080;
```

5. **Subir** (Ctrl+U)
6. Abre el Monitor Serial (115200 baud)
7. Deberías ver:
   ```
   =================================
     ESP32 GreenTech IoT Firmware
   =================================
   
   Device ID: XXXXXXXX
   AP SSID: GreenTech-XXXXXXXX
   ```

### 2.4 Configurar WiFi del ESP32

**Desde tu Celular:**

1. Conéctate a la red WiFi: `GreenTech-XXXXXXXX`
2. Contraseña: `greenhouse123`
3. Abre el navegador y ve a: `http://192.168.4.1`
4. Selecciona tu red WiFi
5. Ingresa la contraseña de tu WiFi
6. Presiona "Configurar"
7. El ESP32 se reiniciará

**Verifica en el Monitor Serial del ESP32:**
```
¡WiFi conectado!
  IP: 192.168.1.XXX
Conectando a WebSocket backend...
[WS] Conectado a: ws://192.168.1.100:8080/ws/connect
[MEGA] TEMP:25.30;HUM:60.5;...
[PARSED] T:25.3 H:60.5 W1:45 W2:50 AQI:120
```

---

## 📱 PASO 3: INSTALACIÓN DE LA APP EN CELULAR {#app-celular}

### 3.1 Preparar el Proyecto Flutter

```bash
# En PowerShell:
cd c:\Users\emmae\Desktop\InvernaderoIA\app_invernadero

# Obtener dependencias
flutter pub get

# Verificar dispositivos conectados
flutter devices
```

### 3.2 Configurar la IP del Backend en la App

Edita: `app_invernadero\lib\services\api_service.dart`

```dart
// Busca esta línea (aproximadamente línea 10-15):
static const String baseUrl = 'http://192.168.1.100:8080'; // ← CAMBIA POR TU IP
```

### 3.3 Opción A: Instalar Directamente en Celular Android (Desarrollo)

**Requisitos:**
- Celular Android con modo desarrollador activado
- USB Debugging habilitado
- Cable USB conectado a la PC

```bash
# Verificar que el celular está conectado:
flutter devices

# Deberías ver algo como:
# Android SDK built for x86 (mobile) • emulator-5554 • android-x86 • Android 11 (API 30)
# SM G960F (mobile) • XXXXXXXXXX • android-arm64 • Android 10 (API 29)

# Instalar en el celular:
flutter run --release
```

La app se instalará y abrirá automáticamente en tu celular.

### 3.4 Opción B: Generar APK para Instalar Manualmente

```bash
# Generar APK:
flutter build apk --release

# El APK estará en:
# app_invernadero\build\app\outputs\flutter-apk\app-release.apk
```

**Para instalar el APK en tu celular:**

1. Copia el archivo `app-release.apk` a tu celular (por USB, email, Drive, etc.)
2. En el celular, abre el archivo APK
3. Permite "Instalar desde fuentes desconocidas" si te lo pide
4. Instala la app

---

## 🌐 PASO 4: DESPLIEGUE DE LA APP EN WEB {#app-web}

### 4.1 Compilar la App para Web

```bash
cd c:\Users\emmae\Desktop\InvernaderoIA\app_invernadero

# Compilar para web:
flutter build web --release
```

Los archivos compilados estarán en: `app_invernadero\build\web\`

### 4.2 Opción A: Probar Localmente

```bash
# Instalar servidor HTTP simple:
pip install http.server

# Servir la app web:
cd build\web
python -m http.server 8000
```

Abre el navegador en: `http://localhost:8000`

### 4.3 Opción B: Desplegar en GitHub Pages (GRATIS)

1. **Crear repositorio en GitHub:**
   - Ve a https://github.com/new
   - Nombre: `invernadero-app`
   - Público o Privado
   - Crear repositorio

2. **Subir el código:**

```bash
cd c:\Users\emmae\Desktop\InvernaderoIA\app_invernadero

# Inicializar git (si no está inicializado):
git init
git add .
git commit -m "Initial commit"

# Conectar con GitHub:
git remote add origin https://github.com/TU_USUARIO/invernadero-app.git
git branch -M main
git push -u origin main
```

3. **Configurar GitHub Pages:**
   - Ve a tu repositorio en GitHub
   - Settings → Pages
   - Source: Deploy from a branch
   - Branch: `main` → Folder: `/build/web`
   - Save

4. **Tu app estará disponible en:**
   ```
   https://TU_USUARIO.github.io/invernadero-app/
   ```

### 4.4 Opción C: Desplegar en Netlify (GRATIS, MÁS FÁCIL)

1. **Crear cuenta en Netlify:**
   - Ve a https://www.netlify.com/
   - Sign up (gratis)

2. **Desplegar:**
   - Arrastra la carpeta `app_invernadero\build\web` a Netlify
   - O conecta tu repositorio de GitHub

3. **Tu app estará disponible en:**
   ```
   https://TU_SITIO.netlify.app
   ```

---

## ✅ PASO 5: PRUEBAS FINALES {#pruebas}

### 5.1 Verificar Flujo Completo

1. **Backend corriendo:**
   ```
   ✅ http://TU_IP:8080/docs muestra la API
   ```

2. **Hardware conectado:**
   ```
   ✅ Monitor Serial MEGA: Muestra lecturas de sensores
   ✅ Monitor Serial ESP32: Muestra [MEGA] y [PARSED]
   ✅ Monitor Serial ESP32: Muestra [WS] Conectado
   ```

3. **App funcionando:**
   ```
   ✅ Abre la app (celular o web)
   ✅ Login con usuario de prueba
   ✅ Dashboard muestra datos en tiempo real
   ✅ Controles de actuadores funcionan
   ```

### 5.2 Crear Usuario de Prueba

**Opción 1: Desde la API (Swagger UI)**

1. Ve a: `http://TU_IP:8080/docs`
2. POST `/auth/register`
3. Try it out
4. Body:
   ```json
   {
     "username": "admin",
     "email": "admin@invernadero.com",
     "password": "admin123"
   }
   ```
5. Execute

**Opción 2: Desde la App**

1. Abre la app
2. Presiona "Registrarse"
3. Completa el formulario
4. Inicia sesión

### 5.3 Probar Funcionalidades

- [ ] Ver datos de sensores en tiempo real
- [ ] Controlar bombas ON/OFF
- [ ] Controlar ventiladores ON/OFF
- [ ] Controlar extractores ON/OFF
- [ ] Controlar LED UVA ON/OFF
- [ ] Ver historial de datos
- [ ] Recibir notificaciones de alarma

---

## 🆘 SOLUCIÓN DE PROBLEMAS COMUNES

### Backend no inicia
```bash
# Verificar que el puerto 8080 no esté en uso:
netstat -ano | findstr :8080

# Si está en uso, matar el proceso o cambiar el puerto
```

### ESP32 no se conecta al WiFi
- Verifica que la contraseña sea correcta
- Verifica que la red sea 2.4GHz (ESP32 no soporta 5GHz)
- Presiona el botón RESET del ESP32

### ESP32 no se conecta al Backend
- Verifica que la IP en el código sea correcta
- Verifica que el backend esté corriendo
- Verifica que estén en la misma red

### App no se conecta
- Verifica que la IP en `api_service.dart` sea correcta
- Verifica que el backend esté corriendo
- Verifica que el celular esté en la misma red WiFi

---

## 📞 RESUMEN DE IPs Y PUERTOS

```
Backend API:     http://TU_IP:8080
WebSocket:       ws://TU_IP:8080/ws/connect
ESP32 AP:        http://192.168.4.1
App Web Local:   http://localhost:8000
```

---

## 🎉 ¡LISTO!

Ahora tienes todo el sistema funcionando:
- ✅ Hardware leyendo sensores
- ✅ ESP32 enviando datos al backend
- ✅ Backend procesando y almacenando datos
- ✅ App mostrando datos en tiempo real
- ✅ Control de actuadores desde la app

**¡Tu invernadero inteligente está completo!** 🌱🤖
