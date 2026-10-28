import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../models/ppl_task_model.dart';
import '../../models/user_model.dart';
import '../../services/ppl_service.dart';
import 'ppl_detail_tugas_screen.dart';
import 'ppl_peta_lahan_screen.dart';

class PPLBerandaScreen extends StatefulWidget {
  final UserModel user;
  final Function(int) onTabChange;

  const PPLBerandaScreen({
    super.key,
    required this.user,
    required this.onTabChange,
  });

  @override
  State<PPLBerandaScreen> createState() => _PPLBerandaScreenState();
}

class _PPLBerandaScreenState extends State<PPLBerandaScreen> {
  List<PPLTaskModel> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final MapController _miniMapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tasks = await PPLService.getAssignedTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 16),
                _buildGreetingSection(),
                const SizedBox(height: 14),
                _buildProfileCard(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildSummarySection(),
                const SizedBox(height: 22),
                _buildPriorityTasksSection(),
                const SizedBox(height: 22),
                _buildSurveyLocationSection(),
                const SizedBox(height: 24),
                _buildFooter(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Top Bar Header
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.eco,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'E-PUPUK • KAB. MOJOKERTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.darkGreen,
                  ),
                ),
                Text(
                  'Beranda',
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
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppTheme.textPrimary, size: 24),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak ada notifikasi baru hari ini.')),
                );
              },
            ),
            GestureDetector(
              onTap: () => widget.onTabChange(4), // Go to Profile
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppTheme.darkGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Greeting Section
  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Selamat pagi, Ahmad 👋',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Siap melanjutkan survei lapangan hari ini?',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // 3. Profile Card
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'AH',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Ahmad, S.P.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Petugas Penyuluh Lapangan (PPL)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Aktif Bertugas',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'BPP Wilayah Mojosari — Kab. Mojokerto',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
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

  // 4. Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari nama petani, NIK, atau lokasi lahan...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onTabChange(1); // Go to Petani Tab
          }
        },
      ),
    );
  }

  // 5. Ringkasan Hari Ini
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.primaryGreen),
                SizedBox(width: 6),
                Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Text(
              'Mojokerto Raya',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Card Belum Disurvei
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Belum Disurvei',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.warningOrange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_tasks.where((t) => !t.hasSurvey).length}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tugas menanti verifikasi',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card Menunggu Validasi
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Menunggu Validasi',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.verified_outlined, size: 14, color: AppTheme.infoBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_tasks.where((t) => t.status == 'MENUNGGU_PERSETUJUAN_AKHIR').length}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Laporan ke Dinas',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 6. Tugas Prioritas
  Widget _buildPriorityTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.flag_outlined, size: 16, color: AppTheme.primaryGreen),
                SizedBox(width: 6),
                Text(
                  'Tugas Prioritas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => widget.onTabChange(2), // Go to Survei Tab
              child: Row(
                children: const [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryGreen),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primaryGreen)))
        else if (_tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Tidak ada tugas survei saat ini.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...List.generate(_tasks.take(3).length, (i) => [
            if (i > 0) const SizedBox(height: 12),
            _buildPriorityTaskCard(task: _tasks[i]),
          ]).expand((e) => e),
      ],
    );
  }

  Widget _buildPriorityTaskCard({required PPLTaskModel task}) {
    // Derive display values from task data
    final bool isSurveyed = task.hasSurvey;
    final String statusLabel;
    final Color statusColor;
    final Color statusBg;
    final String buttonText;
    final IconData buttonIcon;

    switch (task.status) {
      case 'SELESAI':
      case 'DISETUJUI':
        statusLabel = 'Selesai';
        statusColor = AppTheme.primaryGreen;
        statusBg = AppTheme.lightGreen;
        buttonText = 'Lihat Hasil';
        buttonIcon = Icons.visibility_outlined;
        break;
      case 'DALAM_PROSES':
      case 'MENUNGGU_PERSETUJUAN_AKHIR':
        statusLabel = 'Dalam Proses';
        statusColor = AppTheme.infoBlue;
        statusBg = AppTheme.infoBg;
        buttonText = 'Lanjutkan';
        buttonIcon = Icons.edit_note;
        break;
      case 'DITOLAK':
        statusLabel = 'Ditolak';
        statusColor = Colors.red;
        statusBg = const Color(0xFFFFEBEB);
        buttonText = 'Perbaiki';
        buttonIcon = Icons.edit_outlined;
        break;
      default:
        statusLabel = isSurveyed ? 'Sudah Disurvei' : 'Belum Dimulai';
        statusColor = isSurveyed ? AppTheme.primaryGreen : AppTheme.warningOrange;
        statusBg = isSurveyed ? AppTheme.lightGreen : AppTheme.warningBg;
        buttonText = isSurveyed ? 'Lihat Hasil' : 'Mulai Survei';
        buttonIcon = isSurveyed ? Icons.visibility_outlined : Icons.play_circle_outline;
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.infoBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline, color: AppTheme.infoBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.namaPetani,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.desaKecamatan.isNotEmpty ? task.desaKecamatan : task.alamatLahan,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    task.komoditas.toLowerCase().contains('jagung') ? Icons.grass : Icons.eco,
                    size: 15,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    task.komoditas.isNotEmpty ? task.komoditas : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                task.taskIdCode,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PPLDetailTugasScreen(task: task),
                  ),
                );
              },
              icon: Icon(buttonIcon, size: 18, color: Colors.white),
              label: Text(
                buttonText,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 7. Lokasi Survei (Peta Mini Interaktif)
  Widget _buildSurveyLocationSection() {
    // Koordinat poligon contoh sawah Kebondalem Mojosari
    final samplePolygon = [
      const LatLng(-7.5255, 112.5330),
      const LatLng(-7.5255, 112.5350),
      const LatLng(-7.5270, 112.5350),
      const LatLng(-7.5270, 112.5330),
    ];

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.map_outlined, size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Lokasi Survei',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PPLPetaLahanScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.layers_outlined, size: 14, color: AppTheme.primaryGreen),
                label: const Text(
                  'Buka Peta',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Lihat lokasi dan batas poligon lahan petani.',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          // Interactive Mini Map Container
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 150,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _miniMapController,
                    options: const MapOptions(
                      initialCenter: LatLng(-7.5264, 112.5342),
                      initialZoom: 16.2,
                      interactionOptions: InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.epupuk.mobile',
                      ),
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: samplePolygon,
                            color: const Color(0x55078A61),
                            borderColor: AppTheme.primaryGreen,
                            borderStrokeWidth: 2,
                            isFilled: true,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: const LatLng(-7.52625, 112.5340),
                            width: 70,
                            height: 24,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '0.8 Ha • Padi',
                                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Zoom control buttons
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Column(
                      children: [
                        _buildMiniMapBtn(Icons.add, () {
                          final currentZoom = _miniMapController.camera.zoom;
                          _miniMapController.move(_miniMapController.camera.center, currentZoom + 1);
                        }),
                        const SizedBox(height: 4),
                        _buildMiniMapBtn(Icons.remove, () {
                          final currentZoom = _miniMapController.camera.zoom;
                          _miniMapController.move(_miniMapController.camera.center, currentZoom - 1);
                        }),
                      ],
                    ),
                  ),
                  // Coordinates banner bottom
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: const [
                          CircleAvatar(radius: 3, backgroundColor: AppTheme.primaryGreen),
                          SizedBox(width: 4),
                          Text(
                            '7.5264° S, 112.5342° E • Mojosari',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }

  // 8. Footer
  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.eco, color: AppTheme.primaryGreen, size: 14),
          SizedBox(width: 6),
          Text(
            'Dinas Pertanian Kabupaten Mojokerto © 2024',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
