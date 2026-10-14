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
  });

  factory PPLTaskModel.fromJson(Map<String, dynamic> json) {
    final farmer = json['farmer'] ?? {};
    final land = json['land'] ?? {};
    final fert = json['fertilizer'] ?? {};
    final commodity = land['commodity'] ?? {};

    return PPLTaskModel(
      id: json['id'] ?? 0,
      farmerId: json['farmer_id'] ?? 0,
      landId: json['land_id'] ?? 0,
      fertilizerId: json['fertilizer_id'] ?? 0,
      jumlahDiajukan: (json['jumlah_diajukan'] is num)
          ? (json['jumlah_diajukan'] as num).toDouble()
          : double.tryParse('${json['jumlah_diajukan']}') ?? 0.0,
      status: json['status'] ?? 'DITUGASKAN_KE_PPL',
      catatanPenugasan: json['catatan_penugasan'],
      namaPetani: farmer['nama'] ?? 'Petani',
      nikPetani: farmer['nik'] ?? '-',
      kontakPetani: farmer['kontak'] ?? '-',
      namaPupuk: fert['nama_pupuk'] ?? 'Pupuk Bersubsidi',
      lokasiLahan: land['lokasi_deskripsi'] ?? land['alamat_lahan'] ?? 'Lahan Pertanian',
      alamatLahan: land['alamat_lahan'] ?? '',
      luasLahanM2: (land['luas_m2'] is num)
          ? (land['luas_m2'] as num).toDouble()
          : double.tryParse('${land['luas_m2']}') ?? 0.0,
      latitude: land['latitude'] != null
          ? double.tryParse('${land['latitude']}') ?? -7.4726
          : -7.4726,
      longitude: land['longitude'] != null
          ? double.tryParse('${land['longitude']}') ?? 112.4381
          : 112.4381,
      komoditas: commodity['nama_komoditas'] ?? 'Padi / Palawija',
      hasSurvey: json['survey'] != null,
    );
  }
}
