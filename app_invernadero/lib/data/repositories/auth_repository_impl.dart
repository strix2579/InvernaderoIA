import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthRepositoryImpl(this._apiClient);
  
  @override
  Future<User> login(String email, String password) async {
    try {
      // API expects username in form data (x-www-form-urlencoded)
      final response = await _apiClient.post(
        AppConstants.loginEndpoint,
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      
      final accessToken = response.data['access_token'] as String;
      
      // Store token
      await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
      
      // Get user info
      _apiClient.setAuthToken(accessToken);
      final userResponse = await _apiClient.get('/auth/me');
      final user = User.fromJson(userResponse.data);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      
      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  @override
  Future<User> register(String username, String email, String password, {String? fullName}) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'full_name': fullName ?? '',
          'role': 'viewer',
        },
      );
      
      final accessToken = response.data['access_token'] as String;
      
      // Store token
      await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
      
      // Get user info
      _apiClient.setAuthToken(accessToken);
      final userResponse = await _apiClient.get('/auth/me');
      final user = User.fromJson(userResponse.data);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      
      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  @override
  Future<User> loginWithGoogle() async {
    try {
      // For web, we'll use a simplified approach
      // In production, configure Google Sign-In properly with OAuth 2.0 credentials
      final mockToken = 'google_${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await _apiClient.post(
        '/auth/google',
        data: {'id_token': mockToken},
      );
      
      final accessToken = response.data['access_token'] as String;
      
      // Store token
      await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
      
      // Get user info
      _apiClient.setAuthToken(accessToken);
      final userResponse = await _apiClient.get('/auth/me');
      final user = User.fromJson(userResponse.data);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      
      return user;
    } catch (e) {
      throw Exception('Google login failed: $e');
    }
  }
  
  @override
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
  }
  
  @override
  Future<User?> getCurrentUser() async {
    try {
      final userId = await _storage.read(key: AppConstants.userIdKey);
      if (userId == null) return null;
      
      final response = await _apiClient.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
  
  @override
  Future<void> refreshToken() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) throw Exception('No refresh token');
    
    final response = await _apiClient.post(
      AppConstants.refreshTokenEndpoint,
      data: {'refresh_token': refreshToken},
    );
    
    final newAccessToken = response.data['access_token'] as String;
    await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
  }
}
