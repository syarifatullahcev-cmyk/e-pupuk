import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/subsidy_models.dart';

class SubsidyService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // 1. Ambil Profil Detail Petani (NIK, Poktan, Alamat, Foto KTP)
  static Future<FarmerProfileModel?> getFarmerProfile() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.farmerMeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FarmerProfileModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. Ambil Statistik Kuota Petani (Real-time dari DB)
  static Future<DashboardStatsModel?> getStats() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.petaniStatsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardStatsModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 3. Ambil Daftar Lahan Milik Petani
  static Future<List<LandModel>> getLands() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.landsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => LandModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 4. Tambah Lahan Baru
  static Future<Map<String, dynamic>> createLand({
    required String lokasiDeskripsi,
    required double luasM2,
    required String alamatLahan,
    required String statusKepemilikan,
    required int commodityId,
    double? latitude,
    double? longitude,
    String? fotoLahanUrl,
    String? dokumenSertifikatUrl,
    dynamic polygonCoords,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.landsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lokasi_deskripsi': lokasiDeskripsi,
          'luas_m2': luasM2,
          'alamat_lahan': alamatLahan,
          'status_kepemilikan': statusKepemilikan,
          'commodity_id': commodityId,
          'latitude': latitude ?? -7.531234,
          'longitude': longitude ?? 112.551234,
          'foto_lahan_url': fotoLahanUrl,
          'dokumen_sertifikat_url': dokumenSertifikatUrl,
          'polygon_coords': polygonCoords,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Lahan pertanian berhasil didaftarkan!', 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Gagal mendaftarkan lahan.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // 5. Ambil Daftar Komoditas
  static Future<List<CommodityModel>> getCommodities() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.commoditiesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => CommodityModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 6. Ambil Daftar Jenis Pupuk Bersubsidi
  static Future<List<FertilizerModel>> getFertilizers() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.fertilizersUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => FertilizerModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 7. Kirim Pengajuan Pupuk Subsidi Baru
  static Future<Map<String, dynamic>> submitApplication({
    required int landId,
    required int fertilizerId,
    required double jumlahDiajukan,
    String? alamatLahan,
    double? latitude,
    double? longitude,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.applicationsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'land_id': landId,
          'fertilizer_id': fertilizerId,
          'jumlah_diajukan': jumlahDiajukan,
          'alamat_lahan': alamatLahan,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Pengajuan berhasil dikirim! Menunggu verifikasi Admin.',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Gagal mengirim pengajuan.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan: $e',
      };
    }
  }

  // 8. Ambil Riwayat Pengajuan Pupuk
  static Future<List<ApplicationModel>> getApplications() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.applicationsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => ApplicationModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 9. Ambil Distribusi / E-Tiket QR Code
  static Future<List<DistributionModel>> getDistributions() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myDistributionsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => DistributionModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 10. Ambil Riwayat Scan Karung Pupuk di Sawah
  static Future<List<ScanHistoryModel>> getMyScans() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myScansUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => ScanHistoryModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 11. Validasi & Scan QR Karung Pupuk Fisik (Geofencing GPS)
  static Future<Map<String, dynamic>> scanQrBag({
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.scanQrUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qr_token': qrToken.trim(),
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'status': responseData['status'] ?? 'VALID',
          'message': responseData['message'] ?? 'Pembukaan pupuk berhasil dicatat.',
          'distribution': responseData['distribution'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Gagal memvalidasi QR Karung.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // 12. Revisi Berkas Pengajuan
  static Future<Map<String, dynamic>> reviseDocs({
    required int applicationId,
    String? fotoKtpUrl,
    String? fotoLahanUrl,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reviseDocsUrl(applicationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'foto_ktp_url': fotoKtpUrl,
          'foto_lahan_url': fotoLahanUrl,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Perbaikan berkas berhasil diunggah!'};
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Gagal memperbarui berkas.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }
}
