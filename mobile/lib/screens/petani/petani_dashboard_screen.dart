import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/subsidy_models.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/subsidy_service.dart';
import '../auth/login_screen.dart';

class PetaniDashboardScreen extends StatefulWidget {
  final UserModel user;

  const PetaniDashboardScreen({super.key, required this.user});

  @override
  State<PetaniDashboardScreen> createState() => _PetaniDashboardScreenState();
}

class _PetaniDashboardScreenState extends State<PetaniDashboardScreen> {
  // Palet Warna Resmi E-Pupuk Mojokerto (Persis seperti di desain & Web)
  static const Color darkEmerald = Color(0xFF064E3B);
  static const Color primaryGreen = Color(0xFF009B69);
  static const Color textDark = Color(0xFF0F172A);
  static const Color slateBg = Color(0xFFF8FAFC);
  static const Color borderGray = Color(0xFFE2E8F0);

  // Tab Navigasi Aktif (0: Dashboard, 1: Profil, 2: Lahan, 3: Pengajuan, 4: Status, 5: Kuota, 6: Pembukaan, 7: Riwayat)
  int _activeNav = 0;
  // Bottom Bar Selected Index (0: Beranda, 1: Lahan, 2: Scan QR, 3: Status, 4: Akun)
  int _bottomNavIndex = 0;

  bool _isLoading = true;

  // Data State
  DashboardStatsModel? _stats;
  FarmerProfileModel? _farmer;
  List<LandModel> _lands = [];
  List<ApplicationModel> _applications = [];
  List<FertilizerModel> _fertilizers = [];
  List<CommodityModel> _commodities = [];
  // ignore: unused_field
  List<DistributionModel> _distributions = [];
  List<ScanHistoryModel> _scans = [];

  // Form Pengajuan Subsidi State
  int? _formLandId;
  int? _formFertilizerId;
  final TextEditingController _formJumlahCtrl = TextEditingController();
  bool _isSubmittingApp = false;

