import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _base = 'http://192.168.0.9:3000/api';

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

  static Future<void> deleteTransaction(String id) async {
    final token = await _token();
    await http.delete(
      Uri.parse('$_base/transactions/$id'),
      headers: _headers(token),
    );
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