# InvernaderoIA — Greentech
## Manual de Usuario

---

## 5. MANUAL DE USUARIO PASO A PASO

### 5.1 Instalación Inicial

#### Paso 1: Desembalaje y Verificación
1. Verificar que todos los componentes estén presentes (ver lista sección 2)
2. Inspeccionar visualmente sensores y cables (no daños físicos)
3. Preparar herramientas: multímetro, destornilladores, alicate, soldador (opcional)

#### Paso 2: Montaje del Sistema de Alimentación
1. **Conectar fuente 12V:**
   - Fusible 5A en línea positiva
   - Positivo → bornera de distribución
   - Negativo → tierra común

2. **Conectar fuente 9V para Arduino:**
   - Positivo → VIN Arduino Mega
   - Negativo → GND Arduino

3. **Verificación con multímetro:**
   - Entre VIN-GND: 9V ±0.5V
   - Entre pin 5V-GND: 5V ±0.25V
   - Entre pin 3.3V-GND: 3.3V ±0.15V

#### Paso 3: Conexión de Sensores
**Seguir diagrama sección 3.2-3.5:**

1. **DHT22** (4-5 unidades):
   - VCC → 5V
   - DATA → Pines 22-26 (según zona)
   - GND → GND
   - Soldar resistor 10kΩ entre DATA y VCC

2. **Sensores de Humedad de Suelo** (2 unidades):
   - VCC → 5V
   - AOUT → A0, A1
   - GND → GND

3. **Sensores MQ** (3 unidades):
   - VCC → 5V (preferible fuente externa por consumo)
   - AOUT → A2, A3, A4
   - DOUT → Pines 27, 28, 29 (opcional)
   - GND → GND
   - **Dejar precalentar 24-48h para calibración óptima**

4. **RFID MFRC522:**
   - ⚠️ **3.3V únicamente**
   - Seguir tabla sección 3.5 (SPI)
   - Usar divisor resistivo si necesario

#### Paso 4: Conexión de Módulo de Relés
1. Conectar pines IN1-IN8 a pines digitales 30-37
2. VCC relé → 5V Arduino
3. GND relé → GND común
4. **Lado de potencia:**
   - COM → Positivo 12V (o fase AC si aplica)
   - NO (normalmente abierto) → Actuador positivo
   - Actuador negativo → GND/Neutro

5. **Soldar diodos 1N4007:**
   - Cátodo (+) → VCC bobina relé
   - Ánodo (-) → GND

#### Paso 5: Instalación de Actuadores
1. **Bombas de riego 12V:**
   - Positivo → NO relé canal 1 y 2
   - Negativo → GND común
   - Verificar flujo de agua (manguera 6mm aprox)

2. **Ventiladores 12V:**
   - Positivo → NO relé canal 3 y 4
   - Negativo → GND común
   - Orientar para circulación cruzada

3. **Iluminación LED 12V:**
   - Positivo → NO relé canal 5 y 6
   - Negativo → GND común

#### Paso 6: Instalación de Cód conducentes Firmware
**Ver archivo:** `arduino_mega_firmware.ino` y `esp32_config_firmware.ino`

1. **Arduino IDE:**
   - Instalar librerías:
     - DHT sensor library (Adafruit)
     - MFRC522
     - ArduinoJson (v6+)
     - SD (built-in)

2. **Cargar firmware Arduino Mega:**
   ```
   Herramientas → Placa → Arduino Mega 2560
   Herramientas → Puerto → COMx
   Sketch → Subir
   ```

3. **Cargar firmware ESP32:**
   ```
   Herramientas → Placa → ESP32 Dev Module
   Herramientas → Puerto → COMx
   Configurar WiFi SSID/Password en código
   Sketch → Subir
   ```

#### Paso 7: Configuración WiFi y Backend
1. **Configurar ESP32:**
   - Editar `esp32_config_firmware.ino`
   - Cambiar:
     ```cpp
     const char* ssid = "TU_RED_WIFI";
     const char* password = "TU_PASSWORD";
     const char* serverIP = "192.168.1.XXX"; // IP backend
     ```

2. **Iniciar backend FastAPI:**
   ```bash
   cd InvernaderoIA
   uvicorn api.main:app --host 0.0.0.0 --port 8080
   ```

3. **Verificar conexión:**
   - Abrir monitor serial ESP32 (115200 baud)
   - Debe aparecer: "WiFi conectado, IP: ..."
   - "WebSocket conectado al servidor"

---

### 5.2 Encendido y Verificación

#### Procedimiento de Encendido Seguro

