class ControlCommand {
  final String deviceId;
  final String action; // 'turn_on', 'turn_off', 'set_value'
  final double? value; // For analog controls (e.g., fan speed, valve position)
  final DateTime timestamp;
  
  ControlCommand({
    required this.deviceId,
    required this.action,
    this.value,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'action': action,
      if (value != null) 'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory ControlCommand.fromJson(Map<String, dynamic> json) {
    return ControlCommand(
      deviceId: json['device_id'] as String,
      action: json['action'] as String,
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
