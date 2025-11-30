/**
 * ESP32 Firmware con Sistema de Configuración WiFi
 *
 * Características:
 * - Modo AP para configuración inicial
 * - HTTP Server para recibir credenciales WiFi
 * - Almacenamiento en NVS (Non-Volatile Storage)
 * - mDNS para descubrimiento en red local
 * - WebSocket para comunicación con backend
 * - Comunicación serial con Arduino Mega
 */

#include <ArduinoJson.h>
#include <ESPmDNS.h>
#include <Preferences.h>
#include <WebServer.h>
#include <WebSocketsClient.h>
#include <WiFi.h>

// ============================================================================
// CONFIGURACIÓN Y CONSTANTES
// ============================================================================

#define SERIAL_BAUD 115200
#define MEGA_BAUD 115200 // Cambiado a 115200 para mayor confiabilidad
#define RXD2 16
#define TXD2 17

// Configuración del Access Point
#define AP_SSID_PREFIX "GreenTech-"
#define AP_PASSWORD "greenhouse123" // Opcional, puede ser abierto
#define AP_IP IPAddress(192, 168, 4, 1)
#define AP_GATEWAY IPAddress(192, 168, 4, 1)
#define AP_SUBNET IPAddress(255, 255, 255, 0)

// Timeouts y reintentos
#define WIFI_CONNECT_TIMEOUT 10000
#define WIFI_MAX_RETRIES 5
#define HEARTBEAT_INTERVAL 30000
#define SENSOR_INTERVAL 2000

// ============================================================================
// VARIABLES GLOBALES
// ============================================================================

enum DeviceState {
  STATE_AP_MODE,
  STATE_CONNECTING,
  STATE_ONLINE,
  STATE_AP_FALLBACK
};

DeviceState currentState = STATE_AP_MODE;
String deviceId;
String apSSID;

// Almacenamiento persistente
Preferences preferences;

// Servidores y clientes
WebServer server(80);
WebSocketsClient webSocket;

// Credenciales WiFi
String wifiSSID = "";
String wifiPassword = "";
String userToken = "";

// Datos de sensores (recibidos del Mega)
float temp = 0.0;
float hum = 0.0;
float soil1 = 0.0;
float soil2 = 0.0;
int mq2 = 0;
int mq5 = 0;
int mq8 = 0;
int aqi = 0;
int water1 = 0;
int water2 = 0;
String alarmState = "DISARMED";
bool alarmTriggered = false;

// Timers
unsigned long lastHeartbeat = 0;
unsigned long lastSensorUpdate = 0;
int wifiRetries = 0;

String megaBuffer = "";

// Prototipos de funciones (para evitar errores de orden)
void startHTTPServer();
void connectToBackend();
void webSocketEvent(WStype_t type, uint8_t *payload, size_t length);
void handleWebSocketMessage(char *message);
void sendDeviceInfo();
void sendAck(const char *msgId);
void sendHeartbeat();
void sendSensorUpdate();

// ============================================================================
// FUNCIONES DE UTILIDAD
// ============================================================================

String getDeviceId() {
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char id[9];
  sprintf(id, "%02X%02X%02X%02X", mac[2], mac[3], mac[4], mac[5]);
  return String(id);
}

String getMacAddress() {
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char macStr[18];
  sprintf(macStr, "%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2],
          mac[3], mac[4], mac[5]);
  return String(macStr);
}

// ============================================================================
// ALMACENAMIENTO NVS
// ============================================================================

void loadCredentials() {
  preferences.begin("greenhouse", false);
  wifiSSID = preferences.getString("wifi_ssid", "");
  wifiPassword = preferences.getString("wifi_pass", "");
  userToken = preferences.getString("user_token", "");
  preferences.end();

  Serial.println("Credenciales cargadas:");
  Serial.println("  SSID: " +
                 (wifiSSID.length() > 0 ? wifiSSID : String("(vacío)")));
  Serial.println("  Token: " +
                 (userToken.length() > 0 ? String("***") : String("(vacío)")));
}

