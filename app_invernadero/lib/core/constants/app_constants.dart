class AppConstants {
  // API Configuration
  // API Configuration
  // TODO: Reemplazar con la URL de tu proyecto en Railway (ej: https://invernadero-production.up.railway.app)
  static const String apiBaseUrl = 'http://localhost:8000'; 
  static const String wsBaseUrl = 'ws://localhost:8000';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String googleLoginEndpoint = '/auth/google';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String meEndpoint = '/auth/me';
  static const String sensorsEndpoint = '/api/sensores';
  static const String historyEndpoint = '/api/historial';
  static const String controlEndpoint = '/api/control';
  static const String configEndpoint = '/api/configuracion';
  static const String depositosEndpoint = '/api/depositos';
  
  // WebSocket Endpoints
  static const String wsRealtimeEndpoint = '/ws/connect';
  static const String wsEventsEndpoint = '/ws/events';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  
  // Chart Configuration
  static const int maxDataPoints = 50;
  static const Duration chartUpdateInterval = Duration(seconds: 2);
}
