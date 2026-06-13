import 'dart:convert';
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

  // ── Credenciales Guardadas (Remember Me) ──────────────────
  Future<void> saveSavedCredentials(String email, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyRememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(AppConstants.keySavedEmail, email);
      // Encrypt the password in Base64
      final bytes = utf8.encode(password);
      final encrypted = base64.encode(bytes);
      await prefs.setString(AppConstants.keySavedPassword, encrypted);
    } else {
      await prefs.remove(AppConstants.keySavedEmail);
      await prefs.remove(AppConstants.keySavedPassword);
    }
  }

  Future<Map<String, String>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(AppConstants.keyRememberMe) ?? false;
    if (rememberMe) {
      final email = prefs.getString(AppConstants.keySavedEmail) ?? '';
      final encryptedPassword = prefs.getString(AppConstants.keySavedPassword) ?? '';
      String password = '';
      if (encryptedPassword.isNotEmpty) {
        try {
          final decodedBytes = base64.decode(encryptedPassword);
          password = utf8.decode(decodedBytes);
        } catch (_) {}
      }
      return {
        'email': email,
        'password': password,
      };
    }
    return {};
  }
}