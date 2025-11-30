import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/iot_device.dart';

/// Servicio para configurar dispositivos IoT ESP32
class DeviceConfigService {
  static const String defaultAPIP = '192.168.4.1';
  static const Duration timeout = Duration(seconds: 10);

  /// Obtiene el estado del dispositivo
  Future<IoTDevice> getDeviceStatus(String ip) async {
    try {
      final response = await http
          .get(
            Uri.parse('http://$ip/status'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return IoTDevice.fromJson(data);
      } else {
        throw Exception('Error al obtener estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar al dispositivo: $e');
    }
  }

  /// Obtiene las redes WiFi disponibles escaneadas por el dispositivo
  Future<List<WiFiNetwork>> getAvailableNetworks(String ip) async {
    try {
      final response = await http
          .get(
            Uri.parse('http://$ip/networks'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final networks = data['networks'] as List;
        return networks
            .map((n) => WiFiNetwork.fromJson(n as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al escanear redes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo obtener redes: $e');
    }
  }

  /// Envía la configuración WiFi al dispositivo
  Future<bool> configureDevice(
    String ip,
    DeviceConfiguration config,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('http://$ip/configure'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(config.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['ok'] == true;
      } else {
        throw Exception('Error al configurar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo configurar el dispositivo: $e');
    }
  }

  /// Intenta descubrir el dispositivo en la red local usando mDNS
  /// Nota: Requiere el paquete multicast_dns
  Future<String?> discoverDeviceIP(String deviceId) async {
    // TODO: Implementar descubrimiento mDNS
    // Por ahora, retorna null y se debe buscar manualmente
    return null;
  }

  /// Verifica si el dispositivo está accesible en una IP específica
  Future<bool> isDeviceReachable(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Escanea un rango de IPs en la red local para encontrar el dispositivo
  /// Útil después de que el dispositivo se conecte al WiFi
  Future<String?> scanLocalNetwork(
    String baseIP,
    String deviceId,
  ) async {
    // Extraer los primeros 3 octetos (ej: 192.168.1)
    final parts = baseIP.split('.');
    if (parts.length != 4) return null;

    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    // Escanear IPs del 1 al 254
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      try {
        final device = await getDeviceStatus(ip);
        if (device.deviceId == deviceId) {
          return ip;
        }
      } catch (e) {
        // Continuar con la siguiente IP
        continue;
      }
    }

    return null;
  }
}
