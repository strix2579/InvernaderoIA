import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/websocket_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/api_greenhouse_repository.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/greenhouse_repository.dart';
import '../../domain/repositories/alert_repository.dart';

// Core Clients
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient();
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(apiClient);
});

final greenhouseRepositoryProvider = Provider<GreenhouseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final wsClient = ref.watch(webSocketClientProvider);
  return ApiGreenhouseRepository(apiClient, wsClient);
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final wsClient = ref.watch(webSocketClientProvider);
  return AlertRepositoryImpl(wsClient);
});
