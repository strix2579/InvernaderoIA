# InvernaderoIA — Greentech
## Solución de Problemas y Demostración

---

## 8. SOLUCIÓN DE PROBLEMAS FRECUENTES

### 8.1 Diagnóstico de Lecturas Absurdas

#### Problema 1: DHT22 muestra temperatura -999°C o NaN

| Causa Probable | Verificación | Solución |
|----------------|--------------|----------|
| Cable DATA desconectado | Multímetro continuidad pin-sensor | Reconectar, soldar si necesario |
| Falta resistor pull-up 10kΩ | Medir resistencia DATA-VCC | Soldar resistor 10kΩ |
| Sensor dañado por voltaje | Verificar VCC: debe ser ≤5.5V | Reemplazar sensor |
| Pin Arduino dañado | Probar sensor en otro pin digital | Usar pin alternativo, actualizar código |
| Interferencia electromagnética | Alejar de motores/relés, cable <30cm | Cable apantallado, ferrita |

**Prueba diagnóstica:**
```cpp
// Código de prueba simple
#include <DHT.h>
DHT dht(22, DHT22);

void setup() {
  Serial.begin(115200);
  dht.begin();
}

void loop() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  Serial.print("T:"); Serial.print(t);
  Serial.print(" H:"); Serial.println(h);
  delay(2000);
}
// Esperado: T:20-30 H:40-80 (ambiente normal)
// Error: T:nan H:nan → verificar lista arriba
```

#### Problema 2: Humedad de Suelo siempre 0% o siempre 100%

**Síntoma:** Lectura no cambia al insertar/sacar sensor del suelo

| Causa | Diagnóstico | Solución |
|-------|-------------|----------|
| Calibración invertida | Verificar código: `map(crudo, seco, mojado, 0, 100)` | Invertir valores: `map(crudo, mojado, seco, 0, 100)` para sensor capacitivo |
| Sensor desconectado | Leer pin analógico directo: `analogRead(A0)` | Reconectar VCC/GND |
| Corrosión sensor | Inspección visual: óxido verde en electrodos | Limpiar isopropanol, reemplazar si muy dañado |
| Pin analógico dañado | Probar en A5, A6 alternativos | Cambiar pin, actualizar código |

**Procedimiento de calibración:**
```cpp
// 1. Sensor en aire (seco)
int valorSeco = analogRead(A0);
Serial.print("Valor seco: "); Serial.println(valorSeco);
// Típico: 600-800 (capacitivo), 1020 (resistivo)

// 2. Sensor en vaso con agua (mojado)
int valorMojado = analogRead(A0);
Serial.print("Valor mojado: "); Serial.println(valorMojado);
// Típico: 200-400 (capacitivo), 300-500 (resistivo)

// 3. Actualizar en configuración:
config.sueloSeco = valorSeco;    // Ej: 700
config.sueloMojado = valorMojado; // Ej: 300
```

#### Problema 3: Sensor MQ muestra valores erráticos (200 → 5000 → 300 PPM en segundos)

| Causa | Verificación | Solución |
|-------|--------------|----------|
| Precalentamiento insuficiente | Tiempo encendido < 24h | Esperar 24-48h para estabilizar |
| Alimentación inestable | Medir 5V con osciloscopio: debe ser estable | Capacitor 100µF en VCC-GND sensor, fuente dedicada |
| Sensor cerca de fuente calor | Temperatura >50°C | Alejar de lámparas, sol directo, motores |
| Constantes R0 incorrectas | Calibración fábrica vs realidad | Recalibrar R0 en aire limpio 24h |
| Humedad condensación | Gotas agua en sensor | Secar, instalar en zona ventilada |

**Código de calibración R0 (MQ-2):**
```cpp
// En ambiente limpio (exterior, 24h)
float RL = 10000; // 10kΩ típico en placa MQ
int suma = 0;
for (int i = 0; i < 100; i++) {
  int valor = analogRead(A2);
  suma += valor;
  delay(100);
}
int valorPromedio = suma / 100;
float voltaje = valorPromedio * (5.0 / 1023.0);
float RS = ((5.0 * RL) / voltaje) - RL;
float R0 = RS / 9.8; // Factor aire limpio según datasheet
Serial.print("R0 calibrado: "); Serial.println(R0);
// Guardar en EEPROM para usar en lecturas
```

