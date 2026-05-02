import 'package:finan_goal/features/auth/data/auth_local_datasource.dart';
import 'package:finan_goal/features/auth/domain/models/user_model.dart';

// Resultado tipado para manejar errores sin excepciones
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

// ─────────────────────────────────────────────────────────────
class AuthRepository {
  final AuthLocalDatasource _datasource;

  AuthRepository(this._datasource);

  Future<AuthResult> login(String email, String password) async {
    try {
      final hash = AuthLocalDatasource.hashPassword(password);
      final user = await _datasource.findUser(email.trim().toLowerCase(), hash);

      if (user == null) {
        return const AuthFailure('Correo o contraseña incorrectos.');
      }

      await _datasource.saveSession(user);
      return AuthSuccess(user);
    } catch (_) {
      return const AuthFailure('Ocurrió un error inesperado.');
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      if (await _datasource.emailExists(normalizedEmail)) {
        return const AuthFailure('Este correo ya está registrado.');
      }

      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: AuthLocalDatasource.hashPassword(password),
      );

      await _datasource.saveUser(user);
      await _datasource.saveSession(user);
      return AuthSuccess(user);
    } catch (_) {
      return const AuthFailure('Ocurrió un error al registrarte.');
    }
  }

  Future<bool> isLoggedIn() => _datasource.isLoggedIn();
  Future<void> logout() => _datasource.clearSession();
}