import 'dart:convert';
import 'package:latlong2/latlong.dart';

class LandModel {
  final int id;
  final String lokasiDeskripsi;
  final double luasM2;
  final String alamatLahan;
  final String statusKepemilikan;
  final double? latitude;
  final double? longitude;
  final String? fotoLahanUrl;
  final String? dokumenSertifikatUrl;
  final dynamic polygonCoords;
  final double? luasVerifikasiM2;
  final String statusVerifikasi;
  final String? catatanVerifikasi;
  final String? namaKomoditas;

  LandModel({
    required this.id,
    required this.lokasiDeskripsi,
    required this.luasM2,
    required this.alamatLahan,
    required this.statusKepemilikan,
    this.latitude,
    this.longitude,
    this.fotoLahanUrl,
    this.dokumenSertifikatUrl,
    this.polygonCoords,
    this.luasVerifikasiM2,
    this.statusVerifikasi = 'BELUM_DIVERIFIKASI',
    this.catatanVerifikasi,
    this.namaKomoditas,
  });

  bool get isTerverifikasi => statusVerifikasi == 'TERVERIFIKASI';

  double? get selisihLuasM2 => luasVerifikasiM2 != null ? (luasVerifikasiM2! - luasM2) : null;

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

  factory LandModel.fromJson(Map<String, dynamic> json) {
    return LandModel(
      id: json['id'] ?? 0,
      lokasiDeskripsi: json['lokasi_deskripsi'] ?? 'Lahan Petani',
      luasM2: (json['luas_m2'] is num) ? (json['luas_m2'] as num).toDouble() : double.tryParse('${json['luas_m2']}') ?? 0.0,
      alamatLahan: json['alamat_lahan'] ?? '',
      statusKepemilikan: json['status_kepemilikan'] ?? 'MILIK',
      latitude: json['latitude'] != null ? double.tryParse('${json['latitude']}') : null,
      longitude: json['longitude'] != null ? double.tryParse('${json['longitude']}') : null,
      fotoLahanUrl: json['foto_lahan_url'],
      dokumenSertifikatUrl: json['dokumen_sertifikat_url'],
      polygonCoords: json['polygon_coords'],
      luasVerifikasiM2: json['luas_verifikasi_m2'] != null ? double.tryParse('${json['luas_verifikasi_m2']}') : null,
      statusVerifikasi: json['status_verifikasi'] ?? 'BELUM_DIVERIFIKASI',
      catatanVerifikasi: json['catatan_verifikasi'],
      namaKomoditas: json['commodity']?['nama_komoditas'],
    );
  }
}

class FertilizerModel {
  final int id;
  final String namaPupuk;
  final String jenis;
  final double hargaSubsidi;

  FertilizerModel({
    required this.id,
    required this.namaPupuk,
    required this.jenis,
    required this.hargaSubsidi,
  });

  factory FertilizerModel.fromJson(Map<String, dynamic> json) {
    return FertilizerModel(
      id: json['id'] ?? 0,
      namaPupuk: json['nama_pupuk'] ?? '',
      jenis: json['jenis'] ?? '',
      hargaSubsidi: (json['harga_subsidi'] is num)
          ? (json['harga_subsidi'] as num).toDouble()
          : double.tryParse('${json['harga_subsidi']}') ?? 0.0,
    );
  }
}

class CommodityModel {
  final int id;
  final String namaKomoditas;

  CommodityModel({required this.id, required this.namaKomoditas});

  factory CommodityModel.fromJson(Map<String, dynamic> json) {
    return CommodityModel(
      id: json['id'] ?? 0,
      namaKomoditas: json['nama_komoditas'] ?? '',
    );
  }
}

class ApplicationModel {
  final int id;
  final int farmerId;
  final int landId;
  final int fertilizerId;
  final double jumlahDiajukan;
  final double? jumlahDisetujui;
  final String status;
  final String? createdAt;
  final String? namaPupuk;
  final String? satuanPupuk;
  final String? lokasiLahan;
  final double? luasLahan;
  final String? catatanAdminBerkas;
  final String? catatanFinalAdmin;
  final String? surveyKondisiLahan;
  final String? surveyKondisiTanaman;
  final String? surveyRekomendasi;
  final String? surveyFotoUrl;

