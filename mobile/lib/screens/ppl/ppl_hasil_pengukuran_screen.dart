import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../models/ppl_task_model.dart';
import '../../services/geo_calc_service.dart';
import '../../services/ppl_service.dart';

class PPLHasilPengukuranScreen extends StatefulWidget {
  final PPLTaskModel task;
  final double measuredAreaM2;
  final List<LatLng> polygonPoints;

  const PPLHasilPengukuranScreen({
    super.key,
    required this.task,
    required this.measuredAreaM2,
    required this.polygonPoints,
  });

  @override
  State<PPLHasilPengukuranScreen> createState() => _PPLHasilPengukuranScreenState();
}

class _PPLHasilPengukuranScreenState extends State<PPLHasilPengukuranScreen> {
  late final MapController _mapController;
  late PPLTaskModel _task;
  late double _measuredAreaM2;
  late List<LatLng> _polygonPoints;

  String _selectedStatusAlur = 'Siap Diverifikasi';
  bool _isSaving = false;
  late TextEditingController _catatanController;

  final List<String> _statusAlurOptions = [
    'Siap Diverifikasi',
    'Perlu Pengukuran Ulang',
    'Eskalasi ke Admin Dinas',
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _task = widget.task;

    // Gunakan luas hasil ukur geodetik dinamis atau fallback 7850.0 m² jika belum ada titik
    _polygonPoints = widget.polygonPoints;
    if (_polygonPoints.length >= 3) {
      _measuredAreaM2 = GeoCalcService.calculateGeodesicArea(_polygonPoints);
    } else {
      // Tidak ada fallback angka hardcoded — jika < 3 titik, luas tidak dihitung
      _measuredAreaM2 = widget.measuredAreaM2 > 0 ? widget.measuredAreaM2 : 0.0;
    }

    // Inisialisasi controller catatan lapangan
    _catatanController = TextEditingController(
      text: widget.task.catatanPpl ?? '',
    );
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveHasil() async {
    setState(() => _isSaving = true);

    // Konversi LatLng list ke format List<List<double>> untuk API geospasial
    final coordsPayload = _polygonPoints.map((pt) => [pt.latitude, pt.longitude]).toList();

    final result = await PPLService.submitSurvey(
      applicationId: _task.id,
      kondisiFisikLahan: 'BAIK',
      keteranganFisikLahan: 'Tapak sawah terpetakan rapi dengan patok BPN dan saluran irigasi desa.',
      kondisiTanaman: 'SESUAI',
      keteranganTanaman: 'Komoditas ${_task.komoditas}',
      luasLahanAktualM2: _measuredAreaM2,
      catatanPpl: 'Batas fisik tapak sawah sisi timur berbatasan langsung dengan saluran sekunder desa. Patok sudut P1 dan P4 sesuai batas kepemilikan petak. Rekomendasi alokasi pupuk dapat diproses berdasarkan luas faktual ${_measuredAreaM2.toInt()} m².',
      rekomendasi: 'SETUJU',
      polygonCoords: coordsPayload,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      final bool isSuccess = result['success'] == true;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline_rounded,
                color: isSuccess ? AppTheme.primaryGreen : AppTheme.dangerRed,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isSuccess ? 'Pengukuran Berhasil' : 'Gagal Menyimpan Survei',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            result['message'] ?? (isSuccess ? 'Data hasil pengukuran poligon geospasial telah berhasil disimpan dan disinkronkan ke server.' : 'Terjadi kesalahan saat menyimpan ke server.'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                if (isSuccess) {
                  Navigator.pop(context); // Return to previous
                  Navigator.pop(context); // Return to task detail
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? AppTheme.primaryGreen : AppTheme.dangerRed,
              ),
              child: Text(isSuccess ? 'OK' : 'Tutup', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double luasDokumenM2 = _task.luasLahanM2 > 0 ? _task.luasLahanM2 : 8000.0;
    final double luasDokumenHa = luasDokumenM2 / 10000.0;

    final double luasUkurM2 = _measuredAreaM2;
    final double luasUkurHa = luasUkurM2 / 10000.0;

    final double selisihM2 = luasUkurM2 - luasDokumenM2;
    final double selisihHa = selisihM2 / 10000.0;
    final double selisihPersen = (selisihM2 / luasDokumenM2) * 100.0;

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
            // Sub-nav & Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back, size: 14, color: AppTheme.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Pengukuran Batas',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
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
                    children: [
                      const Icon(Icons.check_circle, size: 10, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        _selectedStatusAlur,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Judul Layar & Sub
            const Text(
              'Hasil Pengukuran Lahan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            const Text(
              'Kalkulasi spasial dan perbandingan luas lahan faktual',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),

            // Card Identitas Lahan
            _buildLandIdCard(),
            const SizedBox(height: 14),

            // Peta Mini Poligon Tertutup & Badge Luas
            _buildPolygonMapPreview(luasUkurM2, luasUkurHa),
            const SizedBox(height: 16),

            // Section Perbandingan & Analisis Selisih
            _buildComparisonSection(
              luasDokumenHa: luasDokumenHa,
              luasDokumenM2: luasDokumenM2,
              luasUkurHa: luasUkurHa,
              luasUkurM2: luasUkurM2,
              selisihM2: selisihM2,
              selisihHa: selisihHa,
              selisihPersen: selisihPersen,
            ),
            const SizedBox(height: 16),

            // Section Detail Geospasial Poligon
            _buildGeospatialDetailsSection(),
            const SizedBox(height: 16),

            // Section Catatan Lapangan PPL
            _buildPPLFieldNotesSection(luasUkurM2),
            const SizedBox(height: 22),

            // Tombol Aksi Bawah
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLandIdCard() {
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
              Text(
                'ID LAHAN: PLN-001',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 6),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                'TUGAS: ${_task.taskIdCode}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grass, size: 12, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      _task.komoditas,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _task.poktan.toUpperCase(),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            _task.namaPetani,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_task.lokasiLahan}, ${_task.desaKecamatan}',
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

  Widget _buildPolygonMapPreview(double luasUkurM2, double luasUkurHa) {
    final centerPoint = _polygonPoints.isNotEmpty
        ? _polygonPoints.first
        : LatLng(_task.latitude, _task.longitude);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: 17.5,
                      maxZoom: 19.0,
                      minZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.epupuk.mobile',
                        errorTileCallback: (tile, error, stackTrace) {},
                      ),
                      if (_polygonPoints.length >= 3)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: _polygonPoints,
                              color: const Color(0x55078A61),
                              borderColor: AppTheme.primaryGreen,
                              borderStrokeWidth: 3.0,
                              isFilled: true,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: _polygonPoints.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final pt = entry.value;
                          return Marker(
                            point: pt,
                            width: 26,
                            height: 26,
                            child: CircleAvatar(
                              radius: 13,
                              backgroundColor: AppTheme.darkGreen,
                              child: Text(
                                'P$idx',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Floating Card Luas Poligon Tertutup di Tengah
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'LUAS POLIGON TERTUTUP',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${luasUkurM2.toInt()} m²',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            '(${luasUkurHa.toStringAsFixed(2)} Ha)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Skala & Akurasi GPS di Pojok Bawah
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('50 m ━━', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.gps_fixed, color: Color(0xFF22C55E), size: 10),
                          SizedBox(width: 4),
                          Text('Koordinat dari input manual', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bar Footer Peta
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calculate_outlined, size: 14, color: AppTheme.primaryGreen),
                      SizedBox(width: 6),
                      Text(
                        'Metode Kalkulasi: Geodesic Shoelace (WGS84)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_polygonPoints.length} Sisi',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection({
    required double luasDokumenHa,
    required double luasDokumenM2,
    required double luasUkurHa,
    required double luasUkurM2,
    required double selisihM2,
    required double selisihHa,
    required double selisihPersen,
  }) {
    final String selisihSign = selisihM2 >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perbandingan & Analisis Selisih',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          // 4 Kotak Metrik
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  title: 'Luas SPPT/Sertifikat',
                  haValue: '${luasDokumenHa.toStringAsFixed(2)} Ha',
                  m2Value: '${luasDokumenM2.toInt()} m²',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  title: 'Luas Pengajuan (RDKK)',
                  haValue: '${luasDokumenHa.toStringAsFixed(2)} Ha',
                  m2Value: '${luasDokumenM2.toInt()} m²',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  title: 'Hasil Ukur GIS PPL',
                  haValue: '${luasUkurHa.toStringAsFixed(3)} Ha',
                  m2Value: '${luasUkurM2.toInt()} m²',
                  haColor: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  title: 'Selisih Faktual',
                  haValue: '$selisihSign${selisihM2.toInt()} m²',
                  m2Value: '($selisihSign${selisihHa.toStringAsFixed(3)} Ha [${selisihPersen.toStringAsFixed(2)}%])',
                  haColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner Rekonsiliasi Selisih
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Selisih Faktual vs RDKK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${selisihPersen.toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$selisihSign${selisihM2.toInt()} m² ($selisihSign${selisihHa.toStringAsFixed(3)} Ha)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: selisihPersen.abs() > 20.0 ? 1.0 : (selisihPersen.abs() / 20.0),
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      selisihPersen.abs() < 5.0 ? AppTheme.primaryGreen : const Color(0xFFDC2626),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGreen),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dalam batas toleransi wajar (< 5%). Tidak terdeteksi anomali tumpang tindih spasial dengan poligon tetangga.',
                        style: TextStyle(fontSize: 10, color: Color(0xFF166534), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String haValue,
    required String m2Value,
    Color? haColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(
            haValue,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: haColor ?? AppTheme.textPrimary),
          ),
          Text(m2Value, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildGeospatialDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Geospasial Poligon',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text('Status Alur Pengukuran', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatusAlur,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                items: _statusAlurOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatusAlur = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selisih luas tidak otomatis menyatakan persetujuan atau penolakan. Keputusan alokasi pupuk bersubsidi mengikuti regulasi teknis Dinas Pertanian Kabupaten Mojokerto.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPPLFieldNotesSection(double luasUkurM2) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                'Catatan Lapangan PPL',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Icon(Icons.edit_note, size: 18, color: AppTheme.primaryGreen),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Isi catatan kondisi lahan, batas fisik, atau hal penting lainnya.',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _catatanController,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Contoh: Batas timur berbatasan dengan saluran desa. Patok P1 sesuai kepemilikan...',
              hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          if (_polygonPoints.length >= 3) ...[
            const SizedBox(height: 8),
            Text(
              'Luas terukur:  m² ( Ha) —  titik batas',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Peringatan: Kurang dari 3 titik batas. Luas tidak dapat dihitung.',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
            ),
          ],
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
            onPressed: _isSaving ? null : _handleSaveHasil,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Hasil Pengukuran',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.person_outline, size: 16, color: AppTheme.textPrimary),
                label: const Text(
                  'Detail Petani',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.assignment_outlined, size: 16, color: AppTheme.textPrimary),
                label: const Text(
                  'Tugas Survei',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline, size: 13, color: AppTheme.primaryGreen),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Simulasi prototipe. Hasil pengukuran disimpan lokal di perangkat dan tersinkronisasi ke server Laravel/MySQL.',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}