void saveCredentials(String ssid, String pass, String token) {
  preferences.begin("greenhouse", false);
  preferences.putString("wifi_ssid", ssid);
  preferences.putString("wifi_pass", pass);
  preferences.putString("user_token", token);
  preferences.end();

  Serial.println("Credenciales guardadas en NVS");
}

void clearCredentials() {
  preferences.begin("greenhouse", false);
  preferences.clear();
  preferences.end();

  wifiSSID = "";
  wifiPassword = "";
  userToken = "";

  Serial.println("Credenciales borradas");
}

// ============================================================================
// MODO ACCESS POINT
// ============================================================================

void startAccessPoint() {
  Serial.println("\n=== INICIANDO MODO ACCESS POINT ===");

  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(AP_IP, AP_GATEWAY, AP_SUBNET);
  WiFi.softAP(apSSID.c_str(), AP_PASSWORD);

  Serial.println("Access Point iniciado:");
  Serial.println("  SSID: " + apSSID);
  Serial.println("  IP: " + WiFi.softAPIP().toString());
  Serial.println("  Password: " + String(AP_PASSWORD));

  currentState = STATE_AP_MODE;
  startHTTPServer();
}

// ============================================================================
// SERVIDOR HTTP (MODO AP)
// ============================================================================

void handleStatus() {
  DynamicJsonDocument doc(512);

  doc["state"] = currentState == STATE_AP_MODE       ? "ap_mode"
                 : currentState == STATE_ONLINE      ? "online"
                 : currentState == STATE_AP_FALLBACK ? "ap_fallback"
                                                     : "connecting";
  doc["device_id"] = deviceId;
  doc["mac"] = getMacAddress();

  if (currentState == STATE_ONLINE) {
    doc["ip"] = WiFi.localIP().toString();
    doc["ssid"] = WiFi.SSID();
  }

  String response;
  serializeJson(doc, response);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", response);

  Serial.println("GET /status - Respondido");
}

void handleConfigure() {
  if (server.method() == HTTP_OPTIONS) {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
    server.send(204);
    return;
  }

  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"error\":\"No body\"}");
    return;
  }

  String body = server.arg("plain");
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, body);

  if (error) {
    server.send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
    return;
  }

  String ssid = doc["wifi_ssid"] | "";
  String pass = doc["wifi_password"] | "";
  String token = doc["user_token"] | "";

  if (ssid.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"wifi_ssid required\"}");
    return;
  }

  Serial.println("\n=== CONFIGURACIÓN RECIBIDA ===");
  Serial.println("  SSID: " + ssid);
  Serial.println("  Token: " +
                 (token.length() > 0 ? String("***") : String("(vacío)")));

  saveCredentials(ssid, pass, token);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", "{\"ok\":true}");

  Serial.println("Reiniciando en 2 segundos...");
  delay(2000);
  ESP.restart();
}

void handleNetworks() {
  Serial.println("Escaneando redes WiFi...");

  int n = WiFi.scanNetworks();
  DynamicJsonDocument doc(2048);
  JsonArray networks = doc.createNestedArray("networks");

  for (int i = 0; i < n; i++) {
    JsonObject net = networks.createNestedObject();
    net["ssid"] = WiFi.SSID(i);
    net["rssi"] = WiFi.RSSI(i);
    net["encryption"] =
        (WiFi.encryptionType(i) == WIFI_AUTH_OPEN) ? "open" : "encrypted";
  }

  String response;
  serializeJson(doc, response);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", response);

  Serial.println("Scan completado: " + String(n) + " redes encontradas");
}

