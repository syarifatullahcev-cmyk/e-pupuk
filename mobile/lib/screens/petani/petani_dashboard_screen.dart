import 'dart:math';
import 'package:flutter/material.dart';
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
  List<DistributionModel> _distributions = [];
  List<ScanHistoryModel> _scans = [];

  // Form Pengajuan Subsidi State
  int? _formLandId;
  int? _formFertilizerId;
  final TextEditingController _formJumlahCtrl = TextEditingController();
  bool _isSubmittingApp = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _formJumlahCtrl.dispose();
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
        // Avatar Circle "B"
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Center(
            child: Text(
              initialLetter,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.bold,
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
          // Chip "PORTAL PETANI & KELOMPOK TANI"
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
                Icon(Icons.auto_awesome, size: 12, color: Color(0xFF6EE7B7)),
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
              Row(
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
                  const Text(
                    'PROFIL PETANI',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.4,
                      color: textDark,
                    ),
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
  // 5. RINGKASAN KUOTA (MUSIM TANAM 2026) PERSIS SEPERTI DI GAMBAR
  // =========================================================================
  Widget _buildRingkasanKuotaCard() {
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.pie_chart_outline_rounded, size: 16, color: primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Ringkasan Kuota (Musim Tanam 2026)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: textDark),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _activeNav = 5),
                child: Row(
                  children: const [
                    Text(
                      'Detail',
                      style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 14, color: primaryGreen),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Inner Card Urea
          Container(
            padding: const EdgeInsets.all(14),
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
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: textDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sisa ${_sisaKuotaUrea.toInt()} kg',
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        children: [
                          const TextSpan(text: 'Kuota Disetujui: '),
                          TextSpan(
                            text: '${_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea.toInt() : 500} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        children: [
                          const TextSpan(text: 'Sudah Digunakan: '),
                          TextSpan(
                            text: '${_totalUreaUsed.toInt()} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.14,
                    backgroundColor: Color(0xFFE2E8F0),
                    color: primaryGreen,
                    minHeight: 6.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '14% kuota terpakai',
                    style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Inner Card NPK
          Container(
            padding: const EdgeInsets.all(14),
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
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: textDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sisa ${_sisaKuotaNpk.toInt()} kg',
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        children: [
                          const TextSpan(text: 'Kuota Disetujui: '),
                          TextSpan(
                            text: '${_kuotaDisetujuiNpk > 0 ? _kuotaDisetujuiNpk.toInt() : 400} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        children: [
                          const TextSpan(text: 'Sudah Digunakan: '),
                          TextSpan(
                            text: '${_totalNpkUsed.toInt()} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.12,
                    backgroundColor: Color(0xFFE2E8F0),
                    color: Color(0xFF2563EB),
                    minHeight: 6.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '12% kuota terpakai',
                    style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Status Pengajuan Terkini',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: textDark),
                ),
                SizedBox(height: 2),
                Text(
                  'Lacak perkembangan verifikasi & survei lahan',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                ),
              ],
            ),
            InkWell(
              onTap: () => setState(() => _activeNav = 4),
              child: Row(
                children: const [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(color: primaryGreen, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 14, color: primaryGreen),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Card #1: Pupuk Urea Bersubsidi — 250 kg (Telah Disalurkan)
        _buildExactWebStepperCard(
          id: '#1',
          name: 'Pupuk Urea Bersubsidi',
          weight: '250 kg',
          location: 'Lahan: Sawah Blok Timur Kebondalem',
          status: 'TERSALURKAN',
        ),
        const SizedBox(height: 12),

        // Card #3: Pupuk NPK Phonska Bersubsidi — 150 kg (Menunggu Persetujuan Akhir)
        _buildExactWebStepperCard(
          id: '#3',
          name: 'Pupuk NPK Phonska Bersubsidi',
          weight: '150 kg',
          location: 'Lahan: Sawah Blok Timur Kebondalem',
          status: 'MENUNGGU_PERSETUJUAN_AKHIR',
        ),
      ],
    );
  }

  Widget _buildExactWebStepperCard({
    required String id,
    required String name,
    required String weight,
    required String location,
    required String status,
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
                      location,
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
        ],
      ),
    );
  }

  Widget _buildExactStatusBadge(String status) {
    if (status == 'TERSALURKAN') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
        decoration: BoxDecoration(
          color: const Color(0xFF009B69),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white),
            SizedBox(width: 5.5),
            Text(
              'Telah Disalurkan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'MENUNGGU_PERSETUJUAN_AKHIR') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8B4FE), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF7E22CE)),
            SizedBox(width: 5.5),
            Text(
              'Menunggu Persetujuan Akhir',
              style: TextStyle(
                color: Color(0xFF7E22CE),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check, size: 12, color: Color(0xFF166534)),
            SizedBox(width: 4.5),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profil Lengkap Petani', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: const Text('Terverifikasi', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 20),
          _profileRow('Nama Lengkap', _farmer?.nama ?? widget.user.nama),
          _profileRow('Nomor Induk Kependudukan (NIK)', _farmer?.nik ?? '3516011208830001'),
          _profileRow('Nomor HP / WhatsApp', _farmer?.kontak ?? '081234567890'),
          _profileRow('Kelompok Tani (Poktan)', _farmer?.kelompokTani ?? 'Poktan Sumber Makmur'),
          _profileRow('Wilayah Binaan', _farmer?.wilayahPoktan ?? 'Kecamatan Mojosari, Mojokerto'),
          _profileRow('Alamat Domisili KTP', _farmer?.alamat ?? 'Desa Kebondalem, Mojosari, Mojokerto'),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildLandsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daftar Lahan Pertanian (${_lands.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Tambah Lahan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, visualDensity: VisualDensity.compact),
              onPressed: _showAddLandDialog,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_lands.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('Belum ada lahan pertanian terdaftar.', style: TextStyle(color: Colors.grey))),
          )
        else
          ..._lands.map((land) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderGray),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.terrain_rounded, color: primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(land.lokasiDeskripsi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Luas: ${land.luasM2.toInt()} m² • ${land.statusKepemilikan}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text(land.alamatLahan, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
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
            const Text('Belum ada data lahan.', style: TextStyle(color: Colors.red, fontSize: 11))
          else
            DropdownButtonFormField<int>(
              initialValue: _formLandId,
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
            initialValue: _formFertilizerId,
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

  void _showAddLandDialog() {
    final deskripsiCtrl = TextEditingController();
    final luasCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    String kepemilikan = 'MILIK';
    final selectedComId = _commodities.isNotEmpty ? _commodities.first.id : 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Tambah Lahan Pertanian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Lahan *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: deskripsiCtrl, decoration: const InputDecoration(hintText: 'Contoh: Sawah Blok B', isDense: true, border: OutlineInputBorder())),
                const SizedBox(height: 10),
                const Text('Luas (m²) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: luasCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '2500', isDense: true, border: OutlineInputBorder())),
                const SizedBox(height: 10),
                const Text('Alamat Lengkap *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: alamatCtrl, decoration: const InputDecoration(hintText: 'Desa Kebondalem', isDense: true, border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: () async {
                if (deskripsiCtrl.text.isEmpty || luasCtrl.text.isEmpty || alamatCtrl.text.isEmpty) return;
                final luas = double.tryParse(luasCtrl.text) ?? 1000;
                Navigator.pop(ctx);
                final res = await SubsidyService.createLand(
                  lokasiDeskripsi: deskripsiCtrl.text,
                  luasM2: luas,
                  alamatLahan: alamatCtrl.text,
                  statusKepemilikan: kepemilikan,
                  commodityId: selectedComId,
                );
                if (res['success'] == true) {
                  _loadAllData();
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
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
  Widget _buildPembukaanPupukTabContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Pembukaan Pupuk', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: textDark)),
                    Text('Validasi geofencing GPS pada karung pupuk fisik di petak lahan', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ribbon 4 Tahap Pembukaan
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderGray),
            ),
            child: Row(
              children: [
                _stepRibbonItem('1. Pilih Alokasi', true),
                _stepRibbonItem('2. Validasi GPS', false),
                _stepRibbonItem('3. Scan QR', false),
                _stepRibbonItem('4. Selesai', false),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Alokasi Pupuk Siap Dibuka di Lahan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
          const SizedBox(height: 10),
          if (_distributions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderGray),
              ),
              child: Column(
                children: const [
                  Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 36),
                  SizedBox(height: 8),
                  Text('Belum ada alokasi pupuk yang siap ditebus/dibuka.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            ..._distributions.map((dist) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dist.namaPupuk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                            const SizedBox(height: 2),
                            Text('Jumlah: ${dist.jumlahDisalurkan.toInt()} kg • ${dist.namaLahan}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        label: const Text('Buka Pupuk', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, visualDensity: VisualDensity.compact),
                        onPressed: () => _showScanBagDialog(dist),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _stepRibbonItem(String title, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? primaryGreen : borderGray),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  void _showScanBagDialog(DistributionModel dist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner_rounded, color: primaryGreen),
            SizedBox(width: 8),
            Text('Scan QR Karung Pupuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pupuk: ${dist.namaPupuk} (${dist.jumlahDisalurkan.toInt()} kg)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            Text('Lokasi: ${dist.namaLahan}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            const SizedBox(height: 14),
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.crop_free_rounded, color: Color(0xFF34D399), size: 56),
                  SizedBox(height: 8),
                  Text('Arahkan kamera ke QR Code karung', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  SizedBox(height: 4),
                  Text('Radius Geofencing Lahan: 50 meter', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await SubsidyService.scanQrBag(
                qrToken: dist.qrCodeHash.isNotEmpty ? dist.qrCodeHash : 'PUPUK-DEMO-${dist.id}',
                latitude: dist.latitude ?? -7.531234,
                longitude: dist.longitude ?? 112.551234,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['message'] ?? 'Pemindaian berhasil divalidasi di lahan!'),
                  backgroundColor: res['success'] == true ? primaryGreen : Colors.red,
                ),
              );
              _loadAllData();
            },
            child: const Text('Simulasi Scan Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 7: RIWAYAT PEMBUKAAN PUPUK PERSIS WEB
  // =========================================================================
  Widget _buildRiwayatPembukaanTabContent() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded, color: primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Pembukaan (${_scans.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: textDark)),
                      const Text('Daftar pembukaan karung pupuk divalidasi GPS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_scans.length * 50} kg terbuka',
                  style: const TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_scans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: const [
                  Icon(Icons.history_rounded, size: 48, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 10),
                  Text('Belum Ada Riwayat Pembukaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                  SizedBox(height: 4),
                  Text('Buka pupuk subsidi di petak sawah melalui menu "Pembukaan Pupuk".', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            )
          else
            ..._scans.map((scan) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderGray),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded, color: primaryGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(scan.jenisPupuk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                            const SizedBox(height: 2),
                            Text('Jumlah: ${scan.jumlahPupuk} • Lahan: ${scan.namaLahan}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            Text('Waktu: ${scan.tanggal} ${scan.waktu}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('GPS Valid', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )),
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
                    // 1. Top Banner (#064E3B)
                    _buildTopBanner(),
                    const SizedBox(height: 14),

                    // 2. Horizontal Pill Tabs
                    _buildPillNavigation(),
                    const SizedBox(height: 16),

                    // 3. Tab Contents
                    if (_activeNav == 0) ...[
                      // Dashboard Home (Persis seperti di gambar!)
                      _buildKpiGrid(),
                      const SizedBox(height: 14),
                      _buildProfilPetaniCard(),
                      const SizedBox(height: 14),
                      _buildRingkasanKuotaCard(),
                      const SizedBox(height: 18),
                      _buildStatusPengajuanTerkiniSection(),
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
