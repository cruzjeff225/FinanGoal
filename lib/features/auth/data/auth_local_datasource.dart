import 'package:shared_preferences/shared_preferences.dart';
import 'package:finan_goal/core/constants/app_constants.dart';
import 'package:finan_goal/features/auth/domain/models/user_model.dart';

class AuthLocalDatasource {

  // ── Sesión ────────────────────────────────────────────────
  Future<void> saveSession(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString('token', token);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove('token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }
}