void handleRoot() {
  String html = R"(
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GreenTech - Configuración</title>
  <style>
    body { font-family: Arial; max-width: 500px; margin: 50px auto; padding: 20px; }
    h1 { color: #10B981; }
    input, select { width: 100%; padding: 10px; margin: 10px 0; }
    button { background: #10B981; color: white; padding: 12px; border: none; width: 100%; cursor: pointer; }
    button:hover { background: #059669; }
    .info { background: #E0F2FE; padding: 10px; border-radius: 5px; margin: 10px 0; }
  </style>
</head>
<body>
  <h1>🌱 GreenTech IoT</h1>
  <div class="info">
    <strong>Device ID:</strong> )";
  html += deviceId;
  html += R"(<br>
    <strong>MAC:</strong> )";
  html += getMacAddress();
  html += R"(
  </div>
  <h2>Configuración WiFi</h2>
  <form id="configForm">
    <label>Red WiFi (Escribe el nombre o espera a que cargue la lista):</label>
    <input type="text" id="ssid" list="netlist" required placeholder="Nombre de tu WiFi...">
    <datalist id="netlist"></datalist>
    
    <label>Contraseña:</label>
    <input type="password" id="password" required>
    <label>Token de Usuario (opcional):</label>
    <input type="text" id="token">
    <button type="submit">Configurar</button>
  </form>
  <script>
    fetch('/networks').then(r => r.json()).then(data => {
      const list = document.getElementById('netlist');
      data.networks.forEach(net => {
        const opt = document.createElement('option');
        opt.value = net.ssid;
        list.appendChild(opt);
      });
    }).catch(e => console.log('Error escaneando:', e));
    
    document.getElementById('configForm').onsubmit = async (e) => {
      e.preventDefault();
      const data = {
        wifi_ssid: document.getElementById('ssid').value,
        wifi_password: document.getElementById('password').value,
        user_token: document.getElementById('token').value
      };
      const res = await fetch('/configure', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(data)
      });
      if (res.ok) {
        alert('Configuración guardada. El dispositivo se reiniciará.');
      } else {
        alert('Error al configurar');
      }
    };
  </script>
</body>
</html>
  )";

  server.send(200, "text/html", html);
}

void startHTTPServer() {
  server.on("/", handleRoot);
  server.on("/status", handleStatus);
  server.on("/configure", handleConfigure);
  server.on("/networks", handleNetworks);

  server.begin();
  Serial.println("Servidor HTTP iniciado en puerto 80");
}

// ============================================================================
// MODO STATION (CONECTADO A WIFI)
// ============================================================================

bool connectToWiFi() {
  Serial.println("\n=== CONECTANDO A WIFI ===");
  Serial.println("  SSID: " + wifiSSID);

  currentState = STATE_CONNECTING;
  WiFi.mode(WIFI_STA);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());

  unsigned long startTime = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - startTime > WIFI_CONNECT_TIMEOUT) {
      Serial.println("Timeout conectando a WiFi");
      return false;
    }
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n¡WiFi conectado!");
  Serial.println("  IP: " + WiFi.localIP().toString());

  currentState = STATE_ONLINE;
  wifiRetries = 0;

  // Iniciar mDNS
  String mdnsName = "greentech-" + deviceId;
  mdnsName.toLowerCase();
  if (MDNS.begin(mdnsName.c_str())) {
    Serial.println("  mDNS: " + mdnsName + ".local");
    MDNS.addService("http", "tcp", 80);
  }

  // Iniciar servidor HTTP en modo online
  startHTTPServer();

  // Conectar a WebSocket del backend
  connectToBackend();

  return true;
}

void connectToBackend() {
  // TODO: Obtener la IP del backend desde configuración o descubrimiento
  const char *ws_server = "192.168.100.2"; // IP detectada automáticamente
  const int ws_port = 8080;
  // Simplificamos el path para evitar problemas de parsing en la librería
  const String ws_path = "/ws/connect";

  Serial.println("Conectando a WebSocket backend...");
  webSocket.begin(ws_server, ws_port, ws_path);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);

  // Enviar token si existe
  if (userToken.length() > 0) {
    webSocket.setAuthorization(userToken.c_str());
  }
}

// ============================================================================
// WEBSOCKET
// ============================================================================

