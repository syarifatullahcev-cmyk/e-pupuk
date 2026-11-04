import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/subsidy_models.dart';

class SubsidyService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<String?> getAccountEmail() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(ApiConfig.profileUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat email akun (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['email'] as String?;
  }

  static Future<Map<String, dynamic>> uploadImage(
    XFile image,
    String category,
  ) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    final extension = image.name.split('.').last.toLowerCase();
    final subtype = switch (extension) {
      'png' => 'png',
      'webp' => 'webp',
      'jpg' || 'jpeg' => 'jpeg',
      _ => null,
    };
    if (subtype == null) {
      return {
        'success': false,
        'message': 'Pilih gambar JPG, PNG, atau WEBP.',
      };
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/files/upload'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['category'] = category
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            await image.readAsBytes(),
            filename: image.name,
            contentType: MediaType('image', subtype),
          ),
        );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final url = data['url'];
        if (url is String && url.isNotEmpty) {
          return {'success': true, 'url': url};
        }
        return {
          'success': false,
          'message': 'Server tidak mengembalikan URL foto.',
        };
      }
      return {
        'success': false,
        'message': data['detail'] ?? 'Gagal mengunggah foto.',
      };
    } catch (error) {
      return {'success': false, 'message': 'Gagal mengunggah foto: $error'};
    }
  }

  static Future<Map<String, dynamic>> updateFarmerPhoto(
    int farmerId,
    String photoUrl,
  ) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.farmerDetailUrl(farmerId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'foto_ktp_url': photoUrl}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['detail'] ?? 'Gagal menyimpan foto KTP.',
      };
    } catch (error) {
      return {'success': false, 'message': 'Gagal menyimpan foto KTP: $error'};
    }
  }

  static Future<Map<String, dynamic>> updateLandDocuments({
    required int landId,
    required String? fotoLahanUrl,
    required String? dokumenSertifikatUrl,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.landDetailUrl(landId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '******',
        },
        body: jsonEncode({
          'foto_lahan_url': fotoLahanUrl,
          'dokumen_sertifikat_url': dokumenSertifikatUrl,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['detail'] ?? 'Gagal menyimpan dokumen lahan.',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Gagal menyimpan dokumen lahan: $error',
      };
    }
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
          'latitude': latitude,
          'longitude': longitude,
          'foto_lahan_url': fotoLahanUrl,
          'dokumen_sertifikat_url': dokumenSertifikatUrl,
          'polygon_coords': polygonCoords,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Lahan pertanian berhasil didaftarkan!',
          'data': responseData
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Gagal mendaftarkan lahan.'
        };
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
  static Future<Map<String, dynamic>> uploadPupukPhoto(String imagePath) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi login telah berakhir.'};
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/files/upload'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['category'] = 'pupuk'
        ..files.add(await http.MultipartFile.fromPath('file', imagePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'url': responseData['url']};
      }
      return {
        'success': false,
        'message': responseData['detail'] ?? 'Gagal mengunggah foto karung.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengunggah foto: $e'};
    }
  }

  static Future<Map<String, dynamic>> scanQrBag({
    required String qrToken,
    required double latitude,
    required double longitude,
    required String fotoPupukUrl,
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
          'foto_pupuk_url': fotoPupukUrl,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'status': responseData['status'] ?? 'VALID',
          'message':
              responseData['message'] ?? 'Pembukaan pupuk berhasil dicatat.',
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
      final queryParameters = <String, String>{};
      if (fotoKtpUrl != null) {
        queryParameters['foto_ktp_url'] = fotoKtpUrl;
      }
      if (fotoLahanUrl != null) {
        queryParameters['foto_lahan_url'] = fotoLahanUrl;
      }
      final uri = Uri.parse(ApiConfig.reviseDocsUrl(applicationId))
          .replace(queryParameters: queryParameters);
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Perbaikan berkas berhasil diunggah!'
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Gagal memperbarui berkas.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }
}
