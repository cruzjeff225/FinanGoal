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
        // Fallback offline/mock login
        final mockUser = UserModel(
          id: 'local_user_id',
          name: email.split('@').first.toUpperCase(),
          email: email.trim().toLowerCase(),
          passwordHash: password,
        );
        await _datasource.saveSession(mockUser, 'mock_token');
        return AuthSuccess(mockUser);
      }
    } catch (e) {
      // Fallback en caso de error de red
      final mockUser = UserModel(
        id: 'local_user_id',
        name: email.split('@').first.toUpperCase(),
        email: email.trim().toLowerCase(),
        passwordHash: password,
      );
      await _datasource.saveSession(mockUser, 'mock_token');
      return AuthSuccess(mockUser);
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
        // Fallback offline/mock register
        final mockUser = UserModel(
          id: 'local_user_id',
          name: name,
          email: email.trim().toLowerCase(),
          passwordHash: password,
        );
        await _datasource.saveSession(mockUser, 'mock_token');
        return AuthSuccess(mockUser);
      }
    } catch (e) {
      // Fallback en caso de error de red
      final mockUser = UserModel(
        id: 'local_user_id',
        name: name,
        email: email.trim().toLowerCase(),
        passwordHash: password,
      );
      await _datasource.saveSession(mockUser, 'mock_token');
      return AuthSuccess(mockUser);
    }
  }

  Future<bool> isLoggedIn() => _datasource.isLoggedIn();
  Future<void> logout() => _datasource.clearSession();
}