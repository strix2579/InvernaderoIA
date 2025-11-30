/// Modelo para representar un dispositivo ESP32
class IoTDevice {
  final String deviceId;
  final String mac;
  final String state;
  final String? ip;
  final String? ssid;

  IoTDevice({
    required this.deviceId,
    required this.mac,
    required this.state,
    this.ip,
    this.ssid,
  });

  factory IoTDevice.fromJson(Map<String, dynamic> json) {
    return IoTDevice(
      deviceId: json['device_id'] as String,
      mac: json['mac'] as String,
      state: json['state'] as String,
      ip: json['ip'] as String?,
      ssid: json['ssid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'mac': mac,
      'state': state,
      if (ip != null) 'ip': ip,
      if (ssid != null) 'ssid': ssid,
    };
  }

  bool get isInAPMode => state == 'ap_mode' || state == 'ap_fallback';
  bool get isOnline => state == 'online';
  bool get isConnecting => state == 'connecting';
}

/// Modelo para una red WiFi disponible
class WiFiNetwork {
  final String ssid;
  final int rssi;
  final String encryption;

  WiFiNetwork({
    required this.ssid,
    required this.rssi,
    required this.encryption,
  });

  factory WiFiNetwork.fromJson(Map<String, dynamic> json) {
    return WiFiNetwork(
      ssid: json['ssid'] as String,
      rssi: json['rssi'] as int,
      encryption: json['encryption'] as String,
    );
  }

  int get signalStrength {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    return 1;
  }

  bool get isOpen => encryption == 'open';
}

/// Configuración para enviar al dispositivo
class DeviceConfiguration {
  final String wifiSSID;
  final String wifiPassword;
  final String? userToken;

  DeviceConfiguration({
    required this.wifiSSID,
    required this.wifiPassword,
    this.userToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'wifi_ssid': wifiSSID,
      'wifi_password': wifiPassword,
      if (userToken != null) 'user_token': userToken,
    };
  }
}
