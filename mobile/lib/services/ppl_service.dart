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

      final response = await http.get(
        Uri.parse(ApiConfig.pplTasksUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((item) => PPLTaskModel.fromJson(item)).toList();
        }
      }
    } catch (_) {
      // Fallback ke data prototipe jika jaringan/API belum tersedia
    }

    return _getFallbackTasks();
  }

  // 2. Ambil Daftar Petani (dengan filter pencarian)
  static Future<List<FarmerModel>> getFarmers({String? search, String? desa, String? status}) async {
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

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final list = data.map((item) => FarmerModel.fromJson(item)).toList();
          return _filterFarmers(list, desa: desa, status: status);
        }
      }
    } catch (_) {
      // Gunakan fallback
    }

    return _filterFarmers(_getFallbackFarmers(), desa: desa, status: status, search: search);
  }

  static List<FarmerModel> _filterFarmers(List<FarmerModel> list, {String? desa, String? status, String? search}) {
    var result = list;
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((f) =>
        f.nama.toLowerCase().contains(q) ||
        f.nik.contains(q) ||
        f.alamat.toLowerCase().contains(q)
      ).toList();
    }
    if (desa != null && desa != 'Semua Desa') {
      result = result.where((f) => (f.desa?.toLowerCase() == desa.toLowerCase()) || f.alamat.toLowerCase().contains(desa.toLowerCase())).toList();
    }
    if (status != null && status != 'Status Verifikasi') {
      result = result.where((f) => f.statusVerifikasi.toLowerCase() == status.toLowerCase()).toList();
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

      final response = await http.get(
        Uri.parse(ApiConfig.farmerDetailUrl(id)),
        headers: headers,
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final farmer = FarmerModel.fromJson(data);

        // Ambil daftar lahan petani ini
        final lands = await getLands(farmerId: farmer.id);
        return farmer.copyWith(
          lands: lands,
          jumlahLahan: lands.length,
          totalLuasHa: lands.fold<double>(0.0, (double acc, l) => acc + (l.luasM2 / 10000.0)),
        );
      }
    } catch (_) {
      // Gunakan fallback
    }

    final fallback = _getFallbackFarmers().firstWhere(
      (f) => f.id == id,
      orElse: () => _getFallbackFarmers().first,
    );
    return fallback;
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

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => LandModel.fromJson(item)).toList();
      }
    } catch (_) {
      // Gunakan fallback
    }

    if (farmerId == 2 || farmerId == null) {
      return _getFallbackLandsSiti();
    }
    return [];
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

      final response = await http.post(
        Uri.parse(ApiConfig.pplStartSurveyUrl(applicationId)),
        headers: headers,
      ).timeout(const Duration(seconds: 4));
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
    List<List<double>>? polygonCoords,
    List<String>? fotoSurveiUrls,
  }) async {
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
        'foto_survei_urls': fotoSurveiUrls ?? ['/files/survei/sample_survei_lahan1.jpg'],
        'catatan_ppl': catatanPpl,
        'rekomendasi': rekomendasi,
      };

      if (polygonCoords != null && polygonCoords.isNotEmpty) {
        bodyData['polygon_coords'] = polygonCoords;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.pplSubmitSurveyUrl(applicationId)),
        headers: headers,
        body: jsonEncode(bodyData),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Hasil survei lapangan & poligon spasial berhasil diserahkan ke Dinas!',
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
        'message': 'Gagal terhubung ke server backend: $e. Pastikan backend aktif di port 8000.',
      };
    }
  }

  // --- DATA FALLBACK SESUAI REFERENSI DESAIN ---
  static List<FarmerModel> _getFallbackFarmers() {
    return [
      FarmerModel(
        id: 2,
        userId: 3,
        nama: 'Siti Aminah',
        nik: '3516082104850002',
        kontak: '0812-3456-78XX',
        alamat: 'Dsn. Sumberarum RT 02 RW 01, Ds. Tanjungrejo, Kec. Mojosari',
        desa: 'Tanjungrejo',
        kecamatan: 'Mojosari',
        poktan: 'Poktan Sumber Makmur',
        statusVerifikasi: 'Menunggu',
        jumlahLahan: 2,
        totalLuasHa: 1.4,
        diperbarui: '12 Feb 2025',
        lands: _getFallbackLandsSiti(),
      ),
      FarmerModel(
        id: 4,
        userId: 4,
        nama: 'Joko Santoso',
        nik: '3516081208800019',
        kontak: '0812-9876-54XX',
        alamat: 'Desa Sukamaju, Kec. Mojosari',
        desa: 'Sukamaju',
        kecamatan: 'Mojosari',
        poktan: 'Poktan Tani Sejahtera',
        statusVerifikasi: 'Dalam Proses',
        jumlahLahan: 1,
        totalLuasHa: 1.2,
        diperbarui: '11 Feb 2025',
        lands: [
          LandModel(
            id: 7,
            lokasiDeskripsi: 'Sawah Sukamaju Blok Tengah',
            luasM2: 12000.0,
            alamatLahan: 'Desa Sukamaju, Kec. Mojosari',
            statusKepemilikan: 'MILIK',
            latitude: -7.521500,
            longitude: 112.539000,
            namaKomoditas: 'Jagung Hibrida',
            statusVerifikasi: 'BELUM_DIVERIFIKASI',
          )
        ],
      ),
      FarmerModel(
        id: 5,
        userId: 5,
        nama: 'Dewi Lestari',
        nik: '3516085509910041',
        kontak: '0857-1122-33XX',
        alamat: 'Desa Sumberrejo, Kec. Mojosari',
        desa: 'Sumberrejo',
        kecamatan: 'Mojosari',
        poktan: 'Poktan Sri Rejeki',
        statusVerifikasi: 'Perlu Perbaikan',
        jumlahLahan: 1,
        totalLuasHa: 0.6,
        diperbarui: '09 Feb 2025',
        lands: [
          LandModel(
            id: 8,
            lokasiDeskripsi: 'Tegal Sumberrejo Blok Utara',
            luasM2: 6000.0,
            alamatLahan: 'Desa Sumberrejo, Kec. Mojosari',
            statusKepemilikan: 'MILIK',
            latitude: -7.518000,
            longitude: 112.542000,
            namaKomoditas: 'Kedelai Anjasmoro',
            statusVerifikasi: 'PERLU_SURVEI_ULANG',
          )
        ],
      ),
    ];
  }

  static List<LandModel> _getFallbackLandsSiti() {
    return [
      LandModel(
        id: 5,
        lokasiDeskripsi: 'Sawah Blok Timur Kebondalem',
        luasM2: 8000.0,
        alamatLahan: 'Dsn. Sumberarum RT 02 RW 01, Ds. Tanjungrejo, Kec. Mojosari',
        statusKepemilikan: 'MILIK',
        latitude: -7.526412,
        longitude: 112.534218,
        namaKomoditas: 'Padi Inpari 32',
        statusVerifikasi: 'TERVERIFIKASI',
        luasVerifikasiM2: 7850.0,
        catatanVerifikasi: 'Batas fisik tapak sawah telah diverifikasi citra Sentinel-2 & GPS PPL.',
        polygonCoords: [
          [-7.526012, 112.533812],
          [-7.526012, 112.534618],
          [-7.526812, 112.534618],
          [-7.526812, 112.533812]
        ],
      ),
      LandModel(
        id: 6,
        lokasiDeskripsi: 'Tegal Sawah Blok Selatan',
        luasM2: 6000.0,
        alamatLahan: 'Dsn. Sumberarum RT 03 RW 01, Ds. Tanjungrejo, Kec. Mojosari',
        statusKepemilikan: 'GARAP',
        latitude: -7.528500,
        longitude: 112.536200,
        namaKomoditas: 'Jagung Hibrida',
        statusVerifikasi: 'BELUM_DIVERIFIKASI',
        polygonCoords: null,
      ),
    ];
  }

  static List<PPLTaskModel> _getFallbackTasks() {
    return [
      PPLTaskModel(
        id: 12,
        farmerId: 2,
        landId: 5,
        fertilizerId: 1,
        jumlahDiajukan: 240.0,
        status: 'DITUGASKAN_KE_PPL',
        namaPetani: 'Siti Aminah',
        nikPetani: '3516082104850002',
        kontakPetani: '0812-3456-78XX',
        namaPupuk: 'Urea Bersubsidi',
        lokasiLahan: 'Sawah Blok Timur Kebondalem',
        alamatLahan: 'Dsn. Sumberarum RT 02 RW 01, Ds. Tanjungrejo, Kec. Mojosari',
        luasLahanM2: 8000.0,
        latitude: -7.526412,
        longitude: 112.534218,
        komoditas: 'Padi Inpari 32',
        hasSurvey: false,
        taskIdCode: 'SRV-2025-014',
        jadwal: '14 Feb 2025 • Pagi',
        poktan: 'Poktan Tani Makmur Wilbin',
        desaKecamatan: 'Desa Tanjungrejo, Kec. Mojosari',
        statusLabel: 'Menunggu Survei',
        polygonCoords: [
          [-7.526012, 112.533812],
          [-7.526012, 112.534618],
          [-7.526812, 112.534618],
          [-7.526812, 112.533812]
        ],
        luasHasilUkurM2: 7850.0,
      ),
      PPLTaskModel(
        id: 13,
        farmerId: 4,
        landId: 7,
        fertilizerId: 2,
        jumlahDiajukan: 300.0,
        status: 'SURVEI_LAPANGAN',
        namaPetani: 'Joko Santoso',
        nikPetani: '3516081208800019',
        kontakPetani: '0812-9876-54XX',
        namaPupuk: 'NPK Phonska Bersubsidi',
        lokasiLahan: 'Sawah Sukamaju Blok Tengah',
        alamatLahan: 'Desa Sukamaju, Kec. Mojosari',
        luasLahanM2: 12000.0,
        latitude: -7.521500,
        longitude: 112.539000,
        komoditas: 'Jagung Hibrida',
        hasSurvey: false,
        taskIdCode: 'SRV-2025-018',
        jadwal: '15 Feb 2025 • Siang',
        poktan: 'Poktan Tani Sejahtera',
        desaKecamatan: 'Desa Sukamaju, Kec. Mojosari',
        statusLabel: 'Dalam Proses',
      ),
      PPLTaskModel(
        id: 14,
        farmerId: 5,
        landId: 8,
        fertilizerId: 1,
        jumlahDiajukan: 120.0,
        status: 'SURVEI_LAPANGAN',
        namaPetani: 'Dewi Lestari',
        nikPetani: '3516085509910041',
        kontakPetani: '0857-1122-33XX',
        namaPupuk: 'Urea Bersubsidi',
        lokasiLahan: 'Tegal Sumberrejo Blok Utara',
        alamatLahan: 'Desa Sumberrejo, Kec. Mojosari',
        luasLahanM2: 6000.0,
        latitude: -7.518000,
        longitude: 112.542000,
        komoditas: 'Kedelai Anjasmoro',
        hasSurvey: false,
        taskIdCode: 'SRV-2025-021',
        jadwal: '17 Feb 2025',
        poktan: 'Poktan Sri Rejeki',
        desaKecamatan: 'Desa Sumberrejo, Kec. Mojosari',
        statusLabel: 'Perlu Tindak Lanjut',
      ),
    ];
  }
}
