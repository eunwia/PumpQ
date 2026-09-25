import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/features/auth/data/auth_repository.dart';
import 'package:pumpq/models/user_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isLoggedIn => user != null;
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repo;
  late final ApiService _api;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    _api = ref.watch(apiServiceProvider);
    _tryRestoreSession();
    return const AuthState();
  }

  Future<void> _tryRestoreSession() async {
    final token = await _api.readToken();
    if (token == null) return;
    state = state.copyWith(isLoading: true);
    final user = await _repo.me();
    state = AuthState(user: user, isLoading: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.login(email: email, password: password);
      await _api.saveToken(result.token);
      state = AuthState(user: result.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _readableError(e));
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      await _api.saveToken(result.token);
      state = AuthState(user: result.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _readableError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState();
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      final user = await _repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(user: user);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _readableError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Check your connection.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'The server took too long to respond.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);