import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';

enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  error,
}

class WebSocketClient {
  WebSocketChannel? _channel;
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;
  String? _accessToken;
  
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  WebSocketStatus _currentStatus = WebSocketStatus.disconnected;
  
  WebSocketStatus get currentStatus => _currentStatus;
  
  void setAccessToken(String token) {
    _accessToken = token;
  }
  
  void connect(String endpoint) {
    if (_currentStatus == WebSocketStatus.connected || 
        _currentStatus == WebSocketStatus.connecting) {
      return;
    }
    
    _updateStatus(WebSocketStatus.connecting);
    
    try {
      final uri = Uri.parse('${AppConstants.wsBaseUrl}$endpoint');
      final uriWithToken = _accessToken != null
          ? uri.replace(queryParameters: {'token': _accessToken})
          : uri;
      
      _channel = WebSocketChannel.connect(uriWithToken);
      
      _channel!.stream.listen(
        (data) {
          _updateStatus(WebSocketStatus.connected);
          _handleMessage(data);
        },
        onError: (error) {
          _updateStatus(WebSocketStatus.error);
          _attemptReconnect(endpoint);
        },
        onDone: () {
          _updateStatus(WebSocketStatus.disconnected);
          _attemptReconnect(endpoint);
        },
      );
    } catch (e) {
      _updateStatus(WebSocketStatus.error);
      _attemptReconnect(endpoint);
    }
  }
  
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data as String);
      _dataController.add(message);
    } catch (e) {
      // Invalid JSON, ignore
    }
  }
  
  void _attemptReconnect(String endpoint) {
    if (!_shouldReconnect) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(AppConstants.wsReconnectDelay, () {
      connect(endpoint);
    });
  }
  
  void send(Map<String, dynamic> data) {
    if (_currentStatus == WebSocketStatus.connected) {
      _channel?.sink.add(jsonEncode(data));
    }
  }
  
  void _updateStatus(WebSocketStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }
  
  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _updateStatus(WebSocketStatus.disconnected);
  }
  
  void dispose() {
    disconnect();
    _statusController.close();
    _dataController.close();
  }
}