  ApplicationModel({
    required this.id,
    required this.farmerId,
    required this.landId,
    required this.fertilizerId,
    required this.jumlahDiajukan,
    this.jumlahDisetujui,
    required this.status,
    this.createdAt,
    this.namaPupuk,
    this.satuanPupuk,
    this.lokasiLahan,
    this.luasLahan,
    this.catatanAdminBerkas,
    this.catatanFinalAdmin,
    this.surveyKondisiLahan,
    this.surveyKondisiTanaman,
    this.surveyRekomendasi,
    this.surveyFotoUrl,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    final survey = json['survey'];
    String? surveyFoto;
    if (survey != null && survey['foto_survei_urls'] is List && (survey['foto_survei_urls'] as List).isNotEmpty) {
      surveyFoto = survey['foto_survei_urls'][0];
    }

    return ApplicationModel(
      id: json['id'] ?? 0,
      farmerId: json['farmer_id'] ?? 0,
      landId: json['land_id'] ?? 0,
      fertilizerId: json['fertilizer_id'] ?? 0,
      jumlahDiajukan: (json['jumlah_diajukan'] is num)
          ? (json['jumlah_diajukan'] as num).toDouble()
          : double.tryParse('${json['jumlah_diajukan']}') ?? 0.0,
      jumlahDisetujui: json['jumlah_disetujui'] != null
          ? (json['jumlah_disetujui'] is num
              ? (json['jumlah_disetujui'] as num).toDouble()
              : double.tryParse('${json['jumlah_disetujui']}'))
          : null,
      status: json['status'] ?? 'DIAJUKAN',
      createdAt: json['created_at'] ?? json['tanggal_pengajuan'],
      namaPupuk: json['fertilizer']?['nama_pupuk'],
      satuanPupuk: json['fertilizer']?['satuan'] ?? 'kg',
      lokasiLahan: json['land']?['lokasi_deskripsi'] ?? json['land']?['alamat_lahan'],
      luasLahan: json['land']?['luas_m2'] != null ? double.tryParse('${json['land']['luas_m2']}') : null,
      catatanAdminBerkas: json['catatan_admin_berkas'],
      catatanFinalAdmin: json['catatan_final_admin'],
      surveyKondisiLahan: survey?['kondisi_fisik_lahan'],
      surveyKondisiTanaman: survey?['kondisi_tanaman'],
      surveyRekomendasi: survey?['rekomendasi'],
      surveyFotoUrl: surveyFoto,
    );
  }
}

class DistributionModel {
  final int id;
  final int applicationId;
  final double jumlahDisalurkan;
  final String statusPenyaluran;
  final String qrCodeHash;
  final String namaPupuk;
  final String namaLahan;
  final String? alamatLahan;
  final double? latitude;
  final double? longitude;
  final String? tanggalPenyaluran;

  DistributionModel({
    required this.id,
    required this.applicationId,
    required this.jumlahDisalurkan,
    required this.statusPenyaluran,
    required this.qrCodeHash,
    required this.namaPupuk,
    required this.namaLahan,
    this.alamatLahan,
    this.latitude,
    this.longitude,
    this.tanggalPenyaluran,
  });

  factory DistributionModel.fromJson(Map<String, dynamic> json) {
    final app = json['application'] ?? {};
    final land = app['land'] ?? {};
    return DistributionModel(
      id: json['id'] ?? 0,
      applicationId: json['application_id'] ?? 0,
      jumlahDisalurkan: (json['jumlah_disalurkan'] is num)
          ? (json['jumlah_disalurkan'] as num).toDouble()
          : double.tryParse('${json['jumlah_disalurkan']}') ?? 0.0,
      statusPenyaluran: json['status_penyaluran'] ?? 'MENUNGGU_PENGAMBILAN',
      qrCodeHash: json['qr_code_hash'] ?? '',
      namaPupuk: app['fertilizer']?['nama_pupuk'] ?? 'Pupuk Bersubsidi',
      namaLahan: land['lokasi_deskripsi'] ?? land['alamat_lahan'] ?? 'Lahan Pertanian',
      alamatLahan: land['alamat_lahan'],
      latitude: app['latitude'] != null ? double.tryParse('${app['latitude']}') : (land['latitude'] != null ? double.tryParse('${land['latitude']}') : null),
      longitude: app['longitude'] != null ? double.tryParse('${app['longitude']}') : (land['longitude'] != null ? double.tryParse('${land['longitude']}') : null),
      tanggalPenyaluran: json['tanggal_penyaluran'],
    );
  }
}

class DashboardStatsModel {
  final int totalPengajuan;
  final int aktif;
  final int disetujui;
  final int tersalurkan;
  final int totalLahan;
  final double kuotaTersediaUrea;
  final double kuotaTersediaNpk;