void webSocketEvent(WStype_t type, uint8_t *payload, size_t length) {
  switch (type) {
  case WStype_DISCONNECTED:
    Serial.println("[WS] ❌ DESCONECTADO");
    Serial.println(
        "     Causa: La conexión no se pudo establecer o se perdió.");
    Serial.println("     Reintentando en 5 segundos...");
    break;

  case WStype_CONNECTED:
    Serial.printf("[WS] ✅ CONECTADO EXITOSAMENTE a: %s\n", payload);
    Serial.println("[WS] Enviando información del dispositivo...");
    sendDeviceInfo();
    break;

  case WStype_TEXT:
    Serial.printf("[WS] 📨 Mensaje recibido: %s\n", payload);
    handleWebSocketMessage((char *)payload);
    break;

  case WStype_ERROR:
    Serial.printf("[WS] ⚠️ ERROR: %s\n", payload);
    break;

  default:
    Serial.printf("[WS] Evento desconocido: %d\n", type);
    break;
  }
}

void handleWebSocketMessage(char *message) {
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, message);

  if (error) {
    Serial.println("Error parseando mensaje WS");
    return;
  }

  const char *type = doc["type"];

  if (strcmp(type, "COMMAND") == 0) {
    const char *actuator = doc["payload"]["actuator"];
    const char *action = doc["payload"]["action"];

    Serial.printf("Comando recibido: %s -> %s\n", actuator, action);

    // Mapear a comandos del Mega
    String cmd = "";
    String val = (strcmp(action, "ON") == 0) ? "1" : "0";

    if (strcmp(actuator, "fan") == 0)
      cmd = "VENT:" + val;
    else if (strcmp(actuator, "pump1") == 0)
      cmd = "B1:" + val;
    else if (strcmp(actuator, "pump2") == 0)
      cmd = "B2:" + val;
    else if (strcmp(actuator, "lights") == 0)
      cmd = "UVA:" + val;
    else if (strcmp(actuator, "extractors") == 0)
      cmd = "E:" + val;
    else if (strcmp(actuator, "door") == 0)
      cmd = "PUERTA:" + String(strcmp(action, "OPEN") == 0 ? "OPEN" : "CLOSE");

    if (cmd != "") {
      Serial2.println(cmd);
      Serial.println("Enviado a Mega: " + cmd);
      sendAck("command_received");
    }
  }
}

void sendDeviceInfo() {
  DynamicJsonDocument doc(512);
  doc["type"] = "DEVICE_INFO";
  doc["device_id"] = deviceId;
  doc["mac"] = getMacAddress();
  doc["ip"] = WiFi.localIP().toString();
  doc["firmware_version"] = "1.0.0";

  String output;
  serializeJson(doc, output);
  webSocket.sendTXT(output);
}

void sendAck(const char *msgId) {
  DynamicJsonDocument doc(256);
  doc["type"] = "ack";
  doc["message_id"] = msgId;

  String output;
  serializeJson(doc, output);
  webSocket.sendTXT(output);
}

void sendHeartbeat() {
  DynamicJsonDocument doc(256);
  doc["type"] = "heartbeat";
  doc["device_id"] = deviceId;

  String output;
  serializeJson(doc, output);
  webSocket.sendTXT(output);
}

void sendSensorUpdate() {
  DynamicJsonDocument doc(1024);
  doc["type"] = "TELEMETRY";
  doc["device_id"] = deviceId;

  JsonObject payload = doc.createNestedObject("payload");
  payload["temp"] = temp;
  payload["hum"] = hum;

  JsonArray soil = payload.createNestedArray("soil_moisture");
  soil.add(soil1);
  soil.add(soil2);

  JsonArray water = payload.createNestedArray("water_level");
  water.add(water1);
  water.add(water2);

  JsonObject gas = payload.createNestedObject("gas");
  gas["mq2"] = mq2;
  gas["mq5"] = mq5;
  gas["mq8"] = mq8;
  gas["aqi"] = aqi;

  JsonObject alarm = payload.createNestedObject("alarm");
  alarm["state"] = alarmState;
  alarm["triggered"] = alarmTriggered;

  String output;
  serializeJson(doc, output);
  webSocket.sendTXT(output);
}

// ============================================================================
// COMUNICACIÓN CON ARDUINO MEGA
// ============================================================================

