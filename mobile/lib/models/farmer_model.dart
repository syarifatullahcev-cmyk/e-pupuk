import 'subsidy_models.dart';

class FarmerModel {
  final int id;
  final int userId;
  final String nama;
  final String nik;
  final String kontak;
  final String alamat;
  final String? desa;
  final String? kecamatan;
  final String poktan;
  final String statusVerifikasi; // 'Menunggu', 'Dalam Proses', 'Perlu Perbaikan', 'Terverifikasi'
  final int jumlahLahan;
  final double totalLuasHa;
  final String diperbarui;
  final String? fotoKtpUrl;
  final List<LandModel> lands;

  FarmerModel({
    required this.id,
    required this.userId,
    required this.nama,
    required this.nik,
    required this.kontak,
    required this.alamat,
    this.desa,
    this.kecamatan,
    required this.poktan,
    this.statusVerifikasi = 'Menunggu',
    this.jumlahLahan = 1,
    this.totalLuasHa = 0.8,
    this.diperbarui = '12 Feb 2025',
    this.fotoKtpUrl,
    this.lands = const [],
  });

  String get maskedNik {
    if (nik.length >= 16) {
      return '${nik.substring(0, 6)}******${nik.substring(12)}';
    }
    return nik;
  }

  String get initials {
    final words = nama.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return nama.substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    final group = json['farmer_group'] ?? {};
    final rawLands = json['lands'] as List? ?? [];
    final List<LandModel> parsedLands =
        rawLands.map((item) => LandModel.fromJson(item)).toList();

    // Hitung total luas lahan jika ada daftar lahan
    double totalM2 = 0;
    for (var l in parsedLands) {
      totalM2 += l.luasM2;
    }
    final double calculatedHa = totalM2 > 0 ? (totalM2 / 10000.0) : 0.8;

    final String alamatStr = json['alamat'] ?? 'Kabupaten Mojokerto';
    String extractedDesa = 'Tanjungrejo';
    String extractedKec = 'Mojosari';
    if (alamatStr.contains('Ds. ') || alamatStr.contains('Desa ')) {
      final match = RegExp(r'(?:Ds\.|Desa)\s*([^,]+)').firstMatch(alamatStr);
      if (match != null) extractedDesa = match.group(1)?.trim() ?? 'Mojosari';
    }
    if (alamatStr.contains('Kec. ') || alamatStr.contains('Kecamatan ')) {
      final match = RegExp(r'(?:Kec\.|Kecamatan)\s*([^,]+)').firstMatch(alamatStr);
      if (match != null) extractedKec = match.group(1)?.trim() ?? 'Mojosari';
    }

    return FarmerModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      nama: json['nama'] ?? 'Petani',
      nik: json['nik'] ?? '3516080000000000',
      kontak: json['kontak'] ?? '0812-3456-78XX',
      alamat: alamatStr,
      desa: extractedDesa,
      kecamatan: extractedKec,
      poktan: group['nama_kelompok'] ?? 'Poktan Sumber Makmur',
      statusVerifikasi: json['status_verifikasi'] ?? 'Menunggu',
      jumlahLahan: parsedLands.isNotEmpty ? parsedLands.length : 1,
      totalLuasHa: calculatedHa,
      diperbarui: json['diperbarui'] ?? '12 Feb 2025',
      fotoKtpUrl: json['foto_ktp_url'],
      lands: parsedLands,
    );
  }

  FarmerModel copyWith({
    List<LandModel>? lands,
    int? jumlahLahan,
    double? totalLuasHa,
  }) {
    return FarmerModel(
      id: id,
      userId: userId,
      nama: nama,
      nik: nik,
      kontak: kontak,
      alamat: alamat,
      desa: desa,
      kecamatan: kecamatan,
      poktan: poktan,
      statusVerifikasi: statusVerifikasi,
      jumlahLahan: jumlahLahan ?? this.jumlahLahan,
      totalLuasHa: totalLuasHa ?? this.totalLuasHa,
      diperbarui: diperbarui,
      fotoKtpUrl: fotoKtpUrl,
      lands: lands ?? this.lands,
    );
  }
}
