# 🚀 Guía de Despliegue en Railway - InvernaderoIA

## ✅ Estado Actual
- ✅ Código subido a GitHub: `https://github.com/strix2579/InvernaderoIA`
- ✅ Archivos de configuración creados (`railway.json`, `Procfile`)
- ✅ Base de datos integrada en el código
- ✅ Listo para desplegar

---

## 📋 Pasos para Desplegar en Railway

### **PASO 1: Crear Proyecto en Railway**

1. Ve a [railway.app](https://railway.app/)
2. Inicia sesión con tu cuenta de GitHub
3. Haz clic en **"New Project"**
4. Selecciona **"Deploy from GitHub repo"**
5. Busca y selecciona: **`strix2579/InvernaderoIA`**
6. Haz clic en **"Deploy Now"**

> ⚠️ **IMPORTANTE**: Railway empezará a construir, pero **FALLARÁ** porque aún no tiene la base de datos. Esto es normal, continúa con el siguiente paso.

---

### **PASO 2: Agregar Base de Datos PostgreSQL**

1. En la vista de tu proyecto (verás un bloque con tu repositorio)
2. Haz clic en **"New"** (botón superior derecho) o **"+"**
3. Selecciona **"Database"** → **"Add PostgreSQL"**
4. Espera 10-15 segundos mientras Railway crea la base de datos
5. Verás un nuevo bloque llamado **"Postgres"**

---

### **PASO 3: Conectar Backend con PostgreSQL**

1. **Copiar la URL de la Base de Datos:**
   - Haz clic en el bloque **"Postgres"**
   - Ve a la pestaña **"Variables"**
   - Busca la variable **`DATABASE_URL`**
   - Haz clic en el ícono de **copiar** (📋) junto a su valor

2. **Agregar Variable al Backend:**
   - Haz clic en el bloque de tu **Backend** (el que dice "InvernaderoIA" o "web")
   - Ve a la pestaña **"Variables"**
   - Haz clic en **"New Variable"** o **"+ Variable"**
   - **Variable:** `DATABASE_URL`
   - **Value:** (Pega la URL que copiaste)
   - Haz clic en **"Add"**

> 🔄 Railway automáticamente reiniciará el despliegue. Espera 2-3 minutos.

---

### **PASO 4: Generar URL Pública**

1. En el bloque de tu **Backend**, ve a la pestaña **"Settings"**
2. Baja hasta la sección **"Networking"**
3. Haz clic en **"Generate Domain"**
4. Te dará una URL como: `invernaderoia-production.up.railway.app`
5. **¡COPIA ESTA URL!** La necesitarás para el ESP32 y la App Flutter

---

### **PASO 5: Verificar que Funciona**

1. Ve a la pestaña **"Deployments"** en tu proyecto
2. Deberías ver el último deployment con estado **"SUCCESS"** ✅
3. Haz clic en **"View Logs"** para ver que todo esté corriendo
4. Deberías ver mensajes como:
   ```
   INFO:     Started server process
   INFO:     Waiting for application startup.
   INFO:     Application startup complete.
   INFO:     Uvicorn running on http://0.0.0.0:XXXX
   ```

5. **Prueba la API:**
   - Abre tu navegador
   - Ve a: `https://TU-URL-DE-RAILWAY.up.railway.app/docs`
   - Deberías ver la documentación de FastAPI (Swagger UI)

---

## 🎯 Siguiente Paso: Actualizar ESP32

Una vez que tengas tu URL de Railway funcionando, necesitas actualizar el firmware del ESP32.

### **Archivo a Modificar:**
`firmware/esp32_config_firmware.ino`

### **Línea a Cambiar:**
Busca esta línea (aproximadamente línea 30-40):

```cpp
const char* serverUrl = "ws://192.168.100.2:8080/ws/connect";
```

**Cámbiala por:**
```cpp
const char* serverUrl = "wss://TU-URL-DE-RAILWAY.up.railway.app/ws/connect";
```

> ⚠️ **Nota**: Cambia `ws://` por `wss://` (WebSocket Seguro) porque Railway usa HTTPS.

### **Recompilar y Subir:**
1. Abre Arduino IDE
2. Abre `esp32_config_firmware.ino`
3. Cambia la URL
4. Compila y sube al ESP32
5. Abre el Monitor Serial (115200 baud)
6. Deberías ver: `✓ WebSocket conectado al servidor`

---

## 🔧 Solución de Problemas

### **El deployment falla con error de Python:**
- Railway debería detectar automáticamente Python 3.11
- Si falla, ve a Settings → Environment y agrega:
  - Variable: `NIXPACKS_PYTHON_VERSION`
  - Value: `3.11`

### **Error: "No module named 'tensorflow'"**
- Verifica que `requirements.txt` esté en la raíz del proyecto
- Railway debería instalar todas las dependencias automáticamente

### **La base de datos no se conecta:**
- Verifica que la variable `DATABASE_URL` esté correctamente copiada
- Asegúrate de que ambos servicios (Backend y Postgres) estén en el mismo proyecto

### **El WebSocket no conecta desde el ESP32:**
- Verifica que uses `wss://` (no `ws://`)
- Verifica que la URL no tenga espacios ni caracteres extra
- Verifica que el ESP32 tenga acceso a internet

---

## 📊 Monitoreo

### **Ver Logs en Tiempo Real:**
1. Ve a tu proyecto en Railway
2. Haz clic en el bloque del Backend
3. Pestaña **"Deployments"** → Click en el deployment activo
4. Verás los logs en tiempo real

### **Ver la Base de Datos:**
1. Haz clic en el bloque **"Postgres"**
2. Pestaña **"Data"**
3. Podrás ver las tablas: `sensor_readings`, `alarm_logs`, `system_config`

---

## 🎉 ¡Listo!

Una vez completados estos pasos:
- ✅ Tu backend estará corriendo 24/7 en Railway
- ✅ Tendrás una base de datos PostgreSQL persistente
- ✅ Tu ESP32 podrá enviar datos desde China
- ✅ Tu app Flutter podrá leer datos desde México

---

## 📝 URLs Importantes

Anota aquí tus URLs una vez generadas:

- **Backend Railway:** `https://_____________________.up.railway.app`
- **API Docs:** `https://_____________________.up.railway.app/docs`
- **WebSocket:** `wss://_____________________.up.railway.app/ws/connect`
- **GitHub Repo:** `https://github.com/strix2579/InvernaderoIA`

---

**Última actualización:** 30 de Noviembre, 2025
**Versión del Backend:** 1.0.0 (con PostgreSQL)
