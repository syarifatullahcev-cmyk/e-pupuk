import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/ppl_task_model.dart';

class PPLService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // 1. Ambil Semua Tugas Disposisi Survei untuk PPL
  static Future<List<PPLTaskModel>> getAssignedTasks() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.pplTasksUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => PPLTaskModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Mulai Survei Lapangan (Update Status ke SURVEI_LAPANGAN)
  static Future<bool> startSurvey(int applicationId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.pplStartSurveyUrl(applicationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Serahkan Laporan Hasil Survei Lapangan ke Admin
  static Future<Map<String, dynamic>> submitSurvey({
    required int applicationId,
    required String kondisiFisikLahan,
    required String keteranganFisikLahan,
    required String kondisiTanaman,
    required String keteranganTanaman,
    required double luasLahanAktualM2,
    required String catatanPpl,
    required String rekomendasi,
    List<String>? fotoSurveiUrls,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.pplSubmitSurveyUrl(applicationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'kondisi_fisik_lahan': kondisiFisikLahan,
          'keterangan_fisik_lahan': keteranganFisikLahan,
          'kondisi_tanaman': kondisiTanaman,
          'keterangan_tanaman': keteranganTanaman,
          'luas_lahan_aktual_m2': luasLahanAktualM2,
          'foto_survei_urls': fotoSurveiUrls ?? ['/files/survei/sample_survei_lahan1.jpg'],
          'catatan_ppl': catatanPpl,
          'rekomendasi': rekomendasi,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Hasil survei lapangan berhasil diserahkan ke Admin Dinas!',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Gagal menyimpan hasil survei.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }
}