1. **Verificación pre-encendido:**
   - [ ] Todos los GND conectados a tierra común
   - [ ] No cortocircuitos visibles
   - [ ] Fusibles instalados
   - [ ] Multímetro: verificar continuidad tierra
   - [ ] Actuadores desconectados (primera prueba)

2. **Encendido paso a paso:**
   ```
   1. Conectar fuente 9V Arduino → LED power ON
   2. Esperar 5s → Monitor serial 115200 baud
   3. Verificar mensaje: "Sistema InvernaderoIA iniciado"
   4. Verificar lecturas sensores (no NaN)
   5. Conectar fuente 12V actuadores
   6. Conectar ESP32 USB/5V
   7. Verificar conexión WiFi en monitor serial ESP32
   ```

3. **Checklist de verificación:**

   | Item | Esperado | Acción si falla |
   |------|----------|-----------------|
   | LED power Arduino | Encendido | Verificar fuente 9V |
   | Monitor serial responde | "Sistema iniciado" | Verificar USB, driver CH340 |
   | DHT22 zona 1 | 15-35°C, 30-90% | Revisar conexión, resistor pull-up |
   | Humedad suelo 1 | 0-100% | Calibrar rango seco/mojado |
   | MQ-2 | >100 (precalentando) | Esperar 2-5 min más |
   | RFID | "Listo" | Verificar SPI, voltaje 3.3V |
   | ESP32 WiFi | "Conectado,IP:..." | Verificar SSID/password |
   | WebSocket | "WS conectado" | Verificar IP backend, firewall |

4. **Prueba de actuadores (modo manual):**
   ```
   - Enviar comando prueba desde backend/app
   - O usar monitor serial: {"tipo":"comando","accion":"riego_on","zona":0}
   - Verificar:
     * Clic relé (sonido mecánico)
     * LED relé enciende
     * Actuador funciona (bomba bombea, ventilador gira)
   - Desactivar: {"tipo":"comando","accion":"riego_off","zona":0}
   ```

---

### 5.3 Uso Diario

#### Rutina Matutina (5 minutos)
1. **Inspección visual:**
   - Nivel de agua en tanque (>50%)
   - LEDs Arduino/ESP32 encendidos
   - No alarmas sonoras/visuales
   - Pantalla LCD (si instalada): lecturas normales

2. **Revisión en app móvil:**
   - Abrir app InvernaderoIA
   - Dashboard → Verificar gráficas últimas 24h
   - Temperatura promedio: 18-28°C ✓
   - Humedad suelo: 40-70% ✓
   - Alertas: ninguna ✓

3. **Ajustes manuales (si necesario):**
   - Si temp >30°C: activar ventilación forzada
   - Si humedad <35%: riego manual 60s
   - Si gas >500 PPM: verificar fuente (cocina cercana, etc.)

#### Control Manual desde App
```
Pantalla de Control:
  [Zona 1]
    🌡️ 24.5°C  💧 65%  💦 45%
    [Regar 60s] [Regar 120s]
  
  [Zona 2]
    🌡️ 23.8°C  💧 68%  💦 52%
    [Regar 60s] [Regar 120s]
  
  [Ventilación]
    🌀 Ventilador 1: ● ON
    🌀 Ventilador 2: ○ OFF
    [Activar] [Desactivar]
  
  [Iluminación]
    💡 Estado: ● Horario automático (6:00-20:00)
    [Forzar ON] [Forzar OFF] [Auto]
  
  [Modo]
    ⚙️ Actual: Automático
    [Manual] [Automático] [Eco]
```

#### Uso de RFID

1. **Registro de tarjetas (primera vez):**
   ```cpp
   // En firmware Arduino, modo aprendizaje
   void setup() {
     // Descomentar modo registro:
     modoRegistro = true;
   }
   ```
   - Acercar tarjeta nueva a lector
   - UID se guarda en EEPROM
   - Monitor serial: "Tarjeta registrada: A3B2C1D4"

2. **Uso cotidiano:**
   - Acercar tarjeta autorizada → LED verde 3 parpadeos
   - Control manual habilitado 5 minutos
   - Log de acceso guardado con timestamp
   - Si tarjeta no autorizada → LED rojo 5 parpadeos

3. **Gestión de usuarios:**
   - Máximo 10 tarjetas almacenadas
   - Eliminar usuario: modo servicio técnico
   - Historial de accesos en SD: `logs_accesos.txt`

---

### 5.4 Interpretación de Lecturas

#### Valores Normales