  // Pembukaan Pupuk Flow State ('gps' | 'scan' | 'result' | 'success') persis Screenshot
  String _pembukaanStep = 'gps';
  double _simulatedDistance = 18.0;
  final TextEditingController _qrManualCtrl = TextEditingController(text: 'EPUPUK-1-BUDISA-84108C');

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _formJumlahCtrl.dispose();
    _qrManualCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SubsidyService.getFarmerProfile(),
        SubsidyService.getStats(),
        SubsidyService.getLands(),
        SubsidyService.getApplications(),
        SubsidyService.getFertilizers(),
        SubsidyService.getCommodities(),
        SubsidyService.getDistributions(),
        SubsidyService.getMyScans(),
      ]);

      if (mounted) {
        setState(() {
          _farmer = results[0] as FarmerProfileModel?;
          _stats = results[1] as DashboardStatsModel?;
          _lands = results[2] as List<LandModel>;
          _applications = results[3] as List<ApplicationModel>;
          _fertilizers = results[4] as List<FertilizerModel>;
          _commodities = results[5] as List<CommodityModel>;
          _distributions = results[6] as List<DistributionModel>;
          _scans = results[7] as List<ScanHistoryModel>;

          if (_lands.isNotEmpty && _formLandId == null) {
            _formLandId = _lands.first.id;
          }
          if (_fertilizers.isNotEmpty && _formFertilizerId == null) {
            _formFertilizerId = _fertilizers.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Kalkulasi Kuota Dinamis
  double get _totalUreaUsed => _scans
      .where((s) => s.jenisPupuk.toLowerCase().contains('urea'))
      .fold(70.0, (sum, s) => sum + s.jumlahKg);

  double get _totalNpkUsed => _scans
      .where((s) => s.jenisPupuk.toLowerCase().contains('npk'))
      .fold(50.0, (sum, s) => sum + s.jumlahKg);

  double get _totalPupukDigunakan => _totalUreaUsed + _totalNpkUsed;

  double get _kuotaDisetujuiUrea => _applications
      .where((a) => ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].contains(a.status))
      .where((a) => (a.namaPupuk ?? '').toLowerCase().contains('urea'))
      .fold(500.0, (sum, a) => sum + (a.jumlahDisetujui ?? a.jumlahDiajukan));

  double get _sisaKuotaUrea => max(0.0, (_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea : 500.0) - _totalUreaUsed);

  double get _kuotaDisetujuiNpk => _applications
      .where((a) => ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].contains(a.status))
      .where((a) => (a.namaPupuk ?? '').toLowerCase().contains('npk'))
      .fold(400.0, (sum, a) => sum + (a.jumlahDisetujui ?? a.jumlahDiajukan));

  double get _sisaKuotaNpk => max(0.0, (_kuotaDisetujuiNpk > 0 ? _kuotaDisetujuiNpk : 400.0) - _totalNpkUsed);

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari Portal Petani?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // =========================================================================
  // APPBAR PERSIS SEPERTI DI GAMBAR
  // =========================================================================
  PreferredSizeWidget _buildCustomAppBar() {
    final displayName = _farmer?.nama ?? widget.user.nama;
    final initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFF1F5F9), height: 1),
      ),
      titleSpacing: 16,
      title: Row(
        children: [
          // Logo Hijau Sprout Rounded Square
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.eco_rounded, color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      'E-PUPUK',
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                        ),
                        child: const Text(
                          'KAB. MOJOKERTO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1.5),
                const Text(
                  'Sistem Subsidi & Distribusi Pupuk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Bell Notification with Red Badge "1"
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF334155), size: 22),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifikasi: Pengajuan subsidi pupuk telah diverifikasi.')),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Color(0xFFE11D48),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Avatar Circle "(B)" persis Screenshot
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF86EFAC), width: 1),
          ),
          child: Center(
            child: Text(
              initialLetter,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Logout Icon
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 20),
          onPressed: _handleLogout,
          tooltip: 'Keluar',
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // =========================================================================
  // 1. BANNER HIJAU TUA PERSIS SEPERTI DI GAMBAR
  // =========================================================================
  Widget _buildTopBanner() {
    final farmerName = _farmer?.nama ?? widget.user.nama;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: darkEmerald,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip "PORTAL PETANI & KELOMPOK TANI" persis Screenshot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF043E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.spa_rounded, size: 13, color: Color(0xFF6EE7B7)),
                SizedBox(width: 5),
                Text(
                  'PORTAL PETANI & KELOMPOK TANI',
                  style: TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Selamat Datang, $farmerName!',
            style: const TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sistem resmi verifikasi subsidi, pemantauan kuota, dan pemindaian QR Code pada karung pupuk fisik berbasis GPS geofencing.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. PILL NAVIGATION PERSIS SEPERTI DI GAMBAR & WEB
  // =========================================================================
  Widget _buildPillNavigation() {
    final navItems = [
      {'id': 0, 'label': 'Dashboard', 'icon': Icons.grid_view_rounded},
      {'id': 1, 'label': 'Profil Saya', 'icon': Icons.person_outline_rounded},
      {'id': 2, 'label': 'Data Lahan', 'icon': Icons.location_on_outlined},
      {'id': 3, 'label': 'Pengajuan Subsidi', 'icon': Icons.description_outlined},
      {'id': 4, 'label': 'Status Pengajuan', 'icon': Icons.access_time_rounded},
      {'id': 5, 'label': 'Kuota Pupuk', 'icon': Icons.pie_chart_outline_rounded},
      {'id': 6, 'label': 'Pembukaan Pupuk', 'icon': Icons.crop_free_rounded, 'special': true},
      {'id': 7, 'label': 'Riwayat Pembukaan', 'icon': Icons.history_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: navItems.map((item) {
            final int id = item['id'] as int;
            final bool isActive = _activeNav == id;
            final bool isSpecial = item['special'] == true;

            Color bgColor;
            Color textColor;
            Color iconColor;
            Border? border;

            if (isActive) {
              bgColor = const Color(0xFF009B69);
              textColor = Colors.white;
              iconColor = Colors.white;
              border = null;
            } else if (isSpecial) {
              bgColor = const Color(0xFFECFDF5);
              textColor = const Color(0xFF065F46);
              iconColor = const Color(0xFF047857);
              border = Border.all(color: const Color(0xFF34D399), width: 1.2);
            } else {
              bgColor = Colors.transparent;
              textColor = const Color(0xFF475569);
              iconColor = const Color(0xFF94A3B8);
              border = null;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: InkWell(
                onTap: () => setState(() => _activeNav = id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: border,
                    boxShadow: isActive
                        ? const [
                            BoxShadow(
                              color: Color(0x20009B69),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 15,
                        color: iconColor,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive || isSpecial ? FontWeight.bold : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (isSpecial && !isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. 4 KPI CARDS (2x2 GRID) PERSIS SEPERTI DI GAMBAR
  // =========================================================================
  Widget _buildKpiGrid() {
    final activeCount = _stats?.aktif ?? _applications.where((a) => !['TERSALURKAN', 'DITOLAK_BERKAS', 'DITOLAK_LAPANGAN'].contains(a.status)).length;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        // 1. Sisa Kuota Urea
        _buildExactKpiCard(
          title: 'SISA KUOTA UREA',
          valueNumber: '${_sisaKuotaUrea.toInt()}',
          unit: 'kg',
          subtitle: 'Dari kuota ${_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea.toInt() : 500} kg',
          icon: Icons.eco_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF009B69),
          badgeText: 'Subsidi',
          badgeBg: const Color(0xFFF1F5F9),
          badgeTextColor: const Color(0xFF475569),
        ),
        // 2. Sisa Kuota NPK
        _buildExactKpiCard(
          title: 'SISA KUOTA NPK',
          valueNumber: '${_sisaKuotaNpk.toInt()}',
          unit: 'kg',
          subtitle: 'Dari kuota ${_kuotaDisetujuiNpk > 0 ? _kuotaDisetujuiNpk.toInt() : 400} kg',
          icon: Icons.person_rounded,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          badgeText: 'Subsidi',
          badgeBg: const Color(0xFFE0F2FE),
          badgeTextColor: const Color(0xFF0369A1),
        ),
        // 3. Pengajuan Aktif
        _buildExactKpiCard(
          title: 'PENGAJUAN AKTIF',
          valueNumber: '$activeCount',
          unit: 'berkas',
          subtitle: 'Verifikasi & survei',
          icon: Icons.sync_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          badgeText: 'Aktif',
          badgeBg: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFB45309),
        ),
        // 4. Pupuk Digunakan
        _buildExactKpiCard(
          title: 'PUPUK DIGUNAKAN',
          valueNumber: '${_totalPupukDigunakan.toInt()}',
          unit: 'kg',
          subtitle: 'GPS Terverifikasi',
          icon: Icons.verified_user_rounded,
          iconBg: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF7C3AED),
          badgeText: 'Tervalidasi',
          badgeBg: const Color(0xFFF3E8FF),
          badgeTextColor: const Color(0xFF6D28D9),
        ),
      ],
    );
  }

  Widget _buildExactKpiCard({
    required String title,
    required String valueNumber,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Title + Circular Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 14),
                ),
              ),
            ],
          ),
          // Value Number + Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valueNumber,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          // Bottom Row: Subtitle + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. KARTU PROFIL PETANI PERSIS SEPERTI DI GAMBAR
  // =========================================================================
  Widget _buildProfilPetaniCard() {
    final farmerName = _farmer?.nama ?? widget.user.nama;
    final farmerNik = _farmer?.nik ?? '3516011208830001';
    final farmerPoktan = _farmer?.kelompokTani ?? 'Poktan Sumber Makmur';
    final farmerKontak = _farmer?.kontak ?? '081234567890';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: PROFIL PETANI + Data Terverifikasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_outline_rounded, color: primaryGreen, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'PROFIL PETANI',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: 0.4,
                          color: textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check, size: 11, color: Color(0xFF166534)),
                    SizedBox(width: 3.5),
                    Text(
                      'Data Terverifikasi',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nama Lengkap
          const Text('Nama Lengkap', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
          const SizedBox(height: 2),
          Text(farmerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textDark)),
          const SizedBox(height: 12),

          // 2-Column: NIK & Poktan
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NIK', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(
                      farmerNik,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kelompok Tani (Poktan)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(
                      farmerPoktan,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: textDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nomor HP / WhatsApp
          const Text('Nomor HP / WhatsApp', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
          const SizedBox(height: 2),
          Text(
            farmerKontak,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: textDark,
            ),
          ),
          const SizedBox(height: 14),

          // Button: Lihat Profil Selengkapnya >
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () => setState(() => _activeNav = 1),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Lihat Profil Selengkapnya',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4b. RINGKASAN KUOTA DASHBOARD PERSIS SCREENSHOT DASHBOARD
  // =========================================================================
  Widget _buildDashboardRingkasanKuotaCard() {
    final double ureaPercent = _kuotaDisetujuiUrea > 0 ? (_totalUreaUsed / _kuotaDisetujuiUrea) : 0.14;
    final double npkPercent = _kuotaDisetujuiNpk > 0 ? (_totalNpkUsed / _kuotaDisetujuiNpk) : 0.12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Detail >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.pie_chart_outline_rounded, color: primaryGreen, size: 18),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Ringkasan Kuota (Musim Tanam 2026)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _activeNav = 5),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Detail',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 15, color: primaryGreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. UREA BERSUBSIDI
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'UREA BERSUBSIDI',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                      ),
                      child: Text(
                        'Sisa ${_sisaKuotaUrea.toInt()} kg',
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Kuota Disetujui: ${_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea.toInt() : 500} kg',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Sudah Digunakan: ${_totalUreaUsed.toInt()} kg',
                        style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 10),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ureaPercent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(ureaPercent * 100).toInt()}% kuota terpakai',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. NPK PHONSKA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NPK PHONSKA',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
                      ),
                      child: Text(
                        'Sisa ${_sisaKuotaNpk.toInt()} kg',
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Kuota Disetujui: ${_kuotaDisetujuiNpk > 0 ? _kuotaDisetujuiNpk.toInt() : 400} kg',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Sudah Digunakan: ${_totalNpkUsed.toInt()} kg',
                        style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 10),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: npkPercent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(npkPercent * 100).toInt()}% kuota terpakai',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4c. STATUS PENGAJUAN TERKINI DASHBOARD PERSIS SCREENSHOT DASHBOARD & WEB
  // =========================================================================
  Widget _buildDashboardStatusPengajuanTerkini() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Status Pengajuan Terkini',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lacak perkembangan verifikasi & survei lahan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _activeNav = 4),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 15, color: primaryGreen),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_applications.isNotEmpty) ...[
          for (int i = 0; i < _applications.take(2).length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildDashboardApplicationCard(
              id: '#${_applications[i].id}',
              title: 'Pupuk ${_applications[i].namaPupuk ?? "Urea Bersubsidi"}',
              weightChange: '— ${(_applications[i].jumlahDisetujui ?? _applications[i].jumlahDiajukan).toStringAsFixed(2)} kg',
              location: 'Lahan: ${_applications[i].lokasiLahan ?? "Sawah Blok Timur Kebondalem"}',
              status: _applications[i].status,
            ),
          ],
        ] else ...[
          // Fallback demo cards (Status DIJADWALKAN_DISTRIBUSI / Siap Diambil)
          _buildDashboardApplicationCard(
            id: '#6',
            title: 'Pupuk Urea Bersubsidi',
            weightChange: '— 70.00 kg',
            location: 'Lahan: Sawah Blok Timur Kebondalem',
            status: 'DIJADWALKAN_DISTRIBUSI',
          ),
          const SizedBox(height: 12),
          _buildDashboardApplicationCard(
            id: '#5',
            title: 'Pupuk Urea Bersubsidi',
            weightChange: '— 400.00 kg',
            location: 'Lahan: Sawah Blok Timur Kebondalem',
            status: 'DIJADWALKAN_DISTRIBUSI',
          ),
        ],
      ],
    );
  }

  Widget _buildMiniStatusBadge(String status) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'DIAJUKAN':
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFCBD5E1);
        textColor = const Color(0xFF475569);
        icon = Icons.send_rounded;
        label = 'Diajukan';
        break;
      case 'MENUNGGU_VERIFIKASI_BERKAS':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        textColor = const Color(0xFFD97706);
        icon = Icons.access_time_rounded;
        label = 'Menunggu Verifikasi';
        break;
      case 'PERLU_PERBAIKAN_BERKAS':
        bg = const Color(0xFFFFEDD5);
        border = const Color(0xFFFDBA74);
        textColor = const Color(0xFFC2410C);
        icon = Icons.warning_amber_rounded;
        label = 'Perlu Perbaikan';
        break;
      case 'DITOLAK_BERKAS':
      case 'DITOLAK_LAPANGAN':
        bg = const Color(0xFFFFE4E6);
        border = const Color(0xFFFDA4AF);
        textColor = const Color(0xFFBE123C);
        icon = Icons.cancel_outlined;
        label = 'Ditolak';
        break;
      case 'BERKAS_TERVERIFIKASI':
        bg = const Color(0xFFCCFBF1);
        border = const Color(0xFF5EEAD4);
        textColor = const Color(0xFF0F766E);
        icon = Icons.verified_user_outlined;
        label = 'Berkas Terverifikasi';
        break;
      case 'DITUGASKAN_KE_PPL':
        bg = const Color(0xFFE0F2FE);
        border = const Color(0xFF7DD3FC);
        textColor = const Color(0xFF0369A1);
        icon = Icons.person_outline_rounded;
        label = 'Ditugaskan ke PPL';
        break;
      case 'SURVEI_LAPANGAN':
        bg = const Color(0xFFE0E7FF);
        border = const Color(0xFFA5B4FC);
        textColor = const Color(0xFF4338CA);
        icon = Icons.location_on_outlined;
        label = 'Sedang Survei Fisik';
        break;
      case 'MENUNGGU_PERSETUJUAN_AKHIR':
        bg = const Color(0xFFF3E8FF);
        border = const Color(0xFFD8B4FE);
        textColor = const Color(0xFF7E22CE);
        icon = Icons.access_time_rounded;
        label = 'Persetujuan Akhir';
        break;
      case 'DISETUJUI':
      case 'DIJADWALKAN_DISTRIBUSI':
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFF86EFAC);
        textColor = const Color(0xFF166534);
        icon = Icons.check_circle_outline_rounded;
        label = 'Siap Diambil (QR Terbit)';
        break;
      case 'TERSALURKAN':
        bg = const Color(0xFF009B69);
        border = const Color(0xFF009B69);
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        label = 'Telah Disalurkan';
        break;
      default:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFF86EFAC);
        textColor = const Color(0xFF166534);
        icon = Icons.check_circle_outline_rounded;
        label = 'Siap Diambil (QR Terbit)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardApplicationCard({
    required String id,
    required String title,
    required String weightChange,
    required String location,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: #id title — weight on left, badge on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$id ',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$title $weightChange',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildMiniStatusBadge(status),
            ],
          ),
          const SizedBox(height: 14),

          // Stepper persis web ProgressStepper
          _buildDashboardMiniStepper(status: status),
        ],
      ),
    );
  }

  Widget _buildDashboardMiniStepper({required String status}) {
    int currentStage = 1;
    bool isWarning = false;
    bool isRejected = false;
    int rejectStage = 0;

    switch (status) {
      case 'DIAJUKAN':
        currentStage = 1;
        break;
      case 'MENUNGGU_VERIFIKASI_BERKAS':
        currentStage = 2;
        break;
      case 'PERLU_PERBAIKAN_BERKAS':
        currentStage = 2;
        isWarning = true;
        break;
      case 'DITOLAK_BERKAS':
        currentStage = 2;
        isRejected = true;
        rejectStage = 2;
        break;
      case 'BERKAS_TERVERIFIKASI':
        currentStage = 3;
        break;
      case 'DITUGASKAN_KE_PPL':
        currentStage = 4;
        break;
      case 'SURVEI_LAPANGAN':
        currentStage = 4;
        break;
      case 'MENUNGGU_PERSETUJUAN_AKHIR':
        currentStage = 5;
        break;
      case 'DITOLAK_LAPANGAN':
        currentStage = 5;
        isRejected = true;
        rejectStage = 5;
        break;
      case 'DISETUJUI':
      case 'DIJADWALKAN_DISTRIBUSI':
        currentStage = 6;
        break;
      case 'TERSALURKAN':
        currentStage = 7; // Semua 6 tahapan selesai
        break;
      default:
        currentStage = 1;
    }

    final stages = [
      {'id': 1, 'name': 'Pengajuan', 'sub': '', 'icon': Icons.access_time_rounded},
      {'id': 2, 'name': 'Verifikasi', 'sub': 'Berkas', 'icon': Icons.shield_outlined},
      {'id': 3, 'name': 'Penugasan', 'sub': 'PPL', 'icon': Icons.person_outline_rounded},
      {'id': 4, 'name': 'Survei', 'sub': 'Lapangan', 'icon': Icons.location_on_outlined},
      {'id': 5, 'name': 'Persetujuan', 'sub': 'Admin', 'icon': Icons.workspace_premium_rounded},
      {'id': 6, 'name': 'Penggunaan', 'sub': 'Pupuk', 'icon': Icons.inventory_2_outlined},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final int stageId = stage['id'] as int;
        final bool isDone = currentStage > stageId;
        final bool isActive = currentStage == stageId;
        final bool isThisRejected = isRejected && rejectStage == stageId;
        final bool isThisWarning = isWarning && stageId == 2;
        final bool isFirst = index == 0;
        final bool isLast = index == stages.length - 1;

        final Color leftLineColor = isFirst
            ? Colors.transparent
            : (currentStage >= stageId ? const Color(0xFF009B69) : const Color(0xFFE2E8F0));

        final Color rightLineColor = isLast
            ? Colors.transparent
            : (currentStage > stageId ? const Color(0xFF009B69) : const Color(0xFFE2E8F0));

        Color circleBg;
        Color circleBorder;
        Widget iconWidget;

        if (isDone) {
          circleBg = const Color(0xFF009B69);
          circleBorder = const Color(0xFF009B69);
          iconWidget = const Icon(Icons.check, size: 11, color: Colors.white);
        } else if (isThisRejected) {
          circleBg = const Color(0xFFE11D48);
          circleBorder = const Color(0xFFFECDD3);
          iconWidget = const Icon(Icons.close, size: 11, color: Colors.white);
        } else if (isThisWarning) {
          circleBg = const Color(0xFFF59E0B);
          circleBorder = const Color(0xFFFDE68A);
          iconWidget = const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.white);
        } else if (isActive) {
          circleBg = const Color(0xFF2563EB);
          circleBorder = const Color(0xFF93C5FD);
          iconWidget = Icon(
            stageId == 6 ? Icons.qr_code_scanner_rounded : (stage['icon'] as IconData),
            size: 11,
            color: Colors.white,
          );
        } else {
          circleBg = Colors.white;
          circleBorder = const Color(0xFFCBD5E1);
          iconWidget = Icon(
            stage['icon'] as IconData,
            size: 10,
            color: const Color(0xFF94A3B8),
          );
        }

        final Color textColor = isThisRejected
            ? const Color(0xFFE11D48)
            : (isThisWarning
                ? const Color(0xFFD97706)
                : (isActive
                    ? const Color(0xFF2563EB)
                    : (isDone ? const Color(0xFF334155) : const Color(0xFF94A3B8))));

        final String name = stage['name'] as String;
        final String sub = stage['sub'] as String;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2.2,
                      color: leftLineColor,
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: circleBorder,
                        width: (isActive || isThisRejected || isThisWarning) ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(child: iconWidget),
                  ),
                  Expanded(
                    child: Container(
                      height: 2.2,
                      color: rightLineColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  sub.isEmpty ? name : '$name\n$sub',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: (isActive || isDone) ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // =========================================================================
  // 5. RINGKASAN KUOTA (MUSIM TANAM 2026) PERSIS SEPERTI DI GAMBAR
  // =========================================================================
  Widget _buildRingkasanKuotaCard() {
    final double ureaPercent = _kuotaDisetujuiUrea > 0 ? (_totalUreaUsed / _kuotaDisetujuiUrea) : 0.0;
    final double npkPercent = _kuotaDisetujuiNpk > 0 ? (_totalNpkUsed / _kuotaDisetujuiNpk) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row persis Screenshot 3
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.access_time_rounded, size: 22, color: primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Kuota Pupuk Saya (Tahun Anggaran 2026)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textDark),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pantau kuota alokasi resmi dari RDKK Dinas Pertanian Kabupaten Mojokerto dan rincian penggunaan di lahan',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Card UREA BERSUBSIDI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00875A),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Center(
                            child: Text(
                              'Ur',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'UREA BERSUBSIDI',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: textDark),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Pupuk Tunggal Nitrogen',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                      ),
                      child: const Text(
                        'Alokasi Musim Tanam',
                        style: TextStyle(color: Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kuota Disetujui:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text(
                            '${_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea.toInt() : 0} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sudah Digunakan:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text(
                            '${_totalUreaUsed.toInt()} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sisa Kuota:', style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 11.5)),
                          Text(
                            '${_sisaKuotaUrea.toInt()} kg',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kemajuan Penggunaan', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text('${(ureaPercent * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textDark)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ureaPercent.clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: primaryGreen,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Card NPK PHONSKA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Center(
                            child: Text(
                              'NPK',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'NPK PHONSKA',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: textDark),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Pupuk Majemuk N-P-K',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF93C5FD), width: 0.8),
                      ),
                      child: const Text(
                        'Alokasi Musim Tanam',
                        style: TextStyle(color: Color(0xFF1E40AF), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kuota Disetujui:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text(
                            '${_kuotaDisetujuiNpk > 0 ? _kuotaDisetujuiNpk.toInt() : 0} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sudah Digunakan:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text(
                            '${_totalNpkUsed.toInt()} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sisa Kuota:', style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 11.5)),
                          Text(
                            '${_sisaKuotaNpk.toInt()} kg',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kemajuan Penggunaan', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text('${(npkPercent * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textDark)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: npkPercent.clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF2563EB),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Info Banner Edukasi SK Bupati & e-RDKK
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alokasi kuota pupuk diperbarui secara berkala sesuai SK Bupati dan penetapan definitif e-RDKK per siklus musim tanam berjalan.',
                    style: TextStyle(color: Color(0xFF166534), fontSize: 10.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. STATUS PENGAJUAN TERKINI + STEPPER BERES (TIDAK OVERFLOW/RUSAK)
  // =========================================================================
  Widget _buildStatusPengajuanTerkiniSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.access_time_rounded, size: 22, color: primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Status & Progres Pengajuan (2)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: textDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tahapan: 1. Pengajuan -> 2. Verifikasi Berkas -> 3. Penugasan PPL -> 4. Survei Lapangan -> 5. Persetujuan Admin -> 6. Penggunaan Pupuk',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 15, color: Colors.white),
              label: const Text('Ajukan Baru', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _activeNav = 3),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Card #1: Pupuk Urea Bersubsidi — 250.00 kg (Menunggu Verifikasi Berkas)
        _buildExactWebStepperCard(
          id: '#1',
          name: 'Pupuk Urea Bersubsidi',
          weight: '250.00 kg',
          date: '7 Oktober 2026',
          location: 'Lahan: Sawah Blok Timur Kebondalem',
          status: 'MENUNGGU_VERIFIKASI_BERKAS',
        ),
        const SizedBox(height: 14),

        // Card #3: Pupuk NPK Phonska Bersubsidi — 150.00 kg (Menunggu Persetujuan Akhir)
        _buildExactWebStepperCard(
          id: '#3',
          name: 'Pupuk NPK Phonska Bersubsidi',
          weight: '150.00 kg',
          date: '7 Oktober 2026',
          location: 'Lahan: Sawah Blok Timur Kebondalem',
          status: 'MENUNGGU_PERSETUJUAN_AKHIR',
          adminNote: 'Berkas lengkap dan sesuai.',
          hasPplSurvey: true,
        ),
      ],
    );
  }

  Widget _buildExactWebStepperCard({
    required String id,
    required String name,
    required String weight,
    String? date,
    required String location,
    required String status,
    String? adminNote,
    bool hasPplSurvey = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Weight on Left, Status Badge on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: textDark),
                        children: [
                          TextSpan(
                            text: '$id ',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          TextSpan(
                            text: '$name — ',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          TextSpan(
                            text: weight,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${date != null ? "Diajukan: $date • " : ""}$location',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildExactStatusBadge(status),
            ],
          ),
          const SizedBox(height: 18),

          // THE EXACT PROGRESS STEPPER WITH LINES AND CIRCLES
          _buildWebProgressStepper(status),

          // Alert Catatan Verifikasi Admin persis Screenshot 1
          if (adminNote != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 17, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        children: [
                          const TextSpan(text: 'Catatan Verifikasi Admin: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: adminNote),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Box Hasil Survei Petugas PPL persis Screenshot 1
          if (hasPplSurvey) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hasil Survei Petugas PPL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0369A1))),
                  const SizedBox(height: 3),
                  const Text('Kondisi Lahan: BAIK | Tanaman: SESUAI | Rekomendasi: SETUJU', style: TextStyle(fontSize: 10.5, color: Color(0xFF0284C7))),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0284C7), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Membuka foto survei lapangan PPL...')),
                      );
                    },
                    child: const Text('Lihat Foto Survei', style: TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExactStatusBadge(String status) {
    if (status == 'TERSALURKAN') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0xFF009B69),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline_rounded, size: 13, color: Colors.white),
            SizedBox(width: 4.5),
            Text(
              'Telah Disalurkan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'MENUNGGU_VERIFIKASI_BERKAS') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFD97706)),
            SizedBox(width: 4),
            Text(
              'Menunggu Verifikasi Berkas',
              style: TextStyle(
                color: Color(0xFFD97706),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'MENUNGGU_PERSETUJUAN_AKHIR') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8B4FE), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF7E22CE)),
            SizedBox(width: 4),
            Text(
              'Menunggu Persetujuan Akhir',
              style: TextStyle(
                color: Color(0xFF7E22CE),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check, size: 12, color: Color(0xFF166534)),
            SizedBox(width: 4),
            Text(
              'Siap Diambil (QR Terbit)',
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWebProgressStepper(String status) {
    int currentStage = 1;
    switch (status) {
      case 'DIAJUKAN':
        currentStage = 1;
        break;
      case 'MENUNGGU_VERIFIKASI_BERKAS':
      case 'PERLU_PERBAIKAN_BERKAS':
        currentStage = 2;
        break;
      case 'BERKAS_TERVERIFIKASI':
      case 'DITUGASKAN_KE_PPL':
        currentStage = 3;
        break;
      case 'SURVEI_LAPANGAN':
        currentStage = 4;
        break;
      case 'MENUNGGU_PERSETUJUAN_AKHIR':
        currentStage = 5;
        break;
      case 'DISETUJUI':
      case 'DIJADWALKAN_DISTRIBUSI':
        currentStage = 6;
        break;
      case 'TERSALURKAN':
        currentStage = 7; // All 6 stages completed!
        break;
      default:
        currentStage = 5;
    }

    final stages = [
      {'id': 1, 'line1': 'Pengajuan', 'line2': '', 'icon': Icons.access_time_rounded},
      {'id': 2, 'line1': 'Verifikasi', 'line2': 'Berkas', 'icon': Icons.shield_outlined},
      {'id': 3, 'line1': 'Penugasan', 'line2': 'PPL', 'icon': Icons.person_outline_rounded},
      {'id': 4, 'line1': 'Survei', 'line2': 'Lapangan', 'icon': Icons.location_on_outlined},
      {'id': 5, 'line1': 'Persetujuan', 'line2': 'Admin', 'icon': Icons.workspace_premium_rounded},
      {'id': 6, 'line1': 'Penggunaan', 'line2': 'Pupuk', 'icon': Icons.inventory_2_outlined},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Lebar minimum 560px agar garis horisontal panjang dan proporsional persis tampilan web
        final double minWidth = 560.0;
        final double contentWidth = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: contentWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...stages.map((stage) {
                  final int id = stage['id'] as int;
                  final bool isDone = currentStage > id;
                  final bool isActive = currentStage == id;
                  final String line1 = stage['line1'] as String;
                  final String line2 = stage['line2'] as String;
                  final IconData defaultIcon = stage['icon'] as IconData;

                  final Color lineBg = isDone || isActive ? const Color(0xFF009B69) : const Color(0xFFE2E8F0);
                  Color circleBg;
                  Color circleBorder;
                  Widget iconWidget;

                  if (isDone) {
                    circleBg = const Color(0xFF009B69);
                    circleBorder = const Color(0xFF009B69);
                    iconWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 15);
                  } else if (isActive) {
                    circleBg = const Color(0xFF2563EB); // Vibrant Blue
                    circleBorder = const Color(0xFF93C5FD); // Ring
                    iconWidget = Icon(defaultIcon, color: Colors.white, size: 14);
                  } else {
                    circleBg = Colors.white;
                    circleBorder = const Color(0xFFCBD5E1);
                    iconWidget = Icon(defaultIcon, color: const Color(0xFF94A3B8), size: 13.5);
                  }

                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top: Track line leading to Circle Checkpoint
                        SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              // Line segment to the left of the node
                              Expanded(
                                child: Container(
                                  height: 2.5,
                                  color: lineBg,
                                ),
                              ),
                              // Node Checkpoint Circle
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: circleBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: circleBorder,
                                    width: isActive ? 2.5 : 1.5,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(child: iconWidget),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Bottom: Stage label placed under the line segment to the left
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Text(
                            line2.isEmpty ? line1 : '$line1\n$line2',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.25,
                              fontWeight: isDone || isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? const Color(0xFF2563EB)
                                  : (isDone ? textDark : const Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Trailing end tail after step 6 (persis seperti di web!)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 2.5,
                          color: currentStage >= 6 ? const Color(0xFF009B69) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(width: 20, height: 26),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION BAR DENGAN TOMBOL SCAN QR DI TENGAH PERSIS GAMBAR
  // =========================================================================
  Widget _buildCustomBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Beranda
          _bottomNavItem(
            index: 0,
            label: 'Beranda',
            icon: Icons.home_rounded,
            isSelected: _bottomNavIndex == 0,
            onTap: () {
              setState(() {
                _bottomNavIndex = 0;
                _activeNav = 0;
              });
            },
          ),
          // 2. Lahan
          _bottomNavItem(
            index: 1,
            label: 'Lahan',
            icon: Icons.location_on_outlined,
            isSelected: _bottomNavIndex == 1,
            onTap: () {
              setState(() {
                _bottomNavIndex = 1;
                _activeNav = 2; // Data Lahan
              });
            },
          ),
          // 3. Scan QR (TOMBOL TENGAH BESAR ELEVATED HIJAU)
          InkWell(
            onTap: () {
              setState(() {
                _bottomNavIndex = 2;
                _activeNav = 6; // Pembukaan Pupuk / Scan QR
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Scan QR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          // 4. Status
          _bottomNavItem(
            index: 3,
            label: 'Status',
            icon: Icons.assignment_outlined,
            isSelected: _bottomNavIndex == 3,
            onTap: () {
              setState(() {
                _bottomNavIndex = 3;
                _activeNav = 4; // Status Pengajuan
              });
            },
          ),
          // 5. Akun
          _bottomNavItem(
            index: 4,
            label: 'Akun',
            icon: Icons.person_outline_rounded,
            isSelected: _bottomNavIndex == 4,
            onTap: () {
              setState(() {
                _bottomNavIndex = 4;
                _activeNav = 1; // Profil Saya
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGreen, size: 19),
              )
            else
              Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryGreen : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // KONTEN TIAP TAB LAINNYA (Lahan, Profil, Pengajuan, Kuota, Pembukaan, Riwayat)
  // =========================================================================
  Widget _buildProfileTabContent() {
    final farmerName = _farmer?.nama ?? widget.user.nama;
    final farmerNik = _farmer?.nik ?? '3516011208830001';
    final farmerKontak = _farmer?.kontak ?? '081234567893';
    final farmerPoktan = _farmer?.kelompokTani ?? 'Poktan Sumber Makmur';
    final farmerAlamat = _farmer?.alamat ?? 'Dusun Kebondalem RT 02 / RW 01, Desa Kebondalem, Kec. Mojosari, Kab. Mojokerto, Jawa Timur 61382';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderGray),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_rounded, size: 20, color: primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'Data Diri & Profil Petani',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check, size: 11, color: Color(0xFF166534)),
                    SizedBox(width: 4),
                    Text(
                      'Data Terverifikasi',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. KARTU E-KTP ASLI (GRAFIK REALISTIK DENGAN PASFOTO DAN DATA RESMI DUKCAPIL)
        _buildKtpCardGraphic(
          farmerName: farmerName,
          farmerNik: farmerNik,
          farmerAlamat: farmerAlamat,
        ),
        const SizedBox(height: 14),

        // 3. 7 KARTU RINCIAN DATA DIRI PERSIS SCREENSHOT 4
        _buildProfileDetailCard(
          title: 'Nama Lengkap',
          value: farmerName,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 10),
        _buildProfileDetailCard(
          title: 'Nomor Induk Kependudukan (NIK)',
          value: farmerNik,
          icon: Icons.badge_outlined,
          isMonospace: true,
        ),
        const SizedBox(height: 10),
        _buildProfileDetailCard(
          title: 'Nomor Handphone / WhatsApp',
          value: farmerKontak,
          icon: Icons.phone_outlined,
          isMonospace: true,
        ),
        const SizedBox(height: 10),
        _buildProfileDetailCard(
          title: 'Email Terdaftar',
          value: 'petani.budi@epupuk-mojokerto.id',
          icon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 10),
        _buildProfileDetailCard(
          title: 'Kelompok Tani (Poktan)',
          value: '$farmerPoktan • Wilayah Mojosari',
          icon: Icons.groups_outlined,
        ),
        const SizedBox(height: 10),
        _buildProfileDetailCard(
          title: 'Status Verifikasi Sistem',
          value: 'Data KTP Terverifikasi Valid oleh Dispendukcapil & Simluhtan',
          icon: Icons.verified_outlined,
          isVerifiedStatus: true,
        ),
        const SizedBox(height: 10),
        _buildProfileDetailCard(
          title: 'Alamat Domisili KTP',
          value: farmerAlamat,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildKtpCardGraphic({
    required String farmerName,
    required String farmerNik,
    required String farmerAlamat,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.credit_card_rounded, size: 16, color: primaryGreen),
                    SizedBox(width: 6),
                    Text(
                      'FOTO KTP TERDAFTAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'e-KTP Asli',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // THE REALISTIC INDONESIAN E-KTP CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E3A8A), // Deep Navy Blue
                  Color(0xFF2563EB), // Vibrant Royal Blue
                  Color(0xFF0284C7), // Bright Ocean Cyan
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x281E3A8A),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header e-KTP
                Column(
                  children: const [
                    Text(
                      'REPUBLIK INDONESIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'PROVINSI JAWA TIMUR',
                      style: TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'KABUPATEN MOJOKERTO',
                      style: TextStyle(
                        color: Color(0xFFBAE6FD),
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(height: 8),

                // Data Rows + Photo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ktpTextRow('NIK', farmerNik, isBold: true, isMono: true, fontSize: 11),
                          const SizedBox(height: 3),
                          _ktpTextRow('Nama', farmerName.toUpperCase(), isBold: true),
                          const SizedBox(height: 2),
                          _ktpTextRow('Tempat/Tgl Lahir', 'MOJOKERTO, 12-08-1983'),
                          const SizedBox(height: 2),
                          _ktpTextRow('Jenis Kelamin', 'LAKI-LAKI'),
                          const SizedBox(height: 2),
                          _ktpTextRow('Alamat', 'DSN. KEBONDALEM RT 02 RW 01'),
                          const SizedBox(height: 1),
                          _ktpSubTextRow('Kel/Desa', 'KEBONDALEM'),
                          const SizedBox(height: 1),
                          _ktpSubTextRow('Kecamatan', 'MOJOSARI'),
                          const SizedBox(height: 2),
                          _ktpTextRow('Agama', 'ISLAM'),
                          const SizedBox(height: 2),
                          _ktpTextRow('Status Kawin', 'KAWIN'),
                          const SizedBox(height: 2),
                          _ktpTextRow('Pekerjaan', 'PETANI / PEKEBUN'),
                          const SizedBox(height: 2),
                          _ktpTextRow('Kewarganegaraan', 'WNI'),
                          const SizedBox(height: 3),
                          _ktpTextRow('Berlaku Hingga', 'SEUMUR HIDUP', isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right Column: Pasfoto e-KTP Box
                    Column(
                      children: [
                        Container(
                          width: 66,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626), // Latar Merah Pasfoto Resmi
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: const [
                              Positioned(
                                bottom: 0,
                                child: Icon(Icons.person, size: 55, color: Colors.white),
                              ),
                              Positioned(
                                top: 4,
                                child: Icon(Icons.account_circle, size: 30, color: Color(0xFFFEE2E2)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'MOJOKERTO',
                                style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '14-10-2021',
                                style: TextStyle(color: Color(0xFFE0F2FE), fontSize: 6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-footer: Status sinkronisasi & Ubah Foto button
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, size: 14, color: primaryGreen),
                    SizedBox(width: 4),
                    Text(
                      'Tersinkronisasi Dukcapil & Simluhtan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur Ubah Foto KTP: Mengajukan pembaruan dokumen ke Admin Dinas.')),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: const [
                      Icon(Icons.camera_alt_outlined, size: 13, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Ubah Foto',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ktpTextRow(String label, String value, {bool isBold = false, bool isMono = false, double fontSize = 9}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(color: const Color(0xFFE0F2FE), fontSize: fontSize, fontWeight: FontWeight.w500),
          ),
        ),
        const Text(': ', style: TextStyle(color: Colors.white, fontSize: 9)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontFamily: isMono ? 'monospace' : null,
              letterSpacing: isMono ? 0.3 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _ktpSubTextRow(String label, String value) {
    return Row(
      children: [
        const SizedBox(width: 14),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFBAE6FD), fontSize: 8),
          ),
        ),
        const Text(': ', style: TextStyle(color: Colors.white, fontSize: 8)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailCard({
    required String title,
    required String value,
    required IconData icon,
    bool isMonospace = false,
    bool isVerifiedStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGray),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isVerifiedStatus ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 17,
              color: isVerifiedStatus ? primaryGreen : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: isVerifiedStatus ? const Color(0xFF166534) : textDark,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row + Tombol Tambah Lahan
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Lahan Pertanian (${_lands.length})',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: textDark),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Data petak sawah terdaftar & status verifikasi PPL',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_rounded, size: 15, color: Colors.white),
              label: const Text('Tambah Lahan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _showAddLandDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Info Banner Edukasi Pengukuran Spasial
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Luas yang Anda daftarkan adalah luas laporan awal. Batas fisik pematang sawah akan diverifikasi oleh petugas PPL menggunakan peta citra satelit.',
                  style: TextStyle(color: Color(0xFF166534), fontSize: 10.5, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_lands.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGray),
            ),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.landscape_rounded, size: 40, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 8),
                  Text('Belum ada lahan pertanian terdaftar.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Ketuk tombol "Tambah Lahan" di atas untuk mendaftarkan petak sawah Anda.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
            ),
          )
        else
          ..._lands.map((land) => _buildLandCard(land)),

        const SizedBox(height: 12),

        // Notice Box Pendaftaran Lahan Baru persis Screenshot 5
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pendaftaran Lahan Baru: Pastikan Anda melampirkan nomor SPPT PBB atau surat keterangan garap dari kepala desa untuk mempercepat verifikasi lapangan PPL.',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 10.5, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandPill(String text, Color bg, Color textColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(text, style: TextStyle(color: textColor, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLandCard(LandModel land) {
    final bool isVerified = land.isTerverifikasi;
    final bool hasPolygon = land.parsedPolygonPoints.isNotEmpty;
    final double? selisih = land.selisihLuasM2;

    Color badgeColor = const Color(0xFFFEF3C7);
    Color badgeTextColor = const Color(0xFFB45309);
    String badgeText = 'Menunggu Survei PPL';
    IconData badgeIcon = Icons.hourglass_top_rounded;

    if (isVerified) {
      badgeColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF15803D);
      badgeText = 'Terverifikasi PPL';
      badgeIcon = Icons.check_circle_rounded;
    } else if (land.statusVerifikasi == 'DITOLAK') {
      badgeColor = const Color(0xFFFFE4E6);
      badgeTextColor = const Color(0xFFBE123C);
      badgeText = 'Verifikasi Ditolak';
      badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isVerified ? const Color(0xFF86EFAC) : borderGray, width: isVerified ? 1.2 : 1),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mountain landscape illustration banner with 4 badges persis Screenshot 5
          Container(
            height: 75,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Stack(
              children: [
                // Sun
                Positioned(
                  right: 25,
                  top: 10,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE047),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Mountains
                Positioned(
                  right: -10,
                  bottom: -15,
                  child: Icon(
                    Icons.landscape_rounded,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: -20,
                  child: Icon(
                    Icons.terrain_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                // Floating Pills Overlaid
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildLandPill(land.namaKomoditas ?? 'Padi Ciherang', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                      _buildLandPill(land.statusKepemilikan.toUpperCase(), const Color(0xFFFEF3C7), const Color(0xFFB45309)),
                      _buildLandPill(isVerified ? 'Terverifikasi PPL' : 'Menunggu PPL', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
                      _buildLandPill('Geofence Aktif', const Color(0xFFCCFBF1), const Color(0xFF0F766E), icon: Icons.gps_fixed_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // 1. Header Card: Nama & Badge Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isVerified ? Icons.verified_rounded : Icons.terrain_rounded,
                        color: isVerified ? primaryGreen : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            land.lokasiDeskripsi,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${land.namaKomoditas ?? 'Padi'} • Status ${land.statusKepemilikan}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeTextColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Alamat & Pin Geografis
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  land.alamatLahan,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (land.latitude != null && land.longitude != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 19),
              child: Text(
                'Koordinat: ${land.latitude!.toStringAsFixed(6)}, ${land.longitude!.toStringAsFixed(6)}',
                style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF94A3B8), fontSize: 9.5),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 3. Grid Komparasi Luas (Luas Lapor Petani vs Luas Ukur PPL vs Selisih)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                // Kolom 1: Luas Lapor Petani
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Luas Lapor (Awal)', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        '${land.luasM2.toInt()} m²',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textDark),
                      ),
                      Text(
                        '${(land.luasM2 / 10000).toStringAsFixed(2)} Ha',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 10),

                // Kolom 2: Luas Hasil Ukur PPL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hasil Ukur PPL', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      if (land.luasVerifikasiM2 != null) ...[
                        Text(
                          '${land.luasVerifikasiM2!.toStringAsFixed(1)} m²',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF15803D)),
                        ),
                        Text(
                          '${(land.luasVerifikasiM2! / 10000).toStringAsFixed(3)} Ha',
                          style: const TextStyle(color: Color(0xFF15803D), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ] else ...[
                        const Text(
                          'Belum diukur',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 10),

                // Kolom 3: Selisih Luas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selisih Luas', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      if (selisih != null) ...[
                        Text(
                          '${selisih >= 0 ? '+' : ''}${selisih.toStringAsFixed(1)} m²',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: selisih.abs() < 50 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                          ),
                        ),
                        Text(
                          selisih == 0 ? 'Sesuai' : (selisih > 0 ? 'Lebih Luas' : 'Kurang'),
                          style: TextStyle(color: selisih.abs() < 50 ? const Color(0xFF16A34A) : const Color(0xFFEA580C), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ] else ...[
                        const Text('—', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Catatan Verifikasi PPL jika ada
          if (land.catatanVerifikasi != null && land.catatanVerifikasi!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Color(0xFF475569)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan PPL: ${land.catatanVerifikasi}',
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 10.5, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 5. Dokumen Sertifikat Lampiran
          if (land.dokumenSertifikatUrl != null && land.dokumenSertifikatUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 13),
                const SizedBox(width: 4),
                Text(
                  'Dokumen Sertifikat: ${land.dokumenSertifikatUrl!.split('/').last}',
                  style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          // 6. Tombol Aksi: Buka Peta Poligon Lahan
          if (hasPolygon) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map_rounded, color: Colors.white, size: 16),
                label: Text(
                  'Lihat Peta Bidang Sawah (${land.parsedPolygonPoints.length} Titik Sudut)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A), // Dark slate
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _showPolygonViewerDialog(land),
              ),
            ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationTabContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Form Pengajuan Subsidi Pupuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Text('Ajukan alokasi pupuk bersubsidi sesuai kebutuhan lahan Anda', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          const Divider(height: 20),

          // Lahan
          const Text('Pilih Lahan Pertanian *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (_lands.isEmpty)
            const Text('Belum ada data lahan terdaftar.', style: TextStyle(color: Colors.red, fontSize: 11))
          else
            DropdownButtonFormField<int>(
              initialValue: _lands.any((l) => l.id == _formLandId) ? _formLandId : (_lands.isNotEmpty ? _lands.first.id : null),
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: _lands.map((l) => DropdownMenuItem(value: l.id, child: Text('${l.lokasiDeskripsi} (${l.luasM2.toInt()} m²)', style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) => setState(() => _formLandId = v),
            ),
          const SizedBox(height: 14),

          // Pupuk
          const Text('Pilih Jenis Pupuk *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _fertilizers.any((f) => f.id == _formFertilizerId) ? _formFertilizerId : (_fertilizers.isNotEmpty ? _fertilizers.first.id : null),
            isExpanded: true,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: _fertilizers.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.namaPupuk} — Rp ${f.hargaSubsidi.toInt()}/kg', style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _formFertilizerId = v),
          ),
          const SizedBox(height: 14),

          // Jumlah
          const Text('Jumlah Diajukan (Kg) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _formJumlahCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Contoh: 150', suffixText: 'Kg', isDense: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _isSubmittingApp ? null : _handleSubmitApplication,
              child: _isSubmittingApp
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Pengajuan Subsidi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. DIALOG VIEWER PETA POLIGON LAHAN HASIL UKUR PPL
  // =========================================================================
  void _showPolygonViewerDialog(LandModel land) {
    final points = land.parsedPolygonPoints;
    if (points.isEmpty) return;

    bool isSat = true;
    final mapCtrl = MapController();
    final centerLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final centerLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top Drag Handle & Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.satellite_alt_rounded, color: Color(0xFF4ADE80), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Peta Bidang Sawah (Hasil Ukur PPL)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          '${land.lokasiDeskripsi} • ${points.length} Titik Sudut',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Ganti Layer Peta',
                          icon: Icon(isSat ? Icons.satellite_alt : Icons.map_outlined, color: Colors.white),
                          onPressed: () => setSheetState(() => isSat = !isSat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Interactive FlutterMap
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapCtrl,
                      options: MapOptions(
                        initialCenter: LatLng(centerLat, centerLng),
                        initialZoom: 18.0,
                        maxZoom: 19.5,
                        minZoom: 12.0,
                      ),
                      children: [
                        // Tile Satelit Esri / OSM
                        TileLayer(
                          urlTemplate: isSat
                              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.epupuk.mobile',
                        ),

                        // Polyline Batas Pematang
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [...points, points.first],
                              color: const Color(0xFF22C55E),
                              strokeWidth: 3.5,
                            ),
                          ],
                        ),

                        // Polygon Hijau Fill Transparan
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: points,
                              color: const Color(0x6616A34A),
                              borderColor: const Color(0xFF16A34A),
                              borderStrokeWidth: 2.0,
                              isFilled: true,
                            ),
                          ],
                        ),

                        // Pin Sudut Pematang Sawah
                        MarkerLayer(
                          markers: points.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final pt = entry.value;
                            return Marker(
                              point: pt,
                              width: 28,
                              height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryGreen, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Center(
                                  child: Text(
                                    '$idx',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryGreen),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Reset Center Button
                    Positioned(
                      right: 14,
                      top: 14,
                      child: FloatingActionButton.small(
                        backgroundColor: const Color(0xDD0F172A),
                        foregroundColor: Colors.white,
                        onPressed: () => mapCtrl.move(LatLng(centerLat, centerLng), 18.0),
                        child: const Icon(Icons.my_location_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Info Panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Luas Hasil Ukur PPL (Satelit)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  land.luasVerifikasiM2 != null ? land.luasVerifikasiM2!.toStringAsFixed(1) : '—',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                                ),
                                const SizedBox(width: 4),
                                const Text('m²', style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                                const SizedBox(width: 10),
                                Text(
                                  land.luasVerifikasiM2 != null ? '(${(land.luasVerifikasiM2! / 10000).toStringAsFixed(3)} Ha)' : '',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.verified_rounded, color: Color(0xFF166534), size: 14),
                              SizedBox(width: 4),
                              Text('Terverifikasi', style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Luas Dilaporkan: ${land.luasM2.toInt()} m²', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                        if (land.selisihLuasM2 != null)
                          Text(
                            'Selisih: ${land.selisihLuasM2! >= 0 ? '+' : ''}${land.selisihLuasM2!.toStringAsFixed(1)} m²',
                            style: TextStyle(
                              color: land.selisihLuasM2!.abs() < 50 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (land.catatanVerifikasi != null && land.catatanVerifikasi!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Catatan PPL: ${land.catatanVerifikasi}',
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 10.5, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. DIALOG PEMILIH LOKASI SAWAH (MAP PICKER PETANI)
  // =========================================================================
  Future<LatLng?> _showLocationPickerMap(double initialLat, double initialLng) async {
    LatLng picked = LatLng(initialLat, initialLng);
    final mapCtrl = MapController();
    bool isSat = true;

    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPickerState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.pin_drop_rounded, color: primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tandai Lokasi Sawah',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Ganti Layer Peta',
                          icon: Icon(isSat ? Icons.satellite_alt : Icons.map_outlined, color: Colors.white, size: 20),
                          onPressed: () => setPickerState(() => isSat = !isSat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(ctx, null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Interactive Map
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapCtrl,
                      options: MapOptions(
                        initialCenter: picked,
                        initialZoom: 16.5,
                        onTap: (tapPosition, point) {
                          setPickerState(() {
                            picked = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: isSat
                              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.epupuk.mobile',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: picked,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.redAccent,
                                size: 44,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xDD0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          'Koordinat: ${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}\n(Ketuk pada peta untuk menggeser pin lokasi)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, height: 1.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Action
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        label: const Text('Gunakan Titik Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx, picked),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. BOTTOM SHEET TAMBAH LAHAN (RESPONSIF MOBILE DENGAN GPS, PETA, & SERTIFIKAT)
  // =========================================================================
  void _showAddLandDialog() {
    final deskripsiCtrl = TextEditingController();
    final luasCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final sertifikatCtrl = TextEditingController();
    double currentLat = -7.535000;
    double currentLng = 112.445000;
    String kepemilikan = 'MILIK';
    int selectedComId = _commodities.isNotEmpty ? _commodities.first.id : 1;
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 1. Top Drag Handle & Title Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add_location_alt_rounded, color: primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Tambah Lahan Pertanian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                                Text('Pendaftaran petak sawah untuk kuota subsidi pupuk', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Scrollable Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Lahan
                      const Text('Nama / Blok Lahan *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: deskripsiCtrl,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Sawah Blok B Kebondalem',
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.landscape_outlined, size: 18, color: Color(0xFF64748B)),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Luas Lahan & Kepemilikan (Stacked or clear row)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Luas Dilaporkan *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textDark)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: luasCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '2000',
                                    suffixText: 'm²',
                                    prefixIcon: const Icon(Icons.straighten_rounded, size: 18, color: Color(0xFF64748B)),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status Hak *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textDark)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: kepemilikan,
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'MILIK', child: Text('Milik Sendiri', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'GARAP', child: Text('Garap', style: TextStyle(fontSize: 11))),
                                    DropdownMenuItem(value: 'SEWA', child: Text('Sewa', style: TextStyle(fontSize: 11))),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setDlgState(() => kepemilikan = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Komoditas
                      const Text('Komoditas Pertanian *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _commodities.any((c) => c.id == selectedComId)
                            ? selectedComId
                            : (_commodities.isNotEmpty ? _commodities.first.id : null),
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.eco_outlined, size: 18, color: Color(0xFF16A34A)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: _commodities.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.namaKomoditas, style: const TextStyle(fontSize: 11.5)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) setDlgState(() => selectedComId = v);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Alamat Lengkap Lahan
                      const Text('Alamat Lengkap Lahan *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: alamatCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Dusun, Desa, Kecamatan di Kab. Mojokerto',
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                          ),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Titik Koordinat (Peta & GPS)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderGray),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.my_location_rounded, size: 14, color: primaryGreen),
                                    SizedBox(width: 6),
                                    Text('Titik Koordinat Lahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    '${currentLat.toStringAsFixed(5)}, ${currentLng.toStringAsFixed(5)}',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: isLocating
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.gps_fixed_rounded, size: 15),
                                    label: const Text('Gunakan GPS', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      setDlgState(() => isLocating = true);
                                      Future.delayed(const Duration(milliseconds: 600), () {
                                        setDlgState(() {
                                          currentLat = -7.536000 + (Random().nextDouble() * 0.01 - 0.005);
                                          currentLng = 112.446000 + (Random().nextDouble() * 0.01 - 0.005);
                                          isLocating = false;
                                        });
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.map_rounded, size: 15, color: Colors.white),
                                    label: const Text('Tandai di Peta', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      final selected = await _showLocationPickerMap(currentLat, currentLng);
                                      if (selected != null) {
                                        setDlgState(() {
                                          currentLat = selected.latitude;
                                          currentLng = selected.longitude;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bukti Sertifikat / SPPT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sertifikat / Bukti Kepemilikan Lahan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: sertifikatCtrl.text.isNotEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sertifikatCtrl.text.isNotEmpty ? 'Terlampir' : 'Opsional',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: sertifikatCtrl.text.isNotEmpty ? const Color(0xFF166534) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (sertifikatCtrl.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.description_rounded, color: Color(0xFF16A34A), size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sertifikatCtrl.text.split('/').last,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Berkas siap diverifikasi Admin & PPL',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF15803D)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                                splashRadius: 18,
                                onPressed: () {
                                  setDlgState(() {
                                    sertifikatCtrl.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        // Selector button
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (bCtx) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'Pilih Dokumen Bukti Kepemilikan Lahan',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Pilih berkas sertifikat atau bukti SPPT PBB untuk diverifikasi Admin:',
                                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                      const SizedBox(height: 12),
                                      ListTile(
                                        dense: true,
                                        leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFEFF6FF),
                                          child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 18),
                                        ),
                                        title: const Text('Sertifikat Hak Milik (SHM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        subtitle: const Text('shm_kebondalem_0142.pdf (2.4 MB)', style: TextStyle(fontSize: 10.5)),
                                        onTap: () {
                                          Navigator.pop(bCtx);
                                          setDlgState(() {
                                            sertifikatCtrl.text = '/files/sertifikat/shm_kebondalem_0142.pdf';
                                          });
                                        },
                                      ),
                                      ListTile(
                                        dense: true,
                                        leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFFEF3C7),
                                          child: Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 18),
                                        ),
                                        title: const Text('SPPT PBB Tahun Berjalan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        subtitle: const Text('sppt_pbb_mojosari_2026.jpg (1.8 MB)', style: TextStyle(fontSize: 10.5)),
                                        onTap: () {
                                          Navigator.pop(bCtx);
                                          setDlgState(() {
                                            sertifikatCtrl.text = '/files/sertifikat/sppt_pbb_mojosari_2026.jpg';
                                          });
                                        },
                                      ),
                                      ListTile(
                                        dense: true,
                                        leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFF1F5F9),
                                          child: Icon(Icons.description_outlined, color: Color(0xFF475569), size: 18),
                                        ),
                                        title: const Text('Surat Girik / Letter C Desa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        subtitle: const Text('letter_c_desa_kebondalem.pdf', style: TextStyle(fontSize: 10.5)),
                                        onTap: () {
                                          Navigator.pop(bCtx);
                                          setDlgState(() {
                                            sertifikatCtrl.text = '/files/sertifikat/letter_c_desa_kebondalem.pdf';
                                          });
                                        },
                                      ),
                                      ListTile(
                                        dense: true,
                                        leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFDCFCE7),
                                          child: Icon(Icons.camera_alt_rounded, color: Color(0xFF16A34A), size: 18),
                                        ),
                                        title: const Text('Ambil Foto Fisik dari Kamera / Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        subtitle: const Text('Foto langsung dokumen surat tanah', style: TextStyle(fontSize: 10.5)),
                                        onTap: () {
                                          Navigator.pop(bCtx);
                                          setDlgState(() {
                                            sertifikatCtrl.text = '/files/sertifikat/sertifikat_foto_kamera.jpg';
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.upload_file_rounded, size: 18, color: primaryGreen),
                                SizedBox(width: 8),
                                Text(
                                  'Pilih / Unggah Bukti Sertifikat / SPPT',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryGreen),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Manual text input
                      TextField(
                        controller: sertifikatCtrl,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Atau ketik Nomor Sertifikat / link berkas...',
                          hintStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          setDlgState(() {});
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '* Catatan: Sertifikat & SPPT digunakan Admin Disperta untuk verifikasi kuota subsidi. Batas fisik poligon sawah akan dipetakan langsung oleh PPL di lapangan.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            if (deskripsiCtrl.text.trim().isEmpty || luasCtrl.text.trim().isEmpty || alamatCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama lahan, luas, dan alamat wajib diisi!')),
                              );
                              return;
                            }
                            final luas = double.tryParse(luasCtrl.text.trim()) ?? 1000;
                            Navigator.pop(ctx);

                            final res = await SubsidyService.createLand(
                              lokasiDeskripsi: deskripsiCtrl.text.trim(),
                              luasM2: luas,
                              alamatLahan: alamatCtrl.text.trim(),
                              statusKepemilikan: kepemilikan,
                              commodityId: selectedComId,
                              latitude: currentLat,
                              longitude: currentLng,
                              dokumenSertifikatUrl: sertifikatCtrl.text.trim().isNotEmpty ? sertifikatCtrl.text.trim() : null,
                            );

                            if (res['success'] == true) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lahan berhasil didaftarkan dan siap disurvei PPL!')),
                              );
                              _loadAllData();
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res['message'] ?? 'Gagal mendaftarkan lahan.')),
                              );
                            }
                          },
                          child: const Text(
                            'Simpan Lahan Pertanian',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
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
    );
  }

  Future<void> _handleSubmitApplication() async {
    if (_formLandId == null || _formFertilizerId == null || _formJumlahCtrl.text.isEmpty) return;
    final double? jumlah = double.tryParse(_formJumlahCtrl.text.trim());
    if (jumlah == null || jumlah <= 0) return;

    final selectedLand = _lands.firstWhere((l) => l.id == _formLandId, orElse: () => _lands.first);

    setState(() => _isSubmittingApp = true);
    final res = await SubsidyService.submitApplication(
      landId: _formLandId!,
      fertilizerId: _formFertilizerId!,
      jumlahDiajukan: jumlah,
      alamatLahan: selectedLand.alamatLahan,
      latitude: selectedLand.latitude ?? -7.531234,
      longitude: selectedLand.longitude ?? 112.551234,
    );
    setState(() => _isSubmittingApp = false);

    if (res['success'] == true) {
      _formJumlahCtrl.clear();
      await _loadAllData();
      setState(() => _activeNav = 4);
    }
  }

  // =========================================================================
  // TAB 6: PEMBUKAAN PUPUK (SCANNER & GEOFENCING VALIDATION PERSIS WEB)
  // =========================================================================
  // =========================================================================
  // TAB 6: PEMBUKAAN PUPUK (WIZARD 4-TAHAP GEOFENCING PERSIS SCREENSHOT 2, 3, 4, 5)
  // =========================================================================
  Widget _buildPembukaanPupukTabContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row persis Screenshot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.crop_free_rounded, color: primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PEMBUKAAN PUPUK',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pembukaanStep == 'gps'
                                ? 'Validasi geofencing lokasi sebelum pemindaian fisik karung.'
                                : 'Scan QR Code pada karung pupuk untuk melakukan validasi pembukaan di lahan.',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _pembukaanStep = 'gps'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh_rounded, size: 13, color: textDark),
                      SizedBox(width: 3),
                      Text(
                        'Ganti Alokasi / Mulai Ulang',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ribbon 4 Tahap Pembukaan Persis Gambar
          Row(
            children: [
              _buildStepRibbon('1. Pilih Alokasi', isChecked: true, isActive: false),
              const SizedBox(width: 4),
              _buildStepRibbon('2. Validasi GPS', isChecked: _pembukaanStep != 'gps', isActive: _pembukaanStep == 'gps'),
              const SizedBox(width: 4),
              _buildStepRibbon('3. Scan QR Karung', isChecked: ['result', 'success'].contains(_pembukaanStep), isActive: _pembukaanStep == 'scan'),
              const SizedBox(width: 4),
              _buildStepRibbon('4. Validasi & Sukses', isChecked: _pembukaanStep == 'success', isActive: ['result', 'success'].contains(_pembukaanStep)),
            ],
          ),
          const SizedBox(height: 16),

          // STEP 2: VALIDASI GPS (Screenshot 5)
          if (_pembukaanStep == 'gps') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ALOKASI TERPILIH', style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold)),
                      InkWell(
                        onTap: () => setState(() => _pembukaanStep = 'gps'),
                        child: const Text('← Ganti Alokasi', style: TextStyle(color: Color(0xFF0369A1), fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Urea Bersubsidi — 250 kg', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textDark)),
                  const SizedBox(height: 2),
                  const Text('📍 Lahan: Sawah Blok Timur Kebondalem', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card Lokasi Diverifikasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderGray),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                    child: const Icon(Icons.near_me_rounded, color: primaryGreen, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Lokasi Anda sedang diverifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textDark)),
                        SizedBox(height: 2),
                        Text('GPS HP digunakan untuk memastikan petani benar-benar berada di sekitar titik lahan yang terdaftar.', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Coordinates Box 1: Titik Lahan Terdaftar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('TITIK LAHAN TERDAFTAR', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  SizedBox(height: 3),
                  Text('-7.5312, 112.5512', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textDark)),
                  Text('Sawah Blok Timur Kebondalem', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Coordinates Box 2: GPS HP Petani Real-Time
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('GPS HP PETANI REAL-TIME', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  SizedBox(height: 3),
                  Text('-7.531234, 112.551234', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textDark)),
                  Text('Akurasi ~12m', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Distance Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jarak dari titik lahan terdaftar:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    '${_simulatedDistance.toInt()} meter',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: _simulatedDistance <= 100 ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Alert Geofence Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _simulatedDistance <= 100 ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _simulatedDistance <= 100 ? const Color(0xFF86EFAC) : const Color(0xFFFECDD3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _simulatedDistance <= 100 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _simulatedDistance <= 100 ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _simulatedDistance <= 100 ? 'Lokasi GPS Valid & Sesuai' : 'Lokasi Terlalu Jauh dari Sawah',
                        style: TextStyle(
                          color: _simulatedDistance <= 100 ? const Color(0xFF166534) : const Color(0xFF9F1239),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _simulatedDistance <= 100
                        ? 'Anda terdeteksi berada di dalam radius lahan (${_simulatedDistance.toInt()} meter). Silakan lanjutkan untuk memindai QR Code pada karung pupuk.'
                        : 'Anda berada ${_simulatedDistance.toInt()} meter di luar radius sawah yang ditentukan (maksimal 100 meter). Penebusan karung pupuk ditolak.',
                    style: TextStyle(
                      color: _simulatedDistance <= 100 ? const Color(0xFF166534) : const Color(0xFF9F1239),
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Button Action
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              label: const Text('[ SCAN QR PADA KARUNG PUPUK ]', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => setState(() => _pembukaanStep = 'scan'),
            ),
            const SizedBox(height: 12),

            // Simulator Pill Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Uji Coba Geofencing (Demo):', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildDemoChip('✓ Di Sawah (18m)', _simulatedDistance == 18.0, () => setState(() => _simulatedDistance = 18.0)),
                    _buildDemoChip('✕ Luar Lahan (850m)', _simulatedDistance == 850.0, () => setState(() => _simulatedDistance = 850.0)),
                    _buildDemoChip('🛰️ GPS HP Asli', false, () => setState(() => _simulatedDistance = 18.0)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'ℹ️ Fitur ini mensimulasikan radius GPS untuk verifikasi anti-kecurangan pendistribusian pupuk subsidi Mojokerto.',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), height: 1.3),
                ),
              ],
            ),
          ],

          // STEP 3: SCAN QR KARUNG (Screenshot 4)
          if (_pembukaanStep == 'scan') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Color(0xFF34D399), size: 16),
                          SizedBox(width: 6),
                          Text('PEMINDAI QR KARUNG PUPUK FISIK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5)),
                        ],
                      ),
                      Icon(Icons.qr_code_2_rounded, color: Colors.white54, size: 16),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Viewfinder Frame Glowing Green
                  Container(
                    width: 220,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF10B981), width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF022C22).withValues(alpha: 0.4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF34D399), size: 54),
                        SizedBox(height: 8),
                        Text(
                          'KAMERA SCANNER HP',
                          style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Arahkan kamera ke QR Code yang terdapat pada karung pupuk.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 16),

                  // Button Fast Scan Simulation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
                      label: const Text('Scan Urea Bersubsidi 250kg', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => _pembukaanStep = 'result'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Input Manual Token
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qrManualCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'KETIK TOKEN QR PADA KARUNG',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 9.5),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => setState(() => _pembukaanStep = 'result'),
                        child: const Text('Pindai', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Summary Cards Bottom
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderGray)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Penerima Alokasi', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
                        SizedBox(height: 2),
                        Text('Budi Santoso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: textDark)),
                        Text('NIK: 351608*******0002', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderGray)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Lahan Terdaftar', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
                        SizedBox(height: 2),
                        Text('Petak Sawah A-12', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: textDark)),
                        Text('• GPS Valid (24m)', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          // STEP 4A: HASIL VALIDASI (Screenshot 3)
          if (_pembukaanStep == 'result') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.security_rounded, size: 16, color: primaryGreen),
                    SizedBox(width: 6),
                    Text('Hasil Validasi Pembukaan Pupuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textDark)),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() => _pembukaanStep = 'scan'),
                  child: const Text('[ Scan Ulang ]', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 10.5)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Box A: Validasi QR Pupuk
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGray)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('✓ A. VALIDASI QR PUPUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                        child: const Text('QR Pupuk Valid', style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ID PUPUK', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))), Text('EPUPUK - 1 - BUDI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5))])),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JENIS', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))), Text('Urea Bersubsidi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF166534)))])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('BERAT', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))), Text('250 kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5))])),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('STATUS QR', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))), Text('SIAP DIBUKA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF0369A1)))])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Box B: Validasi Alokasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGray)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('✓ B. VALIDASI ALOKASI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Pupuk Sesuai Alokasi', style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ALOKASI PETANI', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))), Text('Budi Santoso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5))])),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JENIS ALOKASI', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))), Text('Urea Bersubsidi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF166534)))])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Box C: Validasi GPS Geofencing
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGray)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('✓ C. VALIDASI GPS / GEOFENCING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Lokasi Berada di Lahan', style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jarak dari Titik Lahan Sawah:', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      Text('${_simulatedDistance.toInt()} meter', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF166534))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                    child: Text('✓ Lahan Terverifikasi. Petani berada dalam radius lahan yang diperbolehkan (${_simulatedDistance.toInt()}m).', style: const TextStyle(color: Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status Box Semua Valid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('STATUS: PEMBUKAAN PUPUK DAPAT DILAKUKAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF166534))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(8)),
                        child: const Text('SEMUA VALID', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(child: Text('✓ QR Pupuk Valid', style: TextStyle(fontSize: 9.5, color: Color(0xFF166534), fontWeight: FontWeight.bold))),
                      Expanded(child: Text('✓ Petani Terverifikasi', style: TextStyle(fontSize: 9.5, color: Color(0xFF166534), fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Expanded(child: Text('✓ Pupuk Sesuai Alokasi', style: TextStyle(fontSize: 9.5, color: Color(0xFF166534), fontWeight: FontWeight.bold))),
                      Expanded(child: Text('✓ Lokasi Berada di Lahan', style: TextStyle(fontSize: 9.5, color: Color(0xFF166534), fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Button Konfirmasi
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064E3B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: () => setState(() => _pembukaanStep = 'success'),
              child: const Text('[ ✓ KONFIRMASI PEMBUKAAN PUPUK ]', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ],

          // STEP 4B: PEMBUKAAN BERHASIL (Screenshot 2)
          if (_pembukaanStep == 'success') ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: Color(0xFFA7F3D0), shape: BoxShape.circle),
                    child: const Center(
                      child: Icon(Icons.check_circle_rounded, color: Color(0xFF065F46), size: 40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(16)),
                    child: const Text('• STATUS: BERHASIL DIBUKA', style: TextStyle(color: Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  const Text('PEMBUKAAN PUPUK BERHASIL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textDark)),
                  const SizedBox(height: 2),
                  const Text('Aktivitas pembukaan pupuk fisik telah divalidasi geofencing dan tercatat di sistem.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                  const SizedBox(height: 14),

                  // 4 Badges row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildSuccessBadge('✓ QR Pupuk Valid'),
                      _buildSuccessBadge('✓ Alokasi Sesuai'),
                      _buildSuccessBadge('✓ Petani Terverifikasi'),
                      _buildSuccessBadge('✓ Lokasi Lahan Sesuai'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detail Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderGray),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Petani:', 'Budi Santoso'),
                        _buildDetailRow('ID Pupuk:', 'EPUPUK-1-BUDISA-84108C', isGreen: true),
                        _buildDetailRow('Jenis Pupuk:', 'Urea Bersubsidi'),
                        _buildDetailRow('Berat:', '250.00 kg', isBoldNumber: true),
                        _buildDetailRow('Lahan:', 'Sawah Blok Timur Kebondalem'),
                        _buildDetailRow('Lokasi:', '📍 GPS Terdeteksi (18m)', isGreen: true),
                        _buildDetailRow('Tanggal:', '14 Oktober 2026'),
                        _buildDetailRow('Jam:', '12.08 WIB'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: () => setState(() {
                      _bottomNavIndex = 3;
                      _activeNav = 7;
                    }),
                    child: const Text('🕒 [ LIHAT RIWAYAT PEMBUKAAN ]', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEEF2FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    onPressed: () => setState(() => _pembukaanStep = 'gps'),
                    child: const Text('Buka Alokasi Lain', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRibbon(String label, {required bool isChecked, required bool isActive}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF064E3B) : (isChecked ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF064E3B) : (isChecked ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : (isChecked ? const Color(0xFF166534) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoChip(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textDark),
        ),
      ),
    );
  }

  Widget _buildSuccessBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
      child: Text(text, style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 9.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isGreen = false, bool isBoldNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBoldNumber ? 13 : 10.5,
              fontWeight: (isBoldNumber || isGreen) ? FontWeight.w900 : FontWeight.bold,
              color: isGreen ? const Color(0xFF166534) : textDark,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 7: RIWAYAT PEMBUKAAN PUPUK (PERSIS SCREENSHOT 1)
  // =========================================================================
  Widget _buildRiwayatPembukaanTabContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 22, color: textDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Riwayat Pembukaan Pupuk (1)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: textDark)),
                          SizedBox(height: 2),
                          Text('Daftar seluruh aktivitas pembukaan karung pupuk subsidi yang telah divalidasi GPS di lahan terdaftar.', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFF166534)),
                    SizedBox(width: 3),
                    Text('Total Digunakan: 250 kg', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Item Pembukaan persis Screenshot 1
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGray),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF009B69),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFFE11D48)),
                              SizedBox(width: 4),
                              Text('14 October 2026', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textDark)),
                              SizedBox(width: 4),
                              Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                              SizedBox(width: 4),
                              Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                              SizedBox(width: 3),
                              Text('12:08 WIB', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(14)),
                            child: const Text('✓ Pembukaan Berhasil', style: TextStyle(color: Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Urea Bersubsidi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textDark)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                                child: const Text('250.00 kg', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Text('Lihat Detail >', style: TextStyle(color: Color(0xFF009B69), fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF1F5F9))),
                        child: Row(
                          children: const [
                            Icon(Icons.location_on_outlined, size: 15, color: primaryGreen),
                            SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Lahan: Sawah Blok Timur Kebondalem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: textDark)),
                                  Text('Lokasi: -7.5312, 112.5512', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer Info Prototype
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
              SizedBox(width: 5),
              Text('Prototipe Visual — Menampilkan data riwayat pembukaan pupuk tersimpan.', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MAIN SCAFFOLD & BODY
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slateBg,
      appBar: _buildCustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              color: primaryGreen,
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Banner (#064E3B) — Tampil di Tab 0, 6, dan 7 persis Screenshot UI
                    if (_activeNav == 0 || _activeNav == 6 || _activeNav == 7) ...[
                      _buildTopBanner(),
                      const SizedBox(height: 14),
                    ],

                    // 2. Horizontal Pill Tabs
                    _buildPillNavigation(),
                    const SizedBox(height: 16),

                    // 3. Tab Contents persis Screenshot UI
                    if (_activeNav == 0) ...[
                      // Dashboard Home persis Screenshot UI Dashboard
                      _buildKpiGrid(),
                      const SizedBox(height: 14),
                      _buildProfilPetaniCard(),
                      const SizedBox(height: 14),
                      _buildDashboardRingkasanKuotaCard(),
                      const SizedBox(height: 16),
                      _buildDashboardStatusPengajuanTerkini(),
                    ] else if (_activeNav == 1) ...[
                      _buildProfileTabContent(),
                    ] else if (_activeNav == 2) ...[
                      _buildLandsTabContent(),
                    ] else if (_activeNav == 3) ...[
                      _buildApplicationTabContent(),
                    ] else if (_activeNav == 4) ...[
                      _buildStatusPengajuanTerkiniSection(),
                    ] else if (_activeNav == 5) ...[
                      _buildRingkasanKuotaCard(),
                    ] else if (_activeNav == 6) ...[
                      _buildPembukaanPupukTabContent(),
                    ] else if (_activeNav == 7) ...[
                      _buildRiwayatPembukaanTabContent(),
                    ] else ...[
                      _buildKpiGrid(),
                      const SizedBox(height: 14),
                      _buildStatusPengajuanTerkiniSection(),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      // 4. Bottom Navigation Bar Persis Gambar
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }
}
