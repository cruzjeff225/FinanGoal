import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finan_goal/core/constants/app_constants.dart';
import 'package:finan_goal/core/services/api_service.dart';
import 'package:finan_goal/features/auth/data/auth_local_datasource.dart';
import 'package:finan_goal/features/auth/domain/models/user_model.dart';
import 'package:finan_goal/features/auth/domain/repositories/auth_repository.dart';

// ── Providers de infraestructura ──────────────────────────────
final authDatasourceProvider = Provider<AuthLocalDatasource>(
      (_) => AuthLocalDatasource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
      (ref) => AuthRepository(ref.watch(authDatasourceProvider)),
);

// ── Estado del formulario de auth ────────────────────────────
enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );
}

// ── Notifier ─────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _repository.login(email, password);

    if (result is AuthSuccess) {
      state = state.copyWith(status: AuthStatus.success, user: result.user);
      return true;
    } else if (result is AuthFailure) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: result.message,
      );
      return false;
    }
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
    );

    if (result is AuthSuccess) {
      state = state.copyWith(status: AuthStatus.success, user: result.user);
      return true;
    } else if (result is AuthFailure) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: result.message,
      );
      return false;
    }
    return false;
  }

  void resetState() => state = const AuthState();

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.keyUserId);
    final name = prefs.getString(AppConstants.keyUserName);
    final email = prefs.getString(AppConstants.keyUserEmail);
    if (id != null && name != null && email != null) {
      state = state.copyWith(
        status: AuthStatus.success,
        user: UserModel(id: id, name: name, email: email, passwordHash: ''),
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile({required String name, required String email}) async {
    try {
      final response = await ApiService.updateProfile(name, email);
      if (response.containsKey('user')) {
        final updatedUser = UserModel(
          id: response['user']['id'],
          name: response['user']['name'],
          email: response['user']['email'],
          passwordHash: '',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyUserName, updatedUser.name);
        await prefs.setString(AppConstants.keyUserEmail, updatedUser.email);
        state = state.copyWith(user: updatedUser);
        return {'success': true, 'message': 'Perfil actualizado correctamente.'};
      } else {
        return {'success': false, 'message': response['message'] ?? 'Error al actualizar perfil.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión. Intente más tarde.'};
    }
  }

  Future<Map<String, dynamic>> updatePassword({required String currentPassword, required String newPassword}) async {
    try {
      final response = await ApiService.updatePassword(currentPassword, newPassword);
      if (response.containsKey('message') && response['message'].toString().contains('correctamente')) {
        return {'success': true, 'message': response['message']};
      } else {
        return {'success': false, 'message': response['message'] ?? 'Error al actualizar contraseña.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión. Intente más tarde.'};
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

final profileImageProvider = StateNotifierProvider<ProfileImageNotifier, String?>(
      (ref) => ProfileImageNotifier(),
);

class ProfileImageNotifier extends StateNotifier<String?> {
  ProfileImageNotifier() : super(null) {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('profile_image_path');
  }

  Future<void> setImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', path);
    state = path;
  }
}