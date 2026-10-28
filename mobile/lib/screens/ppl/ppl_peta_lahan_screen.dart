import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../models/ppl_task_model.dart';
import 'ppl_pengukuran_batas_screen.dart';

class PPLPetaLahanScreen extends StatefulWidget {
  final PPLTaskModel? task;

  const PPLPetaLahanScreen({super.key, this.task});

  @override
  State<PPLPetaLahanScreen> createState() => _PPLPetaLahanScreenState();
}

class _PPLPetaLahanScreenState extends State<PPLPetaLahanScreen> {
  late final MapController _mapController;
  late PPLTaskModel _task;

  // Koordinat acuan awal petani
  late LatLng _petaniLocation;
  // Posisi PPL Standby (sedikit di selatan titik usulan petani)
  late LatLng _pplLocation;

  bool _isSatelliteLayer = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _task = widget.task ??
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
          alamatLahan: 'Dusun Sumberarum, Desa Tanjungrejo, Kec. Mojosari',
          luasLahanM2: 8000.0,
          latitude: -7.526412,
          longitude: 112.534218,
          komoditas: 'Padi Inpari 32',
          hasSurvey: false,
          taskIdCode: 'SRV-2025-014',
          jadwal: '14 Feb 2025 • Pagi',
          poktan: 'Poktan Tani Makmur Wilbin Mojosari',
          desaKecamatan: 'Dusun Sumberarum, Desa Tanjungrejo, Kec. Mojosari',
          statusLabel: 'Menunggu Survei',
        );
    _petaniLocation = LatLng(_task.latitude, _task.longitude);
    _pplLocation = LatLng(_task.latitude - 0.0006, _task.longitude - 0.0003);
  }

  // Poligon perkiraan draft (kotak batas kasar belum diukur)
  List<LatLng> get _draftBoxCoords {
    final double lat = _petaniLocation.latitude;
    final double lng = _petaniLocation.longitude;
    return [
      LatLng(lat + 0.00035, lng - 0.00045),
      LatLng(lat + 0.00035, lng + 0.00045),
      LatLng(lat - 0.00035, lng + 0.00045),
      LatLng(lat - 0.00035, lng - 0.00045),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double luasHa = _task.luasLahanM2 / 10000.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'E-PUPUK MOJOKERTO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Survei',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.darkGreen,
              child: const Text('AH', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigasi Back Sub-header & Chip Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Detail Tugas Survei (${_task.taskIdCode})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.satellite_alt_outlined, size: 12, color: AppTheme.primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'Citra Satelit & Lokasi Awal',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar Tahap 4 dari 5 (80%)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: AppTheme.primaryGreen,
                            child: const Text('4', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'TAHAP 4 DARI 5',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                      const Text(
                        '80%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.80,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Verifikasi lokasi spasial awal lahan petani sebelum proses plotting poligon fisik.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card Pemilik Garapan
            _buildFarmerLandCard(luasHa),
            const SizedBox(height: 16),

            // Peta Citra Satelit Interaktif
            _buildInteractiveSatelliteMap(),
            const SizedBox(height: 16),

            // Section Status Kesiapan & Verifikasi (e-RDKK Spasial)
            _buildVerificationStatusSection(),
            const SizedBox(height: 14),

            // Warning Box Protokol Verifikasi Fisik
            _buildProtocolNotice(),
            const SizedBox(height: 20),

            // Tombol Aksi Bawah
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerLandCard(double luasHa) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_outlined, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'PEMILIK GARAPAN',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                    ),
                    SizedBox(height: 1),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PTT-351608-0042',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _task.namaPetani,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            _task.poktan,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            'PLN-001 (${_task.lokasiLahan})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 12),

          // 2 Kotak Metrik: Luas Pengajuan vs Luas Dokumen
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Luas Pengajuan',
                        style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.crop_square, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            '${luasHa.toStringAsFixed(2)} Ha',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        '(${_task.luasLahanM2.toInt()} m²)',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Luas Dokumen',
                        style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            '${luasHa.toStringAsFixed(2)} Ha',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        '(${_task.luasLahanM2.toInt()} m²)',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _task.alamatLahan,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSatelliteMap() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header Overlay Peta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.satellite_alt, size: 16, color: AppTheme.primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      'Citra Satelit • Persawahan Mojokerto',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _isSatelliteLayer = !_isSatelliteLayer),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(_isSatelliteLayer ? Icons.layers : Icons.satellite_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _isSatelliteLayer ? 'Satelit' : 'Peta Jalan',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Peta Widget
          SizedBox(
            height: 290,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _petaniLocation,
                    initialZoom: 17.5,
                    maxZoom: 19.0,
                    minZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _isSatelliteLayer
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.epupuk.mobile',
                      errorTileCallback: (tile, error, stackTrace) {
                        // Graceful handling jika koneksi tile terganggu
                      },
                    ),

                    // Garis Batas Kotak Putus-putus Perkiraan (Draft)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _draftBoxCoords,
                          color: const Color(0x22F59E0B),
                          borderColor: const Color(0xFFD97706),
                          borderStrokeWidth: 2.0,
                          isFilled: true,
                        ),
                      ],
                    ),

                    // Marker Titik Awal Petani
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _petaniLocation,
                          width: 140,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_petaniLocation.latitude.toStringAsFixed(6)}, ${_petaniLocation.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(Icons.location_on, color: Color(0xFFB45309), size: 32),
                            ],
                          ),
                        ),
                        // Marker PPL Standby
                        Marker(
                          point: _pplLocation,
                          width: 40,
                          height: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Label Floating di tengah batas tapak sawah
                Positioned(
                  top: 130,
                  left: 30,
                  right: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.straighten, size: 13, color: Color(0xFFD97706)),
                        SizedBox(width: 4),
                        Text(
                          'Batas aktual belum diukur di lapangan',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Zoom & Recenter
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Column(
                    children: [
                      _buildMapIconButton(
                        icon: Icons.add,
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildMapIconButton(
                        icon: Icons.remove,
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildMapIconButton(
                        icon: Icons.my_location,
                        onTap: () => _mapController.move(_petaniLocation, 17.5),
                      ),
                    ],
                  ),
                ),

                // Legend di pojok kanan bawah
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFB45309), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('Titik Awal Pengajuan (Draft)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('Posisi PPL Standby', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildVerificationStatusSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Status Kesiapan & Verifikasi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Text(
                'e-RDKK Spasial',
                style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.location_on_outlined,
            label: 'Koordinat Awal Petani',
            badgeText: (_task.latitude != 0.0 && _task.longitude != 0.0)
                ? 'Ada Koordinat Awal'
                : 'Belum Ada Koordinat',
            badgeBg: (_task.latitude != 0.0 && _task.longitude != 0.0)
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEF3C7),
            badgeFg: (_task.latitude != 0.0 && _task.longitude != 0.0)
                ? AppTheme.primaryGreen
                : const Color(0xFFD97706),
          ),
          const SizedBox(height: 10),
          _buildStatusRow(
            icon: Icons.polyline_outlined,
            label: 'Pengukuran Poligon PPL',
            badgeText: _task.hasSurvey && _task.polygonCoords != null
                ? 'Sudah Diukur'
                : (_task.hasSurvey ? 'Survei Ada (Tanpa Poligon)' : 'Belum Dimulai'),
            badgeBg: _task.hasSurvey && _task.polygonCoords != null
                ? const Color(0xFFDCFCE7)
                : (_task.hasSurvey ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
            badgeFg: _task.hasSurvey && _task.polygonCoords != null
                ? AppTheme.primaryGreen
                : (_task.hasSurvey ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.satellite_alt, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sensor GPS / Status Digitasi',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const Text(
                        'Tekan "Input Koordinat & Batas Lahan" untuk memulai pengukuran',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Standby • Siap Input Lapangan',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeFg),
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protokol Verifikasi Fisik',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 2),
                Text(
                  'Lokasi awal hanya referensi pendaftaran petani. Tapak batas fisik wajib diukur dan diinput langsung oleh PPL di lapangan bersama penggarap atau perwakilan kelompok tani.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF92400E), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PPLPengukuranBatasScreen(task: _task),
                ),
              );
            },
            icon: const Icon(Icons.polyline, color: Colors.white, size: 18),
            label: const Text(
              'Input Koordinat & Batas Lahan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 16),
            label: const Text(
              'Kembali ke Tugas Survei',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

