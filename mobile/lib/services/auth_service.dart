import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  // 1. Registrasi Akun Petani Baru
  static Future<Map<String, dynamic>> registerPetani({
    required String username,
    required String email,
    required String password,
    required String nama,
    required String nik,
    required String kontak,
    required String alamat,
    required String kelompokTani,
  }) async {
    final url = Uri.parse(ApiConfig.registerUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'nama': nama,
          'nik': nik,
          'kontak': kontak,
          'alamat': alamat,
          'kelompok_tani': kelompokTani,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Pendaftaran berhasil!',
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Gagal mendaftar. Silakan coba lagi.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server backend: $e',
      };
    }
  }

  // 2. Login User
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse(ApiConfig.loginUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['access_token'];
        final user = UserModel.fromJson(responseData, token: token);

        // Simpan token & user di storage lokal HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_data', jsonEncode(user.toJson()));

        return {
          'success': true,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Username atau password salah.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server backend: $e',
      };
    }
  }

  // 3. Cek Status Login Saat Ini
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString == null) return null;

    final userMap = jsonDecode(userDataString);
    return UserModel(
      id: userMap['id'],
      username: userMap['username'],
      role: userMap['role'],
      nama: userMap['nama'],
      farmerId: userMap['farmer_id'],
      token: userMap['token'],
    );
  }

  // 4. Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