#### Problema 4: RFID no lee tarjetas o lee UID erróneos

| Causa | Diagnóstico | Solución |
|-------|-------------|----------|
| Voltaje >3.3V dañó módulo | Medir VCC MFRC522: debe ser 3.3V ±0.1V | Reemplazar módulo, agregar divisor resistivo |
| Conexión SPI incorrecta | Verificar tabla pines sección 3.5 | Corregir cables, medir continuidad |
| Distancia tarjeta > 3cm | Acercar tarjeta a <2cm del lector | Instructivo usuario |
| Tarjetas no compatibles | Verificar frecuencia: debe ser 13.56MHz | Usar tarjetas Mifare Classic/NTAG |
| Interferencia RF | Alejar de WiFi, BLE, motores | Cable apantallado, ferrita, distancia >30cm |

**Código de prueba RFID:**
```cpp
#include <MFRC522.h>
MFRC522 rfid(53, 49); // SS, RST

void setup() {
  Serial.begin(115200);
  SPI.begin();
  rfid.PCD_Init();
  Serial.println("Acerque tarjeta...");
}

void loop() {
  if (!rfid.PICC_IsNewCardPresent()) return;
  if (!rfid.PICC_ReadCardSerial()) return;
  
  Serial.print("UID:");
  for (byte i = 0; i < rfid.uid.size; i++) {
    Serial.print(rfid.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(rfid.uid.uidByte[i], HEX);
  }
  Serial.println();
  rfid.PICC_HaltA();
  delay(1000);
}
// Esperado: UID: A3 B2 C1 D4 (ejemplo)
// Error: nada → verificar SPI, voltaje
```

### 8.2 Problemas con Actuadores (Relés)

#### Problema 5: Relé hace "clic" pero actuador no funciona

| Síntoma | Causa | Solución |
|---------|-------|----------|
| Relé suena, LED enciende, pero bomba no arranca | Carga no conectada en NO | Verificar COM-NO, medir voltaje en terminales actuador |
| Voltaje 0V en terminales actuador | Fusible fundido línea 12V | Reemplazar fusible, investigar cortocircuito |
| Voltaje 12V presente pero motor no gira | Motor bloqueado/quemado | Probar motor directo a fuente, liberar rodete, reemplazar |
| Relé suena al activar Y al desactivar | Rebote mecánico normal | OK si actuador responde, agregar delay 50ms anti-rebote código |

#### Problema 6: Relé NO hace "clic", LED relé no enciende

| Causa | Diagnóstico | Solución |
|-------|-------------|----------|
| Pin Arduino no cambia estado | Medir con multímetro pin 30-37: debe ir HIGH→LOW | Verificar código, GPIO no dañado |
| Cable IN roto | Continuidad Arduino pin - INx módulo | Reemplazar jumper |
| Módulo relé sin alimentación | Medir VCC-GND módulo: debe ser 5V | Conectar VCC a 5V Arduino |
| Relé soldado abierto (stuck open) | Probar relé manual (cortocircuitar IN-GND) | Reemplazar canal relé |

**Prueba manual relé:**
```cpp
// Código simple prueba relé
void setup() {
  pinMode(30, OUTPUT); // Canal 1
}

void loop() {
  digitalWrite(30, LOW);  // Activar
  delay(2000);
  digitalWrite(30, HIGH); // Desactivar
  delay(2000);
}
// Esperado: clic cada 2s, LED parpadea, actuador ON/OFF
```

#### Problema 7: Pin Arduino da solo 2V en vez de 5V

| Causa | Diagnóstico | Solución |
|-------|-------------|----------|
| Pin dañado (cortocircuito previo) | Medir en vacío (sin carga): debe ser 5V | Usar pin alternativo |
| Sobrecarga pin (>40mA) | Sumar corriente todos dispositivos en 5V | Redistribuir carga, usar fuente externa |
| Regulador 5V Arduino dañado | Medir pin 5V Arduino: debe ser 5V±0.25V | Alimentar sensores con fuente externa 5V regulada |
| Cable con resistencia alta | Medir caída de voltaje en cable | Cable más grueso (AWG22 o menor), más corto |

**Importante:** Pines digitales Arduino aportan máx 40mA c/u, total 200mA. Si más carga, usar transistores/MOSFETs intermedios.

