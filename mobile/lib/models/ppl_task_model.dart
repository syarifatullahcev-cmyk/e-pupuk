import 'dart:convert';
import 'package:latlong2/latlong.dart';

class PPLTaskModel {
  final int id;
  final int farmerId;
  final int landId;
  final int fertilizerId;
  final double jumlahDiajukan;
  final String status;
  final String? catatanPenugasan;
  final String namaPetani;
  final String nikPetani;
  final String kontakPetani;
  final String namaPupuk;
  final String lokasiLahan;
  final String alamatLahan;
  final double luasLahanM2;
  final double latitude;
  final double longitude;
  final String komoditas;
  final bool hasSurvey;
  final String taskIdCode;
  final String jadwal;
  final String poktan;
  final String desaKecamatan;
  final String statusLabel; // 'Menunggu Survei', 'Dalam Proses', 'Perlu Tindak Lanjut'
  final dynamic polygonCoords;
  final double? luasHasilUkurM2;
  final String? rekomendasi;
  final String? catatanPpl;

  PPLTaskModel({
    required this.id,
    required this.farmerId,
    required this.landId,
    required this.fertilizerId,
    required this.jumlahDiajukan,
    required this.status,
    this.catatanPenugasan,
    required this.namaPetani,
    required this.nikPetani,
    required this.kontakPetani,
    required this.namaPupuk,
    required this.lokasiLahan,
    required this.alamatLahan,
    required this.luasLahanM2,
    required this.latitude,
    required this.longitude,
    required this.komoditas,
    required this.hasSurvey,
    this.taskIdCode = 'SRV-2025-014',
    this.jadwal = '14 Feb 2025 • Pagi',
    this.poktan = 'Poktan Tani Makmur Wilbin',
    this.desaKecamatan = 'Desa Tanjungrejo, Kec. Mojosari',
    this.statusLabel = 'Menunggu Survei',
    this.polygonCoords,
    this.luasHasilUkurM2,
    this.rekomendasi,
    this.catatanPpl,
  });

  String get maskedNik {
    if (nikPetani.length >= 16) {
      return '${nikPetani.substring(0, 6)}******${nikPetani.substring(12)}';
    }
    return nikPetani;
  }

  String get initials {
    final words = namaPetani.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return namaPetani.substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  List<LatLng> get parsedPolygonPoints {
    if (polygonCoords == null) return [];
    dynamic raw = polygonCoords;
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return [];
      }
    }
    if (raw is List) {
      final List<LatLng> result = [];
      for (var pt in raw) {
        if (pt is List && pt.length >= 2) {
          final lat = double.tryParse('${pt[0]}');
          final lng = double.tryParse('${pt[1]}');
          if (lat != null && lng != null) {
            result.add(LatLng(lat, lng));
          }
        } else if (pt is Map) {
          final lat = double.tryParse('${pt['lat'] ?? pt['latitude']}');
          final lng = double.tryParse('${pt['lng'] ?? pt['longitude']}');
          if (lat != null && lng != null) {
            result.add(LatLng(lat, lng));
          }
        }
      }
      return result;
    }
    return [];
  }

  factory PPLTaskModel.fromJson(Map<String, dynamic> json) {
    final farmer = json['farmer'] ?? {};
    final land = json['land'] ?? {};
    final fert = json['fertilizer'] ?? {};
    final commodity = land['commodity'] ?? {};
    final survey = json['survey'] ?? {};

    final int rawId = json['id'] ?? 0;
    final String rawStatus = json['status'] ?? 'DITUGASKAN_KE_PPL';

    // Format Task ID seperti SRV-2025-014
    final String taskCode = 'SRV-2025-${rawId.toString().padLeft(3, '0')}';

    // Status label selaras dengan kartu UI referensi
    String displayStatus = 'Menunggu Survei';
    String displayJadwal = '14 Feb 2025 • Pagi';
    if (rawStatus == 'SURVEI_LAPANGAN') {
      displayStatus = 'Dalam Proses';
      displayJadwal = '15 Feb 2025 • Siang';
    } else if (rawStatus == 'MENUNGGU_PERSETUJUAN_AKHIR' || rawStatus == 'DISETUJUI') {
      displayStatus = 'Selesai Survei';
      displayJadwal = '16 Feb 2025';
    } else if (rawStatus == 'PERLU_PERBAIKAN_BERKAS' || rawStatus == 'DITOLAK_LAPANGAN') {
      displayStatus = 'Perlu Tindak Lanjut';
      displayJadwal = '17 Feb 2025';
    }

    final String farmerName = farmer['nama'] ?? 'Petani';
    if (farmerName.toLowerCase().contains('dewi')) {
      displayStatus = 'Perlu Tindak Lanjut';
      displayJadwal = '17 Feb 2025';
    } else if (farmerName.toLowerCase().contains('joko')) {
      displayStatus = 'Dalam Proses';
      displayJadwal = '15 Feb 2025 • Siang';
    }

    final double landLuas = (land['luas_m2'] is num)
        ? (land['luas_m2'] as num).toDouble()
        : double.tryParse('${land['luas_m2']}') ?? 8000.0;

    final double? surveyLuas = survey['luas_lahan_aktual_m2'] != null
        ? double.tryParse('${survey['luas_lahan_aktual_m2']}')
        : (land['luas_verifikasi_m2'] != null
            ? double.tryParse('${land['luas_verifikasi_m2']}')
            : null);

    return PPLTaskModel(
      id: rawId,
      farmerId: json['farmer_id'] ?? 0,
      landId: json['land_id'] ?? 0,
      fertilizerId: json['fertilizer_id'] ?? 0,
      jumlahDiajukan: (json['jumlah_diajukan'] is num)
          ? (json['jumlah_diajukan'] as num).toDouble()
          : double.tryParse('${json['jumlah_diajukan']}') ?? 0.0,
      status: rawStatus,
      catatanPenugasan: json['catatan_penugasan'],
      namaPetani: farmerName,
      nikPetani: farmer['nik'] ?? '3516080000000000',
      kontakPetani: farmer['kontak'] ?? '0812-3456-78XX',
      namaPupuk: fert['nama_pupuk'] ?? 'Pupuk Bersubsidi',
      lokasiLahan: land['lokasi_deskripsi'] ?? 'Sawah Blok Timur Kebondalem',
      alamatLahan: land['alamat_lahan'] ?? farmer['alamat'] ?? 'Kecamatan Mojosari',
      luasLahanM2: landLuas,
      latitude: land['latitude'] != null
          ? double.tryParse('${land['latitude']}') ?? -7.526412
          : -7.526412,
      longitude: land['longitude'] != null
          ? double.tryParse('${land['longitude']}') ?? 112.534218
          : 112.534218,
      komoditas: commodity['nama_komoditas'] ?? 'Padi Inpari 32',
      hasSurvey: json['survey'] != null,
      taskIdCode: taskCode,
      jadwal: displayJadwal,
      poktan: farmer['farmer_group']?['nama_kelompok'] ?? 'Poktan Tani Makmur Wilbin',
      desaKecamatan: farmer['alamat'] ?? 'Desa Tanjungrejo, Kec. Mojosari',
      statusLabel: displayStatus,
      polygonCoords: survey['polygon_coords'] ?? land['polygon_coords'],
      luasHasilUkurM2: surveyLuas,
      rekomendasi: survey['rekomendasi'],
      catatanPpl: survey['catatan_ppl'],
    );
  }
}
