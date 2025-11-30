#include <ArduinoJson.h>
#include <WebSocketsClient.h>
#include <WiFi.h>

const char *ssid = "YOUR_WIFI_SSID";
const char *password = "YOUR_WIFI_PASSWORD";
const char *ws_server = "192.168.1.100"; // Replace with your API IP
const int ws_port = 8001;
const char *ws_path = "/ws/connect";

WebSocketsClient webSocket;
unsigned long lastHeartbeat = 0;
unsigned long lastSensorUpdate = 0;
const unsigned long heartbeatInterval = 30000; // 30 seconds
const unsigned long sensorInterval =
    2000; // 2 seconds (faster for real-time feel)

// Real sensor values (received from Mega)
float temp = 0.0;
float hum = 0.0;
float soil1 = 0.0;
float soil2 = 0.0;
int mq2 = 0;
int mq5 = 0;
int mq8 = 0;
int aqi = 0;

// Hardware Serial for Mega connection (RX=16, TX=17 on many ESP32 boards)
#define RXD2 16
#define TXD2 17

void webSocketEvent(WStype_t type, uint8_t *payload, size_t length) {
  switch (type) {
  case WStype_DISCONNECTED:
    Serial.println("[WSc] Disconnected!");
    break;
  case WStype_CONNECTED:
    Serial.printf("[WSc] Connected to url: %s\n", payload);
    break;
  case WStype_TEXT:
    Serial.printf("[WSc] get text: %s\n", payload);
    handleMessage((char *)payload);
    break;
  case WStype_BIN:
  case WStype_ERROR:
  case WStype_FRAGMENT_TEXT_START:
  case WStype_FRAGMENT_BIN_START:
  case WStype_FRAGMENT:
  case WStype_FRAGMENT_FIN:
    break;
  }
}

void handleMessage(char *message) {
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, message);

  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.f_str());
    return;
  }

  const char *type = doc["type"];

  // Unified Protocol: COMMAND
  if (strcmp(type, "COMMAND") == 0) {
    const char *actuator = doc["payload"]["actuator"];
    const char *action = doc["payload"]["action"];
    // int duration = doc["payload"]["duration"]; // Not used yet in Mega
    // protocol

    Serial.printf("COMMAND RECEIVED: %s -> %s\n", actuator, action);

    // Forward to Mega via Serial2
    // Mapping API commands to Mega protocol (KEY:VAL)
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
    else if (strcmp(actuator, "door") == 0)
      cmd = "PUERTA:" + String(strcmp(action, "OPEN") == 0 ? "OPEN" : "CLOSE");

    if (cmd != "") {
      Serial2.println(cmd);
      Serial.println("Forwarded to Mega: " + cmd);
    }

    sendAck("command_received");
  }
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
  String output;
  serializeJson(doc, output);
  webSocket.sendTXT(output);
}

void sendSensorUpdate() {
  DynamicJsonDocument doc(1024);
  doc["type"] = "TELEMETRY";

  JsonObject payload = doc.createNestedObject("payload");
  payload["temp"] = temp;
  payload["hum"] = hum;

  JsonArray soil = payload.createNestedArray("soil_moisture");
  soil.add(soil1);
  soil.add(soil2);

  JsonObject gas = payload.createNestedObject("gas");
  gas["mq2"] = mq2;
  gas["mq5"] = mq5;
  gas["mq8"] = mq8;
  gas["aqi"] = aqi;

  String output;
  serializeJson(doc, output);
  webSocket.sendTXT(output);
}

// Parse line from Mega: "TEMP:25.50;HUM:60.0;..."
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
    }
    start = end + 1;
    end = line.indexOf(';', start);
  }
}

void setup() {
  Serial.begin(115200);
  // Init Serial2 for Mega communication
  Serial2.begin(9600, SERIAL_8N1, RXD2, TXD2);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");

  webSocket.begin(ws_server, ws_port, ws_path);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
}

String megaBuffer = "";

void loop() {
  webSocket.loop();

  // Read from Mega
  while (Serial2.available()) {
    char c = (char)Serial2.read();
    if (c == '\n') {
      megaBuffer.trim();
      if (megaBuffer.length() > 0) {
        // Serial.println("Mega says: " + megaBuffer); // Debug
        parseMegaData(megaBuffer);
      }
      megaBuffer = "";
    } else if (c != '\r') {
      megaBuffer += c;
    }
  }

  unsigned long now = millis();

  if (now - lastHeartbeat > heartbeatInterval) {
    sendHeartbeat();
    lastHeartbeat = now;
  }

  if (now - lastSensorUpdate > sensorInterval) {
    sendSensorUpdate();
    lastSensorUpdate = now;
  }
}
