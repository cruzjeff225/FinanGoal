import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Dirección IP local de tu computadora en la red WiFi.
  // Modifica esto si deseas realizar pruebas en tu celular físico conectado al mismo WiFi.
  static const String _physicalDeviceIp = '192.168.0.10';

  static String get _base {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    // Cambiado a 'true' para conectar tu celular físico Samsung
    bool usePhysicalDevice = true;
    if (usePhysicalDevice) {
      return 'http://$_physicalDeviceIp:3000/api';
    }

    // ignore: dead_code
    try {
      if (Platform.isAndroid) {
        // En emuladores de Android de Google, 10.0.2.2 apunta al host de la computadora
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {}

    // ignore: dead_code
    // Simuladores de iOS, Escritorio y navegadores por defecto
    return 'http://localhost:3000/api';
  }

  // ── Auth ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ── Metas ───────────────────────────────────────────────
  static Future<List> getGoals() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$_base/goals'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createGoal(Map<String, dynamic> data) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('$_base/goals'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateGoal(String id, Map<String, dynamic> data) async {
    final token = await _token();
    final res = await http.patch(
      Uri.parse('$_base/goals/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<void> deleteGoal(String id) async {
    final token = await _token();
    await http.delete(
      Uri.parse('$_base/goals/$id'),
      headers: _headers(token),
    );
  }

  // ── Transacciones ────────────────────────────────────────
  static Future<List> getTransactions() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$_base/transactions'),
      headers: _headers(token),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('$_base/transactions'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateTransaction(String id, Map<String, dynamic> data) async {
    final token = await _token();
    final res = await http.patch(
      Uri.parse('$_base/transactions/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<void> deleteTransaction(String id) async {
    final token = await _token();
    await http.delete(
      Uri.parse('$_base/transactions/$id'),
      headers: _headers(token),
    );
  }

  static Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final token = await _token();
    final res = await http.put(
      Uri.parse('$_base/auth/profile'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'email': email}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updatePassword(String currentPassword, String newPassword) async {
    final token = await _token();
    final res = await http.put(
      Uri.parse('$_base/auth/password'),
      headers: _headers(token),
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    return jsonDecode(res.body);
  }

  // ── Helpers ─────────────────────────────────────────────
  static Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}