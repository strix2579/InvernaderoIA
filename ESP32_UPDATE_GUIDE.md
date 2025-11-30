# 🔧 Script de Actualización del ESP32 para Railway

## Instrucciones Rápidas

Este script te ayudará a actualizar la URL del servidor en el firmware del ESP32.

### **Opción 1: Actualización Manual (Recomendada)**

1. **Abre Arduino IDE**
2. **Abre el archivo:** `firmware/esp32_config_firmware.ino`
3. **Busca la línea 35** (aproximadamente):
   ```cpp
   const char* serverUrl = "ws://192.168.100.2:8080/ws/connect";
   ```

4. **Reemplázala con tu URL de Railway:**
   ```cpp
   const char* serverUrl = "wss://TU-URL-RAILWAY.up.railway.app/ws/connect";
   ```

   **Ejemplo real:**
   ```cpp
   const char* serverUrl = "wss://invernaderoia-production.up.railway.app/ws/connect";
   ```

5. **Guarda el archivo** (Ctrl + S)
6. **Compila y sube al ESP32:**
   - Selecciona el puerto COM correcto
   - Click en "Subir" (→)
   - Espera a que termine

7. **Verifica en el Monitor Serial:**
   - Abre Monitor Serial (Ctrl + Shift + M)
   - Velocidad: 115200 baud
   - Deberías ver: `✓ WebSocket conectado al servidor`

---

### **Opción 2: Usando PowerShell (Avanzado)**

Si prefieres automatizar el cambio, puedes usar este comando de PowerShell:

```powershell
# Reemplaza TU_URL_RAILWAY con tu URL real de Railway
$RAILWAY_URL = "invernaderoia-production.up.railway.app"

# Actualiza el archivo
$file = "firmware\esp32_config_firmware.ino"
$content = Get-Content $file -Raw
$content = $content -replace 'const char\* serverUrl = "ws://[^"]+";', "const char* serverUrl = `"wss://$RAILWAY_URL/ws/connect`";"
Set-Content $file $content

Write-Host "✅ Archivo actualizado. Ahora compila y sube desde Arduino IDE." -ForegroundColor Green
```

---

## ⚠️ Puntos Importantes

1. **Cambio de Protocolo:**
   - Local: `ws://` (WebSocket sin cifrar)
   - Railway: `wss://` (WebSocket con SSL/TLS)

2. **Verificar Conectividad:**
   - El ESP32 debe tener acceso a internet
   - El WiFi debe permitir conexiones salientes HTTPS
   - Algunos firewalls corporativos bloquean WebSockets

3. **Debugging:**
   - Si no conecta, verifica los logs en el Monitor Serial
   - Verifica que la URL esté correcta (sin espacios)
   - Prueba hacer ping a la URL desde tu computadora

---

## 🔍 Verificación Post-Actualización

Después de subir el firmware actualizado:

1. **Monitor Serial debe mostrar:**
   ```
   ========================================
   ESP32 - Sistema de Invernadero v2.0
   ========================================
   
   [WiFi] Conectando a: TU_RED_WIFI
   [WiFi] ✓ Conectado
   [WiFi] IP: 192.168.X.X
   
   [WebSocket] Conectando a: wss://TU-URL.up.railway.app/ws/connect
   [WebSocket] ✓ Conectado al servidor
   ```

2. **En Railway (Logs del Backend):**
   - Ve a tu proyecto en Railway
   - Click en el servicio Backend
   - Pestaña "Deployments" → Ver logs
   - Deberías ver: `WebSocket client connected`

3. **Prueba de Telemetría:**
   - Espera 10 segundos
   - En los logs de Railway deberías ver mensajes de tipo `TELEMETRY`
   - Verifica que los datos se estén guardando en PostgreSQL

---

## 🆘 Solución de Problemas

### **Error: "Connection refused"**
- Verifica que la URL de Railway esté correcta
- Asegúrate de usar `wss://` (no `ws://`)
- Verifica que el servicio esté corriendo en Railway

### **Error: "SSL handshake failed"**
- El ESP32 necesita certificados SSL
- Agrega esta línea antes de `webSocket.begin()`:
  ```cpp
  webSocketClient.setInsecure(); // Para desarrollo
  ```

### **El ESP32 conecta pero no envía datos:**
- Verifica que el Arduino MEGA esté enviando datos por Serial
- Revisa la función `parseMegaData()` en el ESP32
- Verifica los logs del Monitor Serial

---

## 📋 Checklist Final

- [ ] URL de Railway copiada correctamente
- [ ] Archivo `esp32_config_firmware.ino` actualizado
- [ ] Protocolo cambiado de `ws://` a `wss://`
- [ ] Firmware compilado sin errores
- [ ] Firmware subido al ESP32
- [ ] Monitor Serial muestra conexión exitosa
- [ ] Logs de Railway muestran cliente conectado
- [ ] Datos de telemetría llegando a Railway

---

**¡Listo!** Tu ESP32 ahora está conectado a la nube y puede enviar datos desde cualquier parte del mundo.