### 8.3 Problemas de Comunicación

#### Problema 8: ESP32 no conecta a WiFi

**Síntomas:** Monitor serial muestra "WiFi failed" o timeout

| Causa | Verificación | Solución |
|-------|--------------|----------|
| SSID/Password incorrectos | Revisar código: mayúsculas, espacios | Corregir credenciales |
| Red 5GHz (ESP32 solo 2.4GHz) | Verificar router: banda 2.4GHz habilitada | Conectar a red 2.4GHz o modo dual |
| Señal débil | RSSI < -80 dBm | Acercar ESP32 a router, antena externa |
| IP estática mal configurada | DHCP deshabilitado | Habilitar DHCP o configurar IP manual correcta |
| Firewall router bloqueando | Verificar logs router | Agregar MAC ESP32 a whitelist |

**Código diagnóstico:**
```cpp
#include <WiFi.h>
const char* ssid = "TU_RED";
const char* password = "TU_PASS";

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Conectando WiFi...");
  WiFi.begin(ssid, password);
  
  int intentos = 0;
  while (WiFi.status() != WL_CONNECTED && intentos < 20) {
    delay(500);
    Serial.print(".");
    intentos++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConectado!");
    Serial.print("IP: "); Serial.println(WiFi.localIP());
    Serial.print("RSSI: "); Serial.print(WiFi.RSSI()); Serial.println(" dBm");
  } else {
    Serial.println("\nFALLO");
    Serial.print("Status: "); Serial.println(WiFi.status());
    // 0=IDLE, 1=NO_SSID, 3=CONNECTED, 4=CONNECT_FAILED, 6=DISCONNECTED
  }
}
```

#### Problema 9: WebSocket no conecta (WiFi OK)

