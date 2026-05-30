import 'package:finan_goal/core/services/api_service.dart';
import 'package:finan_goal/features/auth/data/auth_local_datasource.dart';
import 'package:finan_goal/features/auth/domain/models/user_model.dart';

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  final UserModel user;
  const AuthSuccess(this.user);
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

class AuthRepository {
  final AuthLocalDatasource _datasource;

  AuthRepository(this._datasource);

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await ApiService.login(email.trim().toLowerCase(), password);

      if (response.containsKey('token')) {
        final user = UserModel(
          id: response['user']['id'],
          name: response['user']['name'],
          email: response['user']['email'],
          passwordHash: '',
        );
        await _datasource.saveSession(user, response['token']);
        return AuthSuccess(user);
      } else {
        return AuthFailure(response['message'] ?? 'Error al iniciar sesión.');
      }
    } catch (e) {
      return const AuthFailure('Error de conexión. Verifica tu red.');
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.register(name, email.trim().toLowerCase(), password);

      if (response.containsKey('token')) {
        final user = UserModel(
          id: response['user']['id'],
          name: response['user']['name'],
          email: response['user']['email'],
          passwordHash: '',
        );
        await _datasource.saveSession(user, response['token']);
        return AuthSuccess(user);
      } else {
        return AuthFailure(response['message'] ?? 'Error al registrarte.');
      }
    } catch (e) {
      return const AuthFailure('Error de conexión. Verifica tu red.');
    }
  }

  Future<bool> isLoggedIn() => _datasource.isLoggedIn();
  Future<void> logout() => _datasource.clearSession();
}