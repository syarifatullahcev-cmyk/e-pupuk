import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../models/farmer_model.dart';
import '../../models/ppl_task_model.dart';
import '../../services/ppl_service.dart';
import 'ppl_detail_tugas_screen.dart';
import 'ppl_peta_lahan_screen.dart';

class PPLDetailPetaniScreen extends StatefulWidget {
  final FarmerModel farmer;

  const PPLDetailPetaniScreen({super.key, required this.farmer});

  @override
  State<PPLDetailPetaniScreen> createState() => _PPLDetailPetaniScreenState();
}

class _PPLDetailPetaniScreenState extends State<PPLDetailPetaniScreen> {
  late FarmerModel _farmer;
  List<PPLTaskModel> _farmerTasks = [];
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _farmer = widget.farmer;
    _refreshFarmerDetail();
    _loadFarmerTasks();
  }

  Future<void> _refreshFarmerDetail() async {
    final updated = await PPLService.getFarmerDetail(widget.farmer.id);
    if (mounted) {
      setState(() {
        _farmer = updated;
      });
    }
  }

  Future<void> _loadFarmerTasks() async {
    setState(() => _isLoadingTasks = true);
    final allTasks = await PPLService.getAssignedTasks();
    if (mounted) {
      setState(() {
        _farmerTasks = allTasks.where((t) => t.farmerId == widget.farmer.id).toList();
        _isLoadingTasks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Petani',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.darkGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFarmerHeaderCard(),
            const SizedBox(height: 18),
            _buildRegisteredLandsSection(),
            const SizedBox(height: 18),
            _buildCoordinateInfoSection(),
            const SizedBox(height: 18),
            _buildSupportingDocsSection(),
            const SizedBox(height: 18),
            _buildPreSurveySummarySection(),
            const SizedBox(height: 22),
            _buildBottomActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 1. Farmer Header Card
  Widget _buildFarmerHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  _farmer.initials,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _farmer.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${_farmer.maskedNik} (NIK Terproteksi)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: const Text(
                  'RDKK 2025',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.group_outlined, 'Kelompok Tani: ${_farmer.poktan} (Wilbin Mojosari)'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.location_on_outlined, 'Domisili KTP: ${_farmer.alamat}'),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _farmer.kontak,
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Terdaftar',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warningBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Status Berkas: ',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
                Icon(Icons.hourglass_bottom, size: 13, color: AppTheme.warningOrange),
                SizedBox(width: 3),
                Text(
                  'Menunggu Lapangan',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  // 2. Data Lahan Terdaftar Section
  Widget _buildRegisteredLandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.crop_landscape, size: 18, color: AppTheme.primaryGreen),
                SizedBox(width: 6),
                Text(
                  'Data Lahan Terdaftar (2 Bidang)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Text(
              'Total 1,4 Ha',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lahan 1: Sawah Blok Timur Kebondalem (PLN-001)
        _buildLandCardWithMap(
          code: 'PLN-001',
          statusPolygon: 'Poligon Awal Tersedia',
          version: 'Batas Spasial V.1',
          namaLahan: 'Sawah Blok Timur Kebondalem',
          komoditas: 'Padi Inpari 32',
          luasDokumen: '0,80 Ha (8.000 m²)',
          luasRdkk: '0,80 Ha (8.000 m²)',
          luasGis: '0,785 Ha (7.850 m² — Tahap 4)',
          coordinates: '• -7.5264° S, 112.5342° E',
        ),

        const SizedBox(height: 12),

        // Lahan 2: Tegal Sawah Blok Selatan (PLN-002) - Belum Ada Poligon
        _buildLandCardWithoutPolygon(
          code: 'PLN-002',
          statusSurvei: 'Menunggu Survei Lapangan',
          version: 'Batas Fisik Belum Ada',
          namaLahan: 'Tegal Sawah Blok Selatan',
          komoditasDanLuas: 'Jagung Hibrida • 0,6 Ha (6.000 m²)',
        ),
      ],
    );
  }

  Widget _buildLandCardWithMap({
    required String code,
    required String statusPolygon,
    required String version,
    required String namaLahan,
    required String komoditas,
    required String luasDokumen,
    required String luasRdkk,
    required String luasGis,
    required String coordinates,
  }) {
    final polygonPts = [
      const LatLng(-7.526012, 112.533812),
      const LatLng(-7.526012, 112.534618),
      const LatLng(-7.526812, 112.534618),
      const LatLng(-7.526812, 112.533812),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.darkGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 12, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          statusPolygon,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                version,
                style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            namaLahan,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.eco, size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 4),
              Text(
                'Komoditas : $komoditas',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Box Info Luas
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildLuasRow(Icons.description_outlined, 'Luas Dokumen (SPPT/Sertifikat):', luasDokumen),
                const SizedBox(height: 5),
                _buildLuasRow(Icons.file_copy_outlined, 'Luas Pengajuan (RDKK):', luasRdkk),
                const SizedBox(height: 5),
                _buildLuasRow(Icons.polyline, 'Luas Hasil Ukur GIS:', luasGis, isHighlight: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Mini Map Sentinel-2 Satellite
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 140,
              child: Stack(
                children: [
                  FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(-7.526412, 112.534218),
                      initialZoom: 17.0,
                      interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.epupuk.mobile',
                      ),
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: polygonPts,
                            color: const Color(0x66078A61),
                            borderColor: AppTheme.primaryGreen,
                            borderStrokeWidth: 2.5,
                            isFilled: true,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: const LatLng(-7.526412, 112.534218),
                            width: 130,
                            height: 26,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '0.8 Ha • $komoditas',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Citra Sentinel-2 • Valid',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        coordinates,
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PPLPetaLahanScreen()),
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 16, color: AppTheme.darkGreen),
                label: const Text('Lihat Peta Lahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Text('Lihat Detail Lahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                label: const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primaryGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuasRow(IconData icon, String title, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isHighlight ? AppTheme.primaryGreen : AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: isHighlight ? AppTheme.primaryGreen : AppTheme.textSecondary,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppTheme.primaryGreen : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLandCardWithoutPolygon({
    required String code,
    required String statusSurvei,
    required String version,
    required String namaLahan,
    required String komoditasDanLuas,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusSurvei,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                    ),
                  ),
                ],
              ),
              Text(
                version,
                style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            namaLahan,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            komoditasDanLuas,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          // Dashed border placeholder container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: AppTheme.textSecondary, size: 22),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Poligon belum tersedia',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Menunggu survei lapangan PPL untuk penetapan patok koordinat batas fisik tanah garapan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Text('Lihat Detail Lahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              label: const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Informasi Koordinat
  Widget _buildCoordinateInfoSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.pin_drop_outlined, size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Informasi Koordinat',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Koordinat Tersedia',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Titik Pusat Input Mandiri Petani:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Latitude', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      SizedBox(height: 2),
                      Text('-7.526412', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Longitude', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      SizedBox(height: 2),
                      Text('112.534218', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 16, color: AppTheme.warningOrange),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: Koordinat awal dari petani — belum diverifikasi lapangan terhadap patok batas sertifikat/fisik. Verifikasi spasial wajib dilakukan pada survei lapangan.',
                    style: TextStyle(fontSize: 11, color: AppTheme.warningOrange, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Dokumen Pendukung
  Widget _buildSupportingDocsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Dokumen Pendukung',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Text(
                '3 Berkas',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDocItem(
            icon: Icons.badge_outlined,
            iconColor: AppTheme.primaryGreen,
            title: 'KTP Elektronik Petani',
            status: 'Sudah Diperiksa ✓',
            statusColor: AppTheme.primaryGreen,
          ),
          const Divider(height: 16, color: AppTheme.border),
          _buildDocItem(
            icon: Icons.description_outlined,
            iconColor: AppTheme.warningOrange,
            title: 'Sertifikat Tanah / SPPT PBB',
            subtitle: 'NOP: 35.16.088...0041',
            status: 'Menunggu Pemeriksaan',
            statusColor: AppTheme.warningOrange,
            note: 'Catatan: Sertifikat atau SPPT PBB merupakan dokumen pendukung administratif dan tidak otomatis membuktikan batas GPS atau menghasilkan poligon.',
          ),
          const Divider(height: 16, color: AppTheme.border),
          _buildDocItem(
            icon: Icons.home_work_outlined,
            iconColor: AppTheme.warningOrange,
            title: 'Surat Garap / Sewa Desa',
            status: 'Menunggu Pemeriksaan',
            statusColor: AppTheme.warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required String status,
    required Color statusColor,
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                    const SizedBox(height: 2),
                    Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Membuka arsip $title')),
                );
              },
              child: const Text('Lihat Dokumen', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
            ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningBg.withOpacity(0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              note,
              style: const TextStyle(fontSize: 10.5, color: AppTheme.warningOrange, height: 1.3),
            ),
          ),
        ],
      ],
    );
  }

  // 5. Ringkasan Pemeriksaan Pra-Survei
  Widget _buildPreSurveySummarySection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune, size: 16, color: AppTheme.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Ringkasan Pemeriksaan (Tahap Pra-Survei)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryGridItem('1. Data Petani', 'Sudah Diperiksa ✓', true)),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryGridItem('2. Koordinat Lahan', 'Perlu Verifikasi ⌛', false)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSummaryGridItem('3. Poligon Lahan', 'Belum Diperiksa 📍', false, subtitle: 'Phase 4 Survei')),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryGridItem('4. Dokumen', 'Menunggu Periksa ⌛', false, subtitle: '1/3 Disetujui')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGridItem(String title, String value, bool isSuccess, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSuccess ? AppTheme.primaryGreen : AppTheme.warningOrange,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ],
      ),
    );
  }

  // 6. Bottom Action Buttons
  Widget _buildBottomActionButtons() {
    final PPLTaskModel? activeTask = _farmerTasks.isNotEmpty ? _farmerTasks.first : null;

    void navigateToTask() {
      if (activeTask == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada tugas survei yang ditemukan untuk petani ini.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PPLDetailTugasScreen(task: activeTask),
        ),
      );
    }

    return Column(
      children: [
        // Primary Button: Mulai Survei Lapangan
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoadingTasks ? null : navigateToTask,
            icon: _isLoadingTasks
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
            label: Text(
              _isLoadingTasks ? 'Memuat...' : (activeTask != null ? 'Mulai Survei Lapangan' : 'Tidak Ada Tugas'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: activeTask != null ? AppTheme.darkGreen : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // back to tabs
                },
                icon: const Icon(Icons.list_alt, size: 16, color: AppTheme.darkGreen),
                label: const Text('Lihat Tugas Survei', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (activeTask != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PPLPetaLahanScreen(task: activeTask)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak ada data tugas untuk menampilkan peta.')),
                    );
                  }
                },
                icon: const Icon(Icons.map_outlined, size: 16, color: AppTheme.darkGreen),
                label: const Text('Lihat Peta Lahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Tertiary Button: Hubungi Petani
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Menghubungi ${_farmer.nama} (${_farmer.kontak}) via WhatsApp...')),
              );
            },
            icon: const Icon(Icons.chat_outlined, color: AppTheme.primaryGreen, size: 18),
            label: const Text(
              'Hubungi Petani (WhatsApp)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.lightGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
