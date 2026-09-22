import 'package:dio/dio.dart';
import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/user_model.dart';

class AuthResult {
  final UserModel user;
  final String token;
  const AuthResult({required this.user, required this.token});
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiService _api;

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await _api.client.post('/auth/register', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    });
    return _parseAuthResult(response.data);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _parseAuthResult(response.data);
  }

  Future<UserModel?> me() async {
    try {
      final response = await _api.client.get('/auth/me');
      final data = response.data['data']['user'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException {
      return null;
    }
  }

  AuthResult _parseAuthResult(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    return AuthResult(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }
}