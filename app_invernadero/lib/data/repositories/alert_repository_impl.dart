import 'dart:async';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../core/network/websocket_client.dart';

class AlertRepositoryImpl implements AlertRepository {
  final WebSocketClient _wsClient;
  final _alertsController = StreamController<List<Alert>>.broadcast();
  final List<Alert> _alerts = [];
  
  AlertRepositoryImpl(this._wsClient) {
    _setupWebSocketListeners();
  }
  
  void _setupWebSocketListeners() {
    _wsClient.dataStream.listen((data) {
      final eventType = data['event'] as String?;
      
      if (eventType == 'alert' || eventType == 'ai_suggestion') {
        final alertData = data['data'] as Map<String, dynamic>;
        final alert = Alert.fromJson(alertData);
        
        _alerts.insert(0, alert); // Add to beginning
        _alertsController.add(List.from(_alerts));
      }
    });
  }
  
  @override
  Stream<List<Alert>> getAlertsStream() {
    return _alertsController.stream;
  }
  
  @override
  Future<List<Alert>> getAlerts() async {
    return List.from(_alerts);
  }
  
  @override
  Future<void> markAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      _alertsController.add(List.from(_alerts));
    }
  }
  
  @override
  Future<void> clearAll() async {
    _alerts.clear();
    _alertsController.add([]);
  }
  
  void dispose() {
    _alertsController.close();
  }
}
