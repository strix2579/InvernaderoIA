import '../entities/alert.dart';

abstract class AlertRepository {
  Stream<List<Alert>> getAlertsStream();
  Future<List<Alert>> getAlerts();
  Future<void> markAsRead(String alertId);
  Future<void> clearAll();
}
