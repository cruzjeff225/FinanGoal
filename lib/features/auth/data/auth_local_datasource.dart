import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finan_goal/core/constants/app_constants.dart';
import 'package:finan_goal/features/auth/domain/models/user_model.dart';

class AuthLocalDatasource {
  static const String _usersKey = 'registered_users';

  // ── Registro ──────────────────────────────────────────────
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getAllUsers(prefs);

    users[user.email] = user.toMap();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  // ── Login ─────────────────────────────────────────────────
  Future<UserModel?> findUser(String email, String passwordHash) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getAllUsers(prefs);

    final userData = users[email];
    if (userData == null) return null;

    final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
    if (user.passwordHash != passwordHash) return null;

    return user;
  }

  Future<bool> emailExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getAllUsers(prefs);
    return users.containsKey(email);
  }

  // ── Sesión ────────────────────────────────────────────────
  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserId, user.id);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserId);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  // ── Helpers ───────────────────────────────────────────────
  Future<Map<String, dynamic>> _getAllUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  // Hash simple (en producción usarías bcrypt o similar)
  static String hashPassword(String password) {
    // Simple pero funcional para propósitos locales
    var hash = 0;
    for (var i = 0; i < password.length; i++) {
      hash = (hash << 5) - hash + password.codeUnitAt(i);
      hash &= hash;
    }
    return hash.abs().toRadixString(16);
  }
}