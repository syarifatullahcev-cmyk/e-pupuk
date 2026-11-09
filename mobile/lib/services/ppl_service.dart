import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/farmer_model.dart';
import '../models/ppl_task_model.dart';
import '../models/subsidy_models.dart';

class PPLService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sesi login tidak tersedia. Silakan masuk kembali.');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.notificationsUrl),
      headers: {'Authorization': '******'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat notifikasi (HTTP ${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Format data notifikasi tidak valid.');
    }

    return decoded.whereType<Map<String, dynamic>>().toList(growable: true);
  }

  static Future<void> markNotificationRead(int id) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sesi login tidak tersedia. Silakan masuk kembali.');
    }

    final response = await http.put(
      Uri.parse(ApiConfig.notificationReadUrl(id)),
      headers: {'Authorization': '******'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'Gagal menandai notifikasi telah dibaca (HTTP ${response.statusCode}).');
    }
  }

  // 1. Ambil Semua Tugas Disposisi Survei untuk PPL
  static Future<List<PPLTaskModel>> getAssignedTasks() async {
    final token = await _getToken();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.pplTasksUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception(
            'Gagal memuat tugas PPL (HTTP ${response.statusCode}).');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Format daftar tugas PPL tidak valid.');
      }
      return decoded
          .map((item) => PPLTaskModel.fromJson(item))
          .toList(growable: false);
    } catch (error) {
      throw Exception('Tidak dapat memuat tugas PPL: $error');
    }
  }

  // 2. Ambil Daftar Petani (dengan filter pencarian)
  static Future<List<FarmerModel>> getFarmers(
      {String? search, String? desa, String? status}) async {
    final token = await _getToken();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      String url = ApiConfig.farmersUrl;
      if (search != null && search.trim().isNotEmpty) {
        url += '?search=${Uri.encodeComponent(search.trim())}';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception(
            'Gagal memuat daftar petani (HTTP ${response.statusCode}).');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Format daftar petani tidak valid.');
      }
      final farmers =
          decoded.map((item) => FarmerModel.fromJson(item)).toList();
      return _filterFarmers(farmers,
          desa: desa, status: status, search: search);
    } catch (error) {
      throw Exception('Tidak dapat memuat daftar petani: $error');
    }
  }

  static List<FarmerModel> _filterFarmers(List<FarmerModel> list,
      {String? desa, String? status, String? search}) {
    var result = list;
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result
          .where((f) =>
              f.nama.toLowerCase().contains(q) ||
              f.nik.contains(q) ||
              f.alamat.toLowerCase().contains(q))
          .toList();
    }
    if (desa != null && desa != 'Semua Desa') {
      result = result
          .where((f) =>
              (f.desa?.toLowerCase() == desa.toLowerCase()) ||
              f.alamat.toLowerCase().contains(desa.toLowerCase()))
          .toList();
    }
    if (status != null && status != 'Status Verifikasi') {
      result = result
          .where(
              (f) => f.statusVerifikasi.toLowerCase() == status.toLowerCase())
          .toList();
    }
    return result;
  }

  // 3. Ambil Detail Petani Lengkap beserta Data Lahannya
  static Future<FarmerModel> getFarmerDetail(int id) async {
    final token = await _getToken();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.farmerDetailUrl(id)),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception(
            'Gagal memuat profil petani (HTTP ${response.statusCode}).');
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Format profil petani tidak valid.');
      }
      final farmer = FarmerModel.fromJson(data);
      final lands = await getLands(farmerId: farmer.id);
      return farmer.copyWith(
        lands: lands,
        jumlahLahan: lands.length,
        totalLuasHa: lands.fold<double>(
            0.0, (double acc, land) => acc + (land.luasM2 / 10000.0)),
      );
    } catch (error) {
      throw Exception('Tidak dapat memuat profil petani: $error');
    }
  }

  // 4. Ambil Daftar Lahan Pertanian (Per Petani atau Semua)
  static Future<List<LandModel>> getLands({int? farmerId}) async {
    final token = await _getToken();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      String url = ApiConfig.landsUrl;
      if (farmerId != null) {
        url = ApiConfig.farmerLandsUrl(farmerId);
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception(
            'Gagal memuat data lahan (HTTP ${response.statusCode}).');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Format daftar lahan tidak valid.');
      }
      return decoded.map((item) => LandModel.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Tidak dapat memuat data lahan: $error');
    }
  }

  // 5. Mulai Survei Lapangan (Update Status ke SURVEI_LAPANGAN)
  static Future<bool> startSurvey(int applicationId) async {
    final token = await _getToken();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.pplStartSurveyUrl(applicationId)),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 6. Serahkan Laporan Hasil Survei Lapangan ke Admin Dinas beserta Poligon Geospasial
  static Future<Map<String, dynamic>> submitSurvey({
    required int applicationId,
    required String kondisiFisikLahan,
    required String keteranganFisikLahan,
    required String kondisiTanaman,
    required String keteranganTanaman,
    required double luasLahanAktualM2,
    required String catatanPpl,
    required String rekomendasi,
    required List<String> fotoSurveiUrls,
    required List<List<double>> polygonCoords,
  }) async {
    if (fotoSurveiUrls.length < 2 || fotoSurveiUrls.length > 5) {
      return {
        'success': false,
        'message': 'Unggah 2 sampai 5 foto bukti survei sebelum mengirim.',
      };
    }
    if (polygonCoords.length < 3 || luasLahanAktualM2 <= 0) {
      return {
        'success': false,
        'message': 'Ukur batas lahan sebelum mengirim hasil survei.',
      };
    }

    final token = await _getToken();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final Map<String, dynamic> bodyData = {
        'kondisi_fisik_lahan': kondisiFisikLahan,
        'keterangan_fisik_lahan': keteranganFisikLahan,
        'kondisi_tanaman': kondisiTanaman,
        'keterangan_tanaman': keteranganTanaman,
        'luas_lahan_aktual_m2': luasLahanAktualM2,
        'foto_survei_urls': fotoSurveiUrls,
        'catatan_ppl': catatanPpl,
        'rekomendasi': rekomendasi,
      };

      bodyData['polygon_coords'] = polygonCoords;

      final response = await http
          .post(
            Uri.parse(ApiConfig.pplSubmitSurveyUrl(applicationId)),
            headers: headers,
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              'Hasil survei lapangan & poligon spasial berhasil diserahkan ke Dinas!',
          'data': responseData,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Gagal menyimpan hasil survei.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Gagal terhubung ke server backend: $e. Pastikan backend aktif di port 8000.',
      };
    }
  }
}