void parseMegaData(String line) {
  int start = 0;
  int end = line.indexOf(';');

  while (end != -1) {
    String token = line.substring(start, end);
    int sep = token.indexOf(':');

    if (sep > 0) {
      String key = token.substring(0, sep);
      String val = token.substring(sep + 1);

      if (key == "TEMP")
        temp = val.toFloat();
      else if (key == "HUM")
        hum = val.toFloat();
      else if (key == "MQ2")
        mq2 = val.toInt();
      else if (key == "MQ5")
        mq5 = val.toInt();
      else if (key == "MQ8")
        mq8 = val.toInt();
      else if (key == "AQI")
        aqi = val.toInt();
      else if (key == "SOIL1")
        soil1 = val.toFloat();
      else if (key == "SOIL2")
        soil2 = val.toFloat();
      else if (key == "W1")
        water1 = val.toInt();
      else if (key == "W2")
        water2 = val.toInt();
      else if (key == "ALARM")
        alarmState = val;
      else if (key == "TRIG")
        alarmTriggered = (val == "TRUE");
    }

    start = end + 1;
    end = line.indexOf(';', start);
  }

  // DEBUG: Mostrar valores parseados
  Serial.printf("[PARSED] T:%.1f H:%.1f W1:%d W2:%d AQI:%d\n", temp, hum,
                water1, water2, aqi);
}

// ============================================================================
// SETUP
// ============================================================================

void setup() {
  Serial.begin(SERIAL_BAUD);
  Serial2.begin(MEGA_BAUD, SERIAL_8N1, RXD2, TXD2);

  delay(1000);
  Serial.println("\n\n=================================");
  Serial.println("  ESP32 GreenTech IoT Firmware");
  Serial.println("=================================\n");

  // Generar Device ID
  deviceId = getDeviceId();
  apSSID = String(AP_SSID_PREFIX) + deviceId;

  Serial.println("Device ID: " + deviceId);
  Serial.println("AP SSID: " + apSSID);

  // Cargar credenciales guardadas
  loadCredentials();

  // Decidir modo de operación
  if (wifiSSID.length() > 0) {
    Serial.println("\nCredenciales encontradas, intentando conectar...");

    if (connectToWiFi()) {
      Serial.println("Modo ONLINE activado");
    } else {
      wifiRetries++;

      if (wifiRetries >= WIFI_MAX_RETRIES) {
        Serial.println("Máximo de reintentos alcanzado");
        Serial.println("Borrando credenciales y entrando en modo AP");
        clearCredentials();
        currentState = STATE_AP_FALLBACK;
        startAccessPoint();
      } else {
        Serial.println("Reintentando en 5 segundos...");
        delay(5000);
        ESP.restart();
      }
    }
  } else {
    Serial.println("\nNo hay credenciales guardadas");
    startAccessPoint();
  }
}

// ============================================================================
// LOOP
// ============================================================================

void loop() {
  // Manejar servidor HTTP
  server.handleClient();

  // Si estamos online, manejar WebSocket
  if (currentState == STATE_ONLINE) {
    webSocket.loop();

    // Heartbeat
    unsigned long now = millis();
    if (now - lastHeartbeat > HEARTBEAT_INTERVAL) {
      sendHeartbeat();
      lastHeartbeat = now;
    }

    // Actualización de sensores
    if (now - lastSensorUpdate > SENSOR_INTERVAL) {
      sendSensorUpdate();
      lastSensorUpdate = now;
    }

    // Verificar conexión WiFi
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("WiFi desconectado, reintentando...");
      wifiRetries++;

      if (wifiRetries >= WIFI_MAX_RETRIES) {
        Serial.println("Demasiados fallos, volviendo a modo AP");
        clearCredentials();
        ESP.restart();
      } else {
        delay(5000);
        ESP.restart();
      }
    }
  }

  // Leer datos del Mega
  while (Serial2.available()) {
    char c = (char)Serial2.read();
    if (c == '\n') {
      megaBuffer.trim();
      if (megaBuffer.length() > 0) {
        Serial.println("[MEGA] " +
                       megaBuffer); // DEBUG: Mostrar datos recibidos
        parseMegaData(megaBuffer);
      }
      megaBuffer = "";
    } else if (c != '\r') {
      megaBuffer += c;
    }
  }
}