  DashboardStatsModel({
    required this.totalPengajuan,
    required this.aktif,
    required this.disetujui,
    required this.tersalurkan,
    required this.totalLahan,
    required this.kuotaTersediaUrea,
    required this.kuotaTersediaNpk,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalPengajuan: json['total_pengajuan'] ?? 0,
      aktif: json['aktif'] ?? 0,
      disetujui: json['disetujui'] ?? 0,
      tersalurkan: json['tersalurkan'] ?? 0,
      totalLahan: json['total_lahan'] ?? 0,
      kuotaTersediaUrea: (json['kuota_tersedia_urea'] is num)
          ? (json['kuota_tersedia_urea'] as num).toDouble()
          : double.tryParse('${json['kuota_tersedia_urea']}') ?? 500.0,
      kuotaTersediaNpk: (json['kuota_tersedia_npk'] is num)
          ? (json['kuota_tersedia_npk'] as num).toDouble()
          : double.tryParse('${json['kuota_tersedia_npk']}') ?? 400.0,
    );
  }
}

class FarmerProfileModel {
  final int id;
  final String nama;
  final String nik;
  final String? kontak;
  final String? alamat;
  final String? fotoKtpUrl;
  final String? kelompokTani;
  final String? wilayahPoktan;

  FarmerProfileModel({
    required this.id,
    required this.nama,
    required this.nik,
    this.kontak,
    this.alamat,
    this.fotoKtpUrl,
    this.kelompokTani,
    this.wilayahPoktan,
  });

  factory FarmerProfileModel.fromJson(Map<String, dynamic> json) {
    return FarmerProfileModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? 'Petani',
      nik: json['nik'] ?? '-',
      kontak: json['kontak'],
      alamat: json['alamat'],
      fotoKtpUrl: json['foto_ktp_url'],
      kelompokTani: json['farmer_group']?['nama_kelompok'],
      wilayahPoktan: json['farmer_group']?['wilayah'],
    );
  }
}

class ScanHistoryModel {
  final int id;
  final String tanggal;
  final String waktu;
  final String jenisPupuk;
  final String jumlahPupuk;
  final double jumlahKg;
  final String namaLahan;
  final String alamatLahan;
  final double latitude;
  final double longitude;
  final String statusPembukaan;
  final String statusValidasi;

  ScanHistoryModel({
    required this.id,
    required this.tanggal,
    required this.waktu,
    required this.jenisPupuk,
    required this.jumlahPupuk,
    required this.jumlahKg,
    required this.namaLahan,
    required this.alamatLahan,
    required this.latitude,
    required this.longitude,
    required this.statusPembukaan,
    required this.statusValidasi,
  });

  factory ScanHistoryModel.fromJson(Map<String, dynamic> json) {
    return ScanHistoryModel(
      id: json['id'] ?? 0,
      tanggal: json['tanggal'] ?? '-',
      waktu: json['waktu'] ?? '-',
      jenisPupuk: json['jenis_pupuk'] ?? 'Pupuk Bersubsidi',
      jumlahPupuk: json['jumlah_pupuk'] ?? '0 kg',
      jumlahKg: (json['jumlah_kg'] is num) ? (json['jumlah_kg'] as num).toDouble() : double.tryParse('${json['jumlah_kg']}') ?? 0.0,
      namaLahan: json['nama_lahan'] ?? 'Lahan Pertanian',
      alamatLahan: json['alamat_lahan'] ?? '-',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse('${json['latitude']}') ?? -7.531234,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse('${json['longitude']}') ?? 112.551234,
      statusPembukaan: json['status_pembukaan'] ?? 'Pembukaan Berhasil',
      statusValidasi: json['status_validasi'] ?? 'VALID',
    );
  }
}
