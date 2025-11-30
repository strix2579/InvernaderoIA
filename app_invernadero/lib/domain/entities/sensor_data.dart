class SensorData {
  final String sensorId;
  final String type; // 'temperature', 'humidity', 'light', 'soil_moisture'
  final double value;
  final String unit;
  final DateTime timestamp;
  
  SensorData({
    required this.sensorId,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
  
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      sensorId: json['sensor_id'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'sensor_id': sensorId,
      'type': type,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