| Sensor | Rango Normal | Alarma Low | Alarma High |
|--------|--------------|------------|-------------|
| Temperatura | 18-30°C | <10°C | >35°C |
| Humedad ambiente | 60-80% | <40% | >90% |
| Humedad suelo | 40-70% | <30% | >80% (encharcamiento) |
| Gas MQ-2 (humo) | 50-300 PPM | - | >1000 PPM |
| Gas MQ-5 (GLP) | 50-200 PPM | - | >800 PPM |
| Nivel agua | 50-100% | <20% | - |

#### Diagnóstico de Lecturas Anómalas

**Problema:** DHT22 muestra -999 o NaN
- **Causa:** Sensor desconectado, cable roto, falta resistor pull-up
- **Solución:** Verificar conexión, medir 5V entre VCC-GND del sensor, agregar resistor 10kΩ

**Problema:** Humedad suelo siempre 100%
- **Causa:** Sensor en agua permanente o calibración incorrecta
- **Solución:** Sacar sensor, limpiar, recalibrar valores seco/mojado en código

**Problema:** Humedad suelo siempre 0%
- **Causa:** Sensor desconectado o valor de calibración invertido
- **Solución:** Verificar conexión A0/A1, invertir valores `sueloSeco/sueloMojado`

**Problema:** MQ muestra lecturas inestables
- **Causa:** Precalentamiento insuficiente, alimentación inestable
- **Solución:** Esperar 24h precalentamiento, verificar 5V estable, agregar capacitor 100µF

**Problema:** RFID no detecta tarjetas
- **Causa:** Conexión SPI incorrecta, voltaje >3.3V dañó módulo
- **Solución:** Verificar tabla pines SPI, medir 3.3V en VCC, reemplazar módulo si dañado

---

### 5.5 Cambio de Modo de Operación

#### Modo Automático (Recomendado)
```json
// Comando desde app o serial
{
  "tipo": "comando",
  "accion": "modo_auto",
  "valor": true
}
```
- Sistema controla riego/ventilación por umbrales
- Usuario solo supervisa y ajusta umbrales
- Logs automáticos cada 10 minutos

#### Modo Manual
```json
{
  "tipo": "comando",
  "accion": "modo_auto",
  "valor": false
}
```
- Todos los actuadores controlados desde app/RFID
- Alarmas siguen activas
- Útil para mantenimiento o pruebas

#### Modo Eco (Ahorro energía)
```json
{
  "tipo": "comando",
  "accion": "modo_eco",
  "valor": true
}
```
- Reduce frecuencia de riego 50%
- Iluminación solo horario crítico (8:00-18:00)
- Ventilación solo si temp >32°C

---

## 6. PLAN DE MANTENIMIENTO

### 6.1 Checklist Semanal (15 minutos)

| Tarea | Frecuencia | Procedimiento |
|-------|------------|---------------|
| **Inspección visual** | Semanal | Verificar cables sueltos, corrosión, humedad en componentes |
| **Limpieza sensores DHT22** | Semanal | Paño seco, no sumergir |
| **Limpieza sensores suelo** | Semanal | Retirar tierra adherida, no usar agua directa |
| **Nivel de agua** | Semanal | Rellenar tanque a 80% mínimo |
| **Prueba actuadores** | Semanal | Activar manual cada relé 10s, verificar funcionamiento |
| **Revisión logs SD** | Semanal | Descargar `logs.txt`, verificar no errores repetidos |
| **Limpieza filtros bomba** | Semanal | Extraer filtro, limpiar sedimentos |

### 6.2 Checklist Mensual (45 minutos)

| Tarea | Procedimiento | Herramientas |
|-------|---------------|--------------|
| **Calibración sensores suelo** | Método aire/agua, actualizar valores en código | Multímetro, vaso con agua |
| **Limpieza sensores MQ** | Paño seco, NO alcohol, revisar resistencia calefactora | Multímetro |
| **Revisión conexiones** | Apretar borneras, soldar cables sueltos | Destornillador, soldador |
| **Backup configuración** | Guardar valores EEPROM en archivo | Laptop, monitor serial |
| **Actualización firmware** | Verificar versión, aplicar parches si hay | Arduino IDE |
| **Prueba de alarmas** | Simular gas (encendedor cerca MQ-2), verificar respuesta | - |
| **Limpieza general** | Caja, ventiladores (polvo), PCB (aire comprimido) | Compresor, brocha |
| **Revisión mecánica** | Uniones mangueras, soportes sensores, tuercas | Llave ajustable |

