import '../entities/sensor_data.dart';
import '../entities/control_command.dart';

abstract class GreenhouseRepository {
  // Real-time data stream
  Stream<List<SensorData>> getSensorDataStream();
  
  // Historical data
  Future<List<SensorData>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
    String? sensorType,
  });
  
  // Control
  Future<void> sendControlCommand(ControlCommand command);
  
  // Connection status
  Stream<ConnectionStatus> getConnectionStatus();
  Future<void> connect();
  Future<void> disconnect();
}

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
}
