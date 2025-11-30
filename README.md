# InvernaderoIA 🌿🤖

Sistema de gestión de invernaderos inteligente con IA, IoT y Flutter.

## 🚀 Arquitectura
- **Backend:** Python FastAPI + TensorFlow (Nymbria) + PostgreSQL
- **Frontend:** Flutter (Web & Mobile)
- **Firmware:** ESP32 + Arduino MEGA

## 📂 Estructura del Proyecto
- `api/`: Backend FastAPI y lógica de IA.
- `app_invernadero/`: Aplicación Flutter.
- `firmware/`: Código para ESP32 y Arduino MEGA.
- `modelos/`: Archivos del modelo de IA (Nymbria.keras).
- `scripts/`: Scripts de utilidad y entrenamiento.

## 🛠️ Despliegue

### 1. Backend (Railway)
El backend está listo para **Railway.app**.
- Incluye `Procfile`, `runtime.txt` y `requirements.txt` actualizados.
- Soporte nativo para PostgreSQL (configurado en `api/database.py`).

**Pasos:**
1. Sube este repositorio a GitHub.
2. En Railway, crea un nuevo proyecto desde GitHub.
3. Añade un servicio de base de datos **PostgreSQL**.
4. Railway inyectará automáticamente la variable `DATABASE_URL`.

### 2. Frontend (Flutter Web)
Para desplegar en GitHub Pages:
```bash
cd app_invernadero
flutter build web --base-href "/InvernaderoIA/"
# Luego subir el contenido de build/web a la rama gh-pages
```

### 3. Firmware (ESP32)
Configurar la URL del backend desplegado en `firmware/esp32_config_firmware.ino`:
```cpp
const char* websocket_server_host = "tu-proyecto.up.railway.app";
```

## 🧠 IA (Nymbria)
El modelo detecta:
- Incendios 🔥
- Fugas de Gas 💨
- Fallas Eléctricas ⚡
- Plagas 🐛