| Causa | Diagnóstico | Solución |
|-------|-------------|----------|
| IP backend incorrecta | Ping desde ESP32 red local | Corregir IP en código |
| Puerto bloqueado | Windows Firewall bloquea 8080 | Regla entrada TCP 8080 allow |
| Backend no corriendo | `netstat -an \| findstr 8080` | Iniciar uvicorn |
| Ruta WebSocket incorrecta | Verificar URL: `ws://IP:8080/ws/greenhouse` | Corregir ruta en ESP32 |
| Certificado SSL (si wss://) | Error handshake | Usar ws:// (no seguro) o configurar certificado correcto |

#### Problema 10: Arduino no recibe comandos desde ESP32

**Síntoma:** ESP32 envía, monitor serial Arduino no muestra nada

| Causa | Verificación | Solución |
|-------|--------------|----------|
| TX-RX invertidos | TX ESP32 debe ir a RX Arduino | Intercambiar cables |
| Baudrate diferente | Verificar: Serial1.begin(115200) ambos lados | Igualar baudrate |
| Tierra no común | Medir voltaje GND ESP32 - GND Arduino | Conectar GND común **OBLIGATORIO** |
| Nivel lógico 5V vs 3.3V | ESP32 TX (3.3V) al RX Arduino (tolera) OK, pero Arduino TX (5V) daña ESP32 RX | Divisor resistivo 2kΩ/1kΩ en TX Arduino |

**Prueba cruzada:**
```cpp
// En Arduino:
void loop() {
  Serial1.println("Hola ESP32");
  delay(1000);
}

// En ESP32:
void loop() {
  if (Serial2.available()) {
    String msg = Serial2.readStringUntil('\n');
    Serial.println("Recibido: " + msg);
  }
}
// Debe aparecer "Recibido: Hola ESP32" cada segundo
```

---

## 9. PLAN DE PRUEBAS Y DEMOSTRACIÓN PARA FERIA/CLIENTE

### 9.1 Escenario de Demostración

**Objetivo:** Mostrar capacidades del sistema en 5 minutos, impresionando con automatización, respuesta en tiempo real y métricas cuantificables.

**Audiencia:** Inversionistas, jurado de concurso, clientes potenciales (agricultores, agrónomos).

**Requisitos:**
- Sistema completamente armado y probado
- WiFi local disponible o hotspot móvil
- App móvil instalada en tablet/smartphone
- Datos simulados o reales de 24-48h previas
- Backup plan: modo standalone sin WiFi

### 9.2 Guion de Demostración en Vivo (10 pasos, <5 minutos)

#### Preparación (antes de audiencia)
- [ ] Sistema encendido hace >10min (sensores estabilizados)
- [ ] App conectada, dashboard mostrando datos en vivo
- [ ] Modo manual habilitado para control directo
- [ ] Vaso con agua y sensor de suelo a mano
- [ ] Tarjeta RFID preparada

---

## **DEMO SCRIPT - InvernaderoIA Greentech (5 minutos)**

### Paso 1: Introducción (30 segundos)
**Locutor:**  
_"Bienvenidos. Soy [Nombre] y les presento InvernaderoIA Greentech, un sistema IoT que monitorea y controla automáticamente las condiciones de cultivo en invernaderos. Este prototipo integra **5 sensores ambientales DHT22**, **2 sensores de suelo**, **3 detectores de gas**, control de acceso **RFID** y **gestión remota vía app móvil**. Vamos a verlo en acción."_

**Mostrar:** Sistema físico montado (caja/PCB), tablet con app.

---

### Paso 2: Monitoreo en Tiempo Real (45 segundos)
**Acción:**  
1. Abrir app, pantalla Dashboard.
2. Señalar gráficas de temperatura y humedad actualizándose en vivo.

**Locutor:**  
_"Observen el dashboard: temperatura promedio es **24.3°C** y humedad **68%** en este momento. Estos valores se actualizan cada 5 segundos desde los sensores distribuidos en 4 zonas del invernadero. También monitorea humedad del suelo (actualmente **52%**) y calidad del aire."_

**Métricas mostradas:**
- 🌡️ Temp: 24.3°C
- 💧 Humedad: 68%
- 💦 Suelo: 52%
- 🌀 Gases: 250 PPM (normal)

---

### Paso 3: Simulación de Riego Automático (1 minuto)
**Acción:**  
1. Sacar sensor de humedad de suelo del sustrato (simula sequía).
2. Esperar 5-10 segundos → lectura baja a ~20%.
3. SISTEMA ACTIVA AUTOMÁTICAMENTE la bomba de riego.

**Locutor:**  
_"El sensor detectó que la humedad cayó a **20%**, por debajo del umbral de riego configurado en **30%**. El sistema **automáticamente activa la bomba** por 60 segundos para irrigar. No requiere intervención humana."_

**Evidencia:** Sonido de relé (clic), LED relé enciende, bomba funciona (agua circula), app muestra "Riego activo" en tiempo real.

4. Insertar sensor en vaso con agua → sube a 80% → sistema **desactiva bomba**.

**Locutor:**  
_"Al alcanzar **60% de humedad**, el riego se detiene automáticamente. Esto ahorra **hasta 40% de agua** comparado con riego manual tradicional."_

---

### Paso 4: Control Manual desde App (40 segundos)
**Acción:**  
1. En la app, ir a pantalla "Control".
2. Tocar botón **"Activar Ventiladores"**.
3. Ventiladores físicos se encienden inmediatamente.

**Locutor:**  
_"Desde la app también puedo controlar manualmente cualquier actuador. Por ejemplo, activar los ventiladores para aumentar la circulación de aire en zonas calientes."_

4. **"Activar Iluminación LED"** → luces se encienden.
5. Desactivar ambos.

**Evidencia:** Respuesta instantánea (<1s latencia), confirmación visual con actuadores.

---

### Paso 5: Control de Acceso RFID (30 segundos)
**Acción:**  
1. Acercar tarjeta RFID al lector.
2. LED verde parpadea 3 veces, buzzer suena (opcional).
3. Monitor serial / app muestra: **"Acceso concedido: Usuario Técnico, 10:45 AM"**.

**Locutor:**  
_"El sistema tiene control de acceso mediante RFID. Solo personal autorizado puede acceder físicamente al sistema. Cada acceso queda registrado con timestamp para trazabilidad completa."_

**Evidencia:** Mensaje en app histórico de accesos.

---

### Paso 6: Alarma de Gas (45 segundos)
**Acción:**  
1. Acercar encendedor (SIN encender) al sensor MQ-2 por 3-5 segundos.
2. Lectura de gas sube >1000 PPM.
3. **SISTEMA ACTIVA ALARMA:**
   - LED alarma parpadea rápido.
   - Buzzer suena (si disponible).
   - App muestra notificación: **"⚠️ ALARMA: Gas detectado 1200 PPM"**.
   - **Ventiladores se activan** automáticamente.
   - **Bomba y luces se desactivan** por seguridad.

**Locutor:**  
_"Detectó un nivel peligroso de gas. El sistema **automáticamente** activa ventilación máxima y apaga circuitos de riesgo para prevenir incendios. Esta funcionalidad protege cultivos y personas ante fugas de gas o incendios."_

4. Retirar encendedor → gas baja → resetear alarma desde app.

---

### Paso 7: Historial y Análisis (30 segundos)
**Acción:**  
1. Ir a pantalla "Historial" en app.
2. Mostrar gráficas de últimas 24 horas (temperatura, humedad, riegos realizados).

**Locutor:**  
_"Cada lectura se almacena en base de datos. Aquí vemos las últimas 24 horas: temperatura estuvo entre **22-28°C**, se realizaron **3 ciclos de riego automático** y hubo un pico de humedad ambiental a las 6 AM por condensación matutina."_

**Métricas clave:**
- 📊 Riegos automáticos: 3
- ⏱️ Tiempo total riego: 180s
- 💧 Agua estimada: 1.5L
- 🌡️ Temp min/max: 22°C / 28°C

---

### Paso 8: Inteligencia Artificial (Opcional, 30 segundos)
**Si implementado:**  
1. Activar **Modo IA** en app.
2. Explicar modelo predictivo TensorFlow/Keras.

**Locutor:**  
_"El sistema incorpora un modelo de IA entrenado con datos históricos de cultivos. Predice las condiciones óptimas y ajusta automáticamente riego e iluminación para maximizar el crecimiento. En pruebas, incrementó la productividad **25-35%**."_

**Evidencia:** Pantalla mostrando predicción: "Recomendación IA: Incrementar riego 15% próximas 6h (previsión sequía)".

---

### Paso 9: Escalabilidad y Conectividad (20 segundos)
**Locutor:**  
_"Este prototipo maneja 4 zonas, pero el sistema es **escalable**: puede gestionar hasta 64 zonas con actuadores adicionales. Se conecta vía **WiFi/4G** para monitoreo remoto desde cualquier ubicación, ideal para agricultores que gestionan múltiples invernaderos a distancia."_

---

### Paso 10: Cierre y Métricas de Impacto (30 segundos)
**Locutor:**  
_"Para resumir, InvernaderoIA ofrece:_
- _**Ahorro de agua: 40%** gracias a riego preciso._
- _**Reducción de mano de obra: 60%** (automatización total)._
- _**Incremento de productividad: 25-35%** (condiciones óptimas constantes)._
- _**Prevención de pérdidas** por gases, sequía, heladas._
- _**Bajo costo:** <$200 USD en componentes, escalable según necesidad._

_Esto transforma invernaderos tradicionales en sistemas inteligentes accesibles para pequeños y medianos agricultores. ¿Preguntas?"_

---

### Métricas a Medir Durante Demo

| Métrica | Valor Objetivo | Cómo Medir |
|---------|----------------|------------|
| **Tiempo de respuesta actuador** | <1 segundo | Cronómetro app → relé activa |
| **Precisión sensor temperatura** | ±0.5°C | Comparar con termómetro calibrado |
| **Uptime sistema** | >99% (últimas 48h) | Logs: tiempo activo / tiempo total |
| **Latencia WiFi** | <200ms | Ping ESP32 → backend |
| **Ahorro agua simulado** | 40% vs manual | (Tiempo bomba ON / tiempo total) × factor |
| **Tasa éxito RFID** | >95% | (Lecturas correctas / intentos) × 100 |

---

### Backup Plan (Sin WiFi/Internet)

**Si falla conexión WiFi durante demo:**

1. **Modo Standalone Arduino:**
   - Sistema sigue funcionando en automático (control por umbrales local).
   - Mostrar monitor serial directo en laptop.
   
2. **Demostración Offline:**
   - Usar logs descargados previamente en USB.
   - Mostrar interfaz app en modo demo (datos simulados).
   
3. **Explicación:**  
   _"Ante pérdida de conectividad, el sistema continúa operando de forma autónoma. Los datos se almacenan localmente en tarjeta SD y se sincronizan automáticamente cuando se restablece la conexión."_

---

## 10. PLAN DE MEJORAS Y ROADMAP TÉCNICO

### 10.1 Mejoras a Corto Plazo (1-3 meses)

#### Hardware
- **Pantalla LCD 20x4** con I2C para visualización local (sin app).
- **RTC DS3231** para timestamp preciso sin WiFi.
- **Sensor de luz LDR** para ajuste automático iluminación.
- **Sensor ultrasónico HC-SR04** para nivel de agua preciso.
- **Buzzer activo** para alarmas sonoras.

#### Software
- **Logs estructurados JSON** en SD (fácil parsing).
- **OTA (Over-The-Air) updates** para firmware ESP32.
- **Backup automático EEPROM** a SD cada semana.
- **Modo ahorro energía:** sleep ESP32 cuando inactivo.
- **Notificaciones push** vía Firebase Cloud Messaging.

### 10.2 Mejoras a Mediano Plazo (3-6 meses)

#### Integración con Servicios Cloud
- **Migrar backend a AWS/Azure:**
  - RDS (PostgreSQL) para datos históricos escalables.
  - S3 para almacenar logs largo plazo.
  - Lambda para procesamiento serverless.
  
- **Dashboard web:**
  - React/Vue.js para monitoreo desde navegador.
  - Gráficas interactivas (Chart.js, D3.js).
  - Export datos CSV/Excel.

#### Modelo de IA Mejorado
- **Reentrenamiento mensual** con datos reales del invernadero.
- **Predicción clima** integrada (API OpenWeather) para anticipar heladas/olas de calor.
- **Recomendaciones personalizadas** por tipo de cultivo (tomate, lechuga, fresa, etc.).
- **Detección anomalías** (plagas, enfermedades) mediante visión artificial (Raspberry Pi + cámara).

### 10.3 Mejoras a Largo Plazo (6-12 meses)

#### Escalabilidad Industrial
- **Protocolo LoRaWAN** para invernaderos remotos sin WiFi.
- **Mesh network** con múltiples ESP32 para grandes instalaciones.
- **PLC industrial** (Siemens S7, Allen-Bradley) para integración con sistemas existentes.
- **Sensores profesionales:**
  - CO₂ (MH-Z19B) para fotosíntesis optimizada.
  - pH y EC para hidroponía.
  - PAR meter para luz fotosintéticamente activa.

#### Monetización y Modelo de Negocio
- **SaaS (Software as a Service):**
  - Plan básico: $10/mes (1 invernadero, 10 sensores).
  - Plan pro: $50/mes (5 invernaderos, análisis IA ilimitado).
  - Plan enterprise: personalizado (integración ERP agrícola).

- **Hardware como servicio:**
  - Venta de kits completos ($300-$500 USD).
  - Subscripción firmware premium con updates.
  - Servicio instalación y mantenimiento.

#### Certificaciones
- **CE/FCC** para comercialización Europa/USA.
- **IP65** encapsulado resistente agua/polvo.
- **Norma ISO 11783** (ISOBUS) para maquinaria agrícola.

### 10.4 Roadmap Visual

```
Q4 2024 - Q1 2025: PROTOTIPO MVP
├─ Arduino Mega + sensores básicos
├─ App móvil Flutter v1.0
├─ Backend FastAPI local
└─ Demo funcional

Q2-Q3 2025: PRODUCCIÓN BETA
├─ 10 instalaciones piloto (agricultores locales)
├─ Feedback y mejoras UX
├─ Modelo IA entrenado datos reales
├─ Dashboard web lanzado
└─ Certificación eléctrica local

Q4 2025 - Q1 2026: LANZAMIENTO COMERCIAL
├─ Marketing y preventa (500 unidades)
├─ E-commerce (tienda online)
├─ Alianzas distribuidores agrícolas
├─ Soporte técnico 24/7 (chat)
└─ Primeras rondas inversión Serie A

2026-2027: ESCALAMIENTO INTERNACIONAL
├─ Expansión LATAM (México, Colombia, Chile)
├─ Integración IoT plataformas (Google Cloud IoT Core)
├─ Versión industrial 200+ sensores
├─ Patentes tecnología IA predictiva
└─ IPO tecnología agrícola o adquisición
```

---

*Continúa en PITCH_COMERCIAL.md*