### 6.3 Mantenimiento Trimestral

- **Reemplazo de filtros** de bomba de agua
- **Calibración completa** de todos los sensores MQ (método gas estándar

)
- **Actualización de modelo IA** con datos históricos nuevos
- **Revisión de fusibles** y reemplazo si signos de desgaste
- **Backup completo** de base de datos y logs
- **Prueba de recuperación ante fallo** (desconectar ESP32, verificar Arduino standalone)

### 6.4 Registro de Mantenimiento

**Plantilla:**
```
Fecha: ___________
Técnico: __________
Tarea: ____________

Checklist:
[ ] Sensores limpios
[ ] Actuadores probados
[ ] Logs revisados
[ ] Calibración OK
[ ] Alarmas funcionando

Observaciones:
_________________________
_________________________

Próximo mantenimiento: ___________
```

---

## 7. PROCEDIMIENTO DE SEGURIDAD ANTE ALARMAS

### 7.1 ALARMA: Detección de Gas

**Síntomas:**
- LED alarma parpadeando rápido
- Buzzer sonando (si instalado)
- Monitor serial: "ALARMA: Gas detectado >1000 PPM"
- App móvil: notificación push "⚠️ Gas detectado"

**Procedimiento:**
1. **EVACUACIÓN INMEDIATA** del área (personas/animales)
2. **NO ACCIONAR** interruptores eléctricos
3. **Ventilar** abrir puertas/ventanas
4. Sistema **automáticamente**:
   - Desactiva bomba, luces, calefactor
   - Activa ventiladores al máximo
   - Corta alimentación circuitos optativos (si relé maestro instalado)

5. **Verificar fuente:**
   - Fuga de gas (cocina, calentador cercano)
   - Combustión (fuego externo)
   - Falsa alarma (sensor MQ sucio, humedad)

6. **Resetear alarma:**
   - Solo cuando PPM <300 durante 5 minutos seguidos
   - Botón reset físico o comando:
     ```json
     {"tipo":"comando","accion":"reset_alarma"}
     ```

### 7.2 ALARMA: Fallo de Bomba

**Síntomas:**
- Relé activo (clic, LED encendido) pero bomba no funciona
- Presión de agua nula
- Timeout riego (bomba activa >5min sin desactivar)

**Procedimiento:**
1. **Desactivar riego** manualmente:
   ```json
   {"tipo":"comando","accion":"riego_off","zona":0}
   ```

2. **Diagnóstico:**
   - ✓ Voltaje en terminales bomba: debe ser 12V
   - ✓ Nivel de agua en tanque: >20%
   - ✓ Filtro bomba: no obstruido
   - ✓ Rodete bomba: gira libremente
   - ✓ Fusible línea 12V: intacto

3. **Causas comunes:**
   - Bomba bloqueada (sedimento, aire)
   - Cable roto/desconectado
   - Bomba quemada (medir resistencia bobina: típico 10-50Ω)
   - Relé soldado (stuck closed/open)

4. **Solución temporal:**
   - Riego manual con regadera
   - Activar bomba zona 2 (si disponible)
   - Contactar soporte técnico

### 7.3 ALARMA: Cortocircuito/Sobrecorriente

**Síntomas:**
- Fusible fundido
- Arduino/ESP32 reinicia continuamente
- Olor a quemado
- Pin de voltaje anómalo (<2V cuando esperábamos 5V)

**Procedimiento CRÍTICO:**
1. **DESCONECTAR INMEDIATAMENTE** todas las fuentes de alimentación
2. **NO RECONECTAR** hasta identificar causa
3. **Inspección visual:**
   - Cables pelados tocando tierra
   - Componentes quemados (olor, decoloración)
   - Agua/humedad en PCB
   - Soldaduras frías/puentes

4. **Diagnóstico con multímetro:**
   - Modo continuidad
   - Verificar entre VCC-GND (debe ser circuito abierto, infinito)
   - Si <100Ω: cortocircuito presente
   - Desconectar componentes uno por uno hasta identificar culpable

5. **Causas frecuentes:**
   - Pin 5V Arduino tocando GND (cable dañado)
   - Relé con carga AC mal aislada
   - Sensor MQ con VCC-GND invertidos
   - Agua filtrada en uniones

6. **Reparación:**
   - Reemplazar fusible SOLO después de eliminar cortocircuito
   - Aislar conexiones con termoretráctil
   - Reemplazar componente dañado
   - Prueba sin actuadores primero

---

*Continúa en siguiente documento: TROUBLESHOOTING_DEMOSTRACION.md*
