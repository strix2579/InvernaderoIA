import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/websocket_client.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/control_command.dart';
import '../../domain/repositories/greenhouse_repository.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiGreenhouseRepository implements GreenhouseRepository {
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  final _sensorDataController = StreamController<List<SensorData>>.broadcast();
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  
  List<SensorData> _currentSensorData = [];
  
  ApiGreenhouseRepository(this._apiClient, this._wsClient) {
    _setupWebSocketListeners();
  }
  
  void _setupWebSocketListeners() {
    _wsClient.statusStream.listen((wsStatus) {
      ConnectionStatus status;
      switch (wsStatus) {
        case WebSocketStatus.connected:
          status = ConnectionStatus.connected;
          break;
        case WebSocketStatus.connecting:
          status = ConnectionStatus.connecting;
          break;
        case WebSocketStatus.disconnected:
          status = ConnectionStatus.disconnected;
          break;
        case WebSocketStatus.error:
          status = ConnectionStatus.error;
          break;
      }
      _connectionStatusController.add(status);
    });
    
    _wsClient.dataStream.listen((data) {
      _handleWebSocketMessage(data);
    });
  }
  
  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    if (type == 'STATE_UPDATE') {
      final payload = data['payload'] as Map<String, dynamic>;
      // The payload might contain 'sensors' directly or be the sensors object itself depending on API implementation.
      // Based on the diagnosis, API sends: { "type": "STATE_UPDATE", "payload": { "sensors": {...}, "prediction": {...} } }
      
      if (payload.containsKey('sensors')) {
        final sensors = payload['sensors'] as Map<String, dynamic>;
        _processSensorData(sensors);
      } else {
        // Fallback if payload is directly the sensor data
        _processSensorData(payload);
      }
    } else if (type == 'TELEMETRY') {
       // Direct telemetry update
       final payload = data['payload'] as Map<String, dynamic>;
       _processSensorData(payload);
    }
  }

  void _processSensorData(Map<String, dynamic> sensors) {
    List<SensorData> parsedData = [];
    final timestamp = DateTime.now(); 

    // Temp
    if (sensors.containsKey('temp')) {
      parsedData.add(SensorData(
        sensorId: 'temp_1', 
        type: 'temperature', 
        value: (sensors['temp'] as num).toDouble(), 
        unit: '°C', 
        timestamp: timestamp
      ));
    }
    // Hum
    if (sensors.containsKey('hum')) {
      parsedData.add(SensorData(
        sensorId: 'hum_1', 
        type: 'humidity', 
        value: (sensors['hum'] as num).toDouble(), 
        unit: '%', 
        timestamp: timestamp
      ));
    }
    // CO2
    if (sensors.containsKey('co2')) {
      parsedData.add(SensorData(
        sensorId: 'co2_1', 
        type: 'co2', 
        value: (sensors['co2'] as num).toDouble(), 
        unit: 'ppm', 
        timestamp: timestamp
      ));
    }
    // Gas (AQI)
    if (sensors.containsKey('gas')) {
      final gas = sensors['gas'] as Map<String, dynamic>;
      if (gas.containsKey('aqi')) {
        parsedData.add(SensorData(
          sensorId: 'aqi_1', 
          type: 'aqi', // Match UI expectation
          value: (gas['aqi'] as num).toDouble(), 
          unit: '', 
          timestamp: timestamp
        ));
      }
    }
    // Soil Moisture
    if (sensors.containsKey('soil_moisture')) {
      final soils = sensors['soil_moisture'] as List;
      if (soils.isNotEmpty) {
        parsedData.add(SensorData(
          sensorId: 'soil_a', 
          type: 'soil_moisture_a', 
          value: (soils[0] as num).toDouble(), 
          unit: '%', 
          timestamp: timestamp
        ));
        
        if (soils.length > 1) {
          parsedData.add(SensorData(
            sensorId: 'soil_b', 
            type: 'soil_moisture_b', 
            value: (soils[1] as num).toDouble(), 
            unit: '%', 
            timestamp: timestamp
          ));
        }
      }
    }
    
    _currentSensorData = parsedData;
    _sensorDataController.add(List.from(_currentSensorData));
  }
  
  @override
  Stream<List<SensorData>> getSensorDataStream() {
    return _sensorDataController.stream;
  }
  
  @override
  Future<List<SensorData>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
    String? sensorType,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConstants.historyEndpoint,
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          if (sensorType != null) 'sensor_type': sensorType,
        },
      );
      
      final dataList = response.data['data'] as List;
      return dataList
          .map((json) => SensorData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch historical data: $e');
    }
  }
  
  @override
  Future<void> sendControlCommand(ControlCommand command) async {
    try {
      await _apiClient.post(
        AppConstants.controlEndpoint,
        data: command.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to send control command: $e');
    }
  }
  
  @override
  Stream<ConnectionStatus> getConnectionStatus() {
    return _connectionStatusController.stream;
  }
  
  @override
  Future<void> connect() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      _wsClient.setAccessToken(token);
    }
    _wsClient.connect(AppConstants.wsRealtimeEndpoint);
  }
  
  @override
  Future<void> disconnect() async {
    _wsClient.disconnect();
  }
  
  void dispose() {
    _sensorDataController.close();
    _connectionStatusController.close();
    _wsClient.dispose();
  }
}
