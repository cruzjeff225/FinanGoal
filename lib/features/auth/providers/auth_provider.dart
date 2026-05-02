import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);