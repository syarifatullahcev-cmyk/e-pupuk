import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  // Palet Warna Resmi Web E-Pupuk Mojokerto
  static const Color darkEmerald = Color(0xFF064E3B);
  static const Color primaryGreen = Color(0xFF059669);
  static const Color slateBg = Color(0xFFF8FAFC);

  // Tab Navigasi Aktif (0: Dashboard, 1: Profil, 2: Lahan, 3: Pengajuan, 4: Status, 5: Kuota, 6: Pembukaan, 7: Riwayat)
  int _activeNav = 0;
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

  // =========================================================================
  // GEOFENCING GPS & SCANNER QR KARUNG STATE
  // Step: 'select' | 'gps' | 'scan' | 'result' | 'success'
  // =========================================================================
  String _pembukaanStep = 'select';
  DistributionModel? _selectedDistribution;
  int _simulatedDistance = 18; // default 18m
  final TextEditingController _manualQrCtrl = TextEditingController();
  bool _isProcessingOpen = false;
  Map<String, dynamic>? _lastOpenSuccess;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _formJumlahCtrl.dispose();
    _manualQrCtrl.dispose();
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
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Kalkulasi Kuota Dinamis
  double get _totalUreaUsed => _scans
      .where((s) => s.jenisPupuk.toLowerCase().contains('urea'))
      .fold(0.0, (sum, s) => sum + s.jumlahKg);

  double get _totalNpkUsed => _scans
      .where((s) => s.jenisPupuk.toLowerCase().contains('npk'))
      .fold(0.0, (sum, s) => sum + s.jumlahKg);

  double get _totalPupukDigunakan => _totalUreaUsed + _totalNpkUsed;

  double get _kuotaDisetujuiUrea => _applications
      .where((a) => ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].contains(a.status))
      .where((a) => (a.namaPupuk ?? '').toLowerCase().contains('urea'))
      .fold(0.0, (sum, a) => sum + (a.jumlahDisetujui ?? a.jumlahDiajukan));

  double get _sisaKuotaUrea => max(0.0, (_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea : 500.0) - _totalUreaUsed);

  double get _kuotaDisetujuiNpk => _applications
      .where((a) => ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].contains(a.status))
      .where((a) => (a.namaPupuk ?? '').toLowerCase().contains('npk'))
      .fold(0.0, (sum, a) => sum + (a.jumlahDisetujui ?? a.jumlahDiajukan));

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
  // SUBMISSION FORMS
  // =========================================================================
  Future<void> _handleSubmitApplication() async {
    if (_formLandId == null || _formFertilizerId == null || _formJumlahCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua kolom pengajuan.')),
      );
      return;
    }

    final double? jumlah = double.tryParse(_formJumlahCtrl.text.trim());
    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pupuk harus berupa angka valid (> 0).')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: primaryGreen,
          content: Text('Pengajuan subsidi pupuk berhasil dikirim! Masuk tahap Verifikasi.'),
        ),
      );
      _formJumlahCtrl.clear();
      await _loadAllData();
      setState(() => _activeNav = 4); // Buka tab status
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Gagal mengirim pengajuan.')),
      );
    }
  }

  void _showAddLandDialog() {
    final deskripsiCtrl = TextEditingController();
    final luasCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    String kepemilikan = 'MILIK';
    int? selectedComId = _commodities.isNotEmpty ? _commodities.first.id : 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Tambah Lahan Pertanian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama / Deskripsi Lahan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: deskripsiCtrl,
                  decoration: const InputDecoration(hintText: 'Contoh: Sawah Blok Timur', isDense: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Luas Lahan (m²) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: luasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Contoh: 2500', isDense: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Status Kepemilikan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: kepemilikan,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'MILIK', child: Text('Milik Sendiri')),
                    DropdownMenuItem(value: 'SEWA', child: Text('Sewa / Garap')),
                  ],
                  onChanged: (v) => setDlgState(() => kepemilikan = v!),
                ),
                const SizedBox(height: 12),
                const Text('Alamat Lengkap Lahan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: alamatCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Desa, Dusun, RT/RW, Kecamatan', isDense: true, border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: () async {
                if (deskripsiCtrl.text.isEmpty || luasCtrl.text.isEmpty || alamatCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi kolom wajib.')));
                  return;
                }
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: primaryGreen, content: Text('Lahan berhasil didaftarkan!')),
                  );
                  _loadAllData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Gagal mendaftarkan lahan.')),
                  );
                }
              },
              child: const Text('Simpan Lahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrVoucherModal(DistributionModel dist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 40, color: primaryGreen),
            const SizedBox(height: 8),
            const Text(
              'E-Tiket Penebusan Kios',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tunjukkan QR ini ke Petugas Kios Resmi',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: dist.qrCodeHash.isNotEmpty ? dist.qrCodeHash : 'PUPUK-${dist.id}',
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${dist.namaPupuk} — ${dist.jumlahDisalurkan.toInt()} Kg',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkEmerald),
            ),
            Text(
              'Kode: ${dist.qrCodeHash}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TOP BAR & PILL NAVIGATION (Persis seperti di Web PetaniDashboard)
  // =========================================================================
  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkEmerald,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF043E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, size: 13, color: Color(0xFF6EE7B7)),
                SizedBox(width: 6),
                Text(
                  'PORTAL PETANI & KELOMPOK TANI KAB. MOJOKERTO',
                  style: TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Selamat Datang, ${_farmer?.nama ?? widget.user.nama}!',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistem resmi verifikasi subsidi, pemantauan kuota, dan pemindaian QR Code pada karung pupuk fisik berbasis GPS geofencing.',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPillNavigation() {
    final navItems = [
      {'id': 0, 'label': 'Dashboard', 'icon': Icons.dashboard_rounded},
      {'id': 1, 'label': 'Profil Saya', 'icon': Icons.person_rounded},
      {'id': 2, 'label': 'Data Lahan', 'icon': Icons.location_on_rounded},
      {'id': 3, 'label': 'Pengajuan Subsidi', 'icon': Icons.description_rounded},
      {'id': 4, 'label': 'Status Pengajuan', 'icon': Icons.schedule_rounded},
      {'id': 5, 'label': 'Kuota Pupuk', 'icon': Icons.pie_chart_rounded},
      {'id': 6, 'label': 'Pembukaan Pupuk', 'icon': Icons.qr_code_scanner_rounded, 'special': true},
      {'id': 7, 'label': 'Riwayat Pembukaan', 'icon': Icons.history_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: navItems.map((item) {
          final int id = item['id'] as int;
          final bool isActive = _activeNav == id;
          final bool isSpecial = item['special'] == true;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _activeNav = id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? primaryGreen
                        : isSpecial
                            ? const Color(0xFFDCFCE7)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? primaryGreen
                          : isSpecial
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 15,
                        color: isActive
                            ? Colors.white
                            : isSpecial
                                ? darkEmerald
                                : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : isSpecial
                                  ? darkEmerald
                                  : const Color(0xFF334155),
                        ),
                      ),
                      if (isSpecial && !isActive) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================================
  // 1. TAB DASHBOARD (BERANDA RINGKASAN & KPI CARDS)
  // =========================================================================
  Widget _buildDashboardTab() {
    final activeCount = _stats?.aktif ?? _applications.where((a) => !['TERSALURKAN', 'DITOLAK_BERKAS', 'DITOLAK_LAPANGAN'].contains(a.status)).length;
    final latestApp = _applications.isNotEmpty ? _applications.first : null;

    final ureaPercent = _kuotaDisetujuiUrea > 0 ? ((_totalUreaUsed / _kuotaDisetujuiUrea) * 100).round() : 0;
    final npkPercent = _kuotaDisetujuiNpk > 0 ? ((_totalNpkUsed / _kuotaDisetujuiNpk) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4 KPI Cards
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          children: [
            _buildKpiCard(
              title: 'SISA KUOTA UREA',
              value: '${_sisaKuotaUrea.toInt()} kg',
              subtitle: 'Dari kuota ${_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea.toInt() : 500} kg',
              icon: Icons.grass,
              color: const Color(0xFF059669),
              badge: 'Subsidi',
            ),
            _buildKpiCard(
              title: 'SISA KUOTA NPK',
              value: '${_sisaKuotaNpk.toInt()} kg',
              subtitle: 'Dari kuota ${_kuotaDisetujuiNpk > 0 ? _kuotaDisetujuiNpk.toInt() : 400} kg',
              icon: Icons.agriculture_rounded,
              color: const Color(0xFF0284C7),
              badge: 'Subsidi',
            ),
            _buildKpiCard(
              title: 'PENGAJUAN AKTIF',
              value: '$activeCount Berjalan',
              subtitle: 'Verifikasi & Survei PPL',
              icon: Icons.sync,
              color: const Color(0xFFD97706),
              badge: 'Aktif',
            ),
            _buildKpiCard(
              title: 'PUPUK SUDAH DIGUNAKAN',
              value: '${_totalPupukDigunakan.toInt()} kg',
              subtitle: 'Divalidasi GPS di Lahan',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF7C3AED),
              badge: 'Tervalidasi',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Profil Petani Quick Card & Kuota Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person, size: 16, color: primaryGreen),
                      SizedBox(width: 6),
                      Text('Profil Petani', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Akun Resmi', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nama Lengkap', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  Text(_farmer?.nama ?? widget.user.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NIK KTP', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  Text(_farmer?.nik ?? '-', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kelompok Tani', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  Text(_farmer?.kelompokTani ?? 'Poktan Mojokerto', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _activeNav = 1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Lihat Profil Selengkapnya', style: TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Ringkasan Kuota Pupuk (Progress Bars)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ringkasan Kuota Musim Tanam 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton(
                    onPressed: () => setState(() => _activeNav = 5),
                    child: const Text('Detail Kuota', style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Urea Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('UREA BERSUBSIDI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text('Sisa ${_sisaKuotaUrea.toInt()} kg', style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (ureaPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: primaryGreen,
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 12),
              // NPK Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NPK PHONSKA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text('Sisa ${_sisaKuotaNpk.toInt()} kg', style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (npkPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF0284C7),
                  minHeight: 7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tombol Pintas Ajukan Subsidi (Hijau Besar)
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
            label: const Text('Ajukan Subsidi Pupuk Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _activeNav = 3),
          ),
        ),
        const SizedBox(height: 16),

        // Live Tracker Pengajuan Terakhir
        if (latestApp != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Pengajuan Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    _buildStatusBadge(latestApp.status),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(latestApp.namaPupuk ?? 'Pupuk Bersubsidi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${latestApp.jumlahDiajukan.toInt()} Kg', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 13)),
                  ],
                ),
                Text(latestApp.lokasiLahan ?? 'Lahan Petani', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                const SizedBox(height: 10),
                _buildMiniStepper(latestApp.status),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _activeNav = 4),
                    child: const Text('Lihat Detail Stepper & Verifikasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // 2. TAB PROFIL SAYA
  // =========================================================================
  Widget _buildProfileTab() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Profil Petani Terdaftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Data kependudukan & keanggotaan Poktan resmi', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Terverifikasi', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24),

          // Foto KTP Box
          const Text('FOTO KTP TERDAFTAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 6),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: _farmer?.fotoKtpUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _farmer!.fotoKtpUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('Foto KTP e-KTP Tersimpan', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 36, color: Color(0xFF94A3B8)),
                        SizedBox(height: 6),
                        Text('Foto e-KTP telah terverifikasi di Dinas', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 18),

          // Grid Data Petani
          _profileItem('Nama Lengkap', _farmer?.nama ?? widget.user.nama),
          _profileItem('Nomor Induk Kependudukan (NIK)', _farmer?.nik ?? '-'),
          _profileItem('Nomor HP / WhatsApp', _farmer?.kontak ?? '-'),
          _profileItem('Username Akun', widget.user.username),
          _profileItem('Kelompok Tani (Poktan)', _farmer?.kelompokTani ?? 'Poktan Tani Makmur'),
          _profileItem('Wilayah Binaan', _farmer?.wilayahPoktan ?? 'Kecamatan Mojosari, Mojokerto'),
          _profileItem('Alamat Domisili KTP', _farmer?.alamat ?? 'Kabupaten Mojokerto, Jawa Timur'),
        ],
      ),
    );
  }

  Widget _profileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. TAB DATA LAHAN
  // =========================================================================
  Widget _buildLandsTab() {
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
          ..._lands.map((land) => _buildLandCard(land)),
      ],
    );
  }

  Widget _buildLandCard(LandModel land) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.terrain_rounded, color: primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(land.lokasiDeskripsi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('Luas: ${land.luasM2.toInt()} m² • Kepemilikan: ${land.statusKepemilikan}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(land.alamatLahan, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if (land.latitude != null && land.longitude != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 13, color: primaryGreen),
                const SizedBox(width: 4),
                Text('Koordinat: ${land.latitude!.toStringAsFixed(6)}, ${land.longitude!.toStringAsFixed(6)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF475569))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // 4. TAB PENGAJUAN SUBSIDI (FORM)
  // =========================================================================
  Widget _buildApplicationTab() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Form Pengajuan Subsidi Pupuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Text('Ajukan alokasi pupuk bersubsidi sesuai kebutuhan lahan Anda', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          const Divider(height: 20),

          // Pilih Lahan
          const Text('Pilih Lahan Pertanian *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (_lands.isEmpty)
            const Text('Belum ada lahan. Daftarkan lahan di tab Data Lahan terlebih dahulu.', style: TextStyle(color: Colors.red, fontSize: 11))
          else
            DropdownButtonFormField<int>(
              value: _formLandId,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: _lands.map((l) => DropdownMenuItem(value: l.id, child: Text('${l.lokasiDeskripsi} (${l.luasM2.toInt()} m²)', style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) => setState(() => _formLandId = v),
            ),
          const SizedBox(height: 14),

          // Pilih Pupuk
          const Text('Pilih Jenis Pupuk *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _formFertilizerId,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: _fertilizers.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.namaPupuk} — Rp ${f.hargaSubsidi.toInt()}/kg', style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _formFertilizerId = v),
          ),
          const SizedBox(height: 14),

          // Jumlah Pupuk
          const Text('Jumlah Diajukan (Kg) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _formJumlahCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Contoh: 150',
              suffixText: 'Kg',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Checklist Verifikasi Berkas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Persyaratan Berkas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                SizedBox(height: 4),
                Text('✓ Foto e-KTP terdaftar di profil', style: TextStyle(fontSize: 10.5, color: Color(0xFF166534))),
                Text('✓ Lahan terdaftar dalam RDKK Poktan', style: TextStyle(fontSize: 10.5, color: Color(0xFF166534))),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _isSubmittingApp ? null : _handleSubmitApplication,
              child: _isSubmittingApp
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Pengajuan Subsidi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. TAB STATUS PENGAJUAN (DENGAN 6-STAGE STEPPER)
  // =========================================================================
  Widget _buildStatusTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Status & Riwayat Pengajuan (${_applications.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Ajukan Baru', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, visualDensity: VisualDensity.compact),
              onPressed: () => setState(() => _activeNav = 3),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_applications.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('Belum ada riwayat pengajuan subsidi.', style: TextStyle(color: Colors.grey))),
          )
        else
          ..._applications.map((app) => _buildApplicationStatusCard(app)),
      ],
    );
  }

  Widget _buildApplicationStatusCard(ApplicationModel app) {
    final isReadyOpen = ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI'].contains(app.status);

    // Cari voucher jika sudah disetujui
    final matchingDist = _distributions.where((d) => d.applicationId == app.id).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${app.id} — ${app.namaPupuk ?? 'Pupuk'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${app.jumlahDiajukan.toInt()} Kg • ${app.lokasiLahan ?? 'Lahan Petani'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
              _buildStatusBadge(app.status),
            ],
          ),
          const Divider(height: 18),

          // 6-STAGE PROGRESS STEPPER
          const Text('Alur Proses Pengajuan:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildFullProgressStepper(app.status),
          const SizedBox(height: 12),

          // Catatan Admin atau Survei PPL jika ada
          if (app.catatanAdminBerkas != null && app.catatanAdminBerkas!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Catatan Verifikasi: ${app.catatanAdminBerkas}', style: const TextStyle(color: Color(0xFF92400E), fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (app.surveyRekomendasi != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hasil Survei Lapangan PPL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E40AF))),
                  const SizedBox(height: 2),
                  Text('Rekomendasi: ${app.surveyRekomendasi} • Kondisi: ${app.surveyKondisiLahan ?? '-'}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF1E3A8A))),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Tombol Aksi
          Row(
            children: [
              if (matchingDist != null)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code, size: 14),
                    label: const Text('Lihat E-Tiket QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showQrVoucherModal(matchingDist),
                  ),
                ),
              if (isReadyOpen) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    label: const Text('Scan QR Karung', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                    onPressed: () {
                      setState(() {
                        _selectedDistribution = matchingDist;
                        _pembukaanStep = 'gps';
                        _activeNav = 6; // Buka tab pembukaan
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. TAB KUOTA PUPUK SAYA
  // =========================================================================
  Widget _buildKuotaTab() {
    final ureaPercent = _kuotaDisetujuiUrea > 0 ? ((_totalUreaUsed / _kuotaDisetujuiUrea) * 100).round() : 0;
    final npkPercent = _kuotaDisetujuiNpk > 0 ? ((_totalNpkUsed / _kuotaDisetujuiNpk) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Kuota Pupuk Bersubsidi (Tahun 2026)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Text('Berdasarkan RDKK resmi Dinas Pertanian Kabupaten Mojokerto', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 14),

        // UREA Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Ur', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('UREA BERSUBSIDI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Pupuk Tunggal Nitrogen', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Alokasi Aktif', style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('Kuota RDKK', '${_kuotaDisetujuiUrea > 0 ? _kuotaDisetujuiUrea.toInt() : 500} Kg'),
                  _statItem('Sudah Dipakai', '${_totalUreaUsed.toInt()} Kg'),
                  _statItem('Sisa Tersedia', '${_sisaKuotaUrea.toInt()} Kg', isHighlight: true, color: primaryGreen),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (ureaPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: primaryGreen,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text('$ureaPercent% kuota musim tanam terpakai', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), textAlign: TextAlign.right),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // NPK Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                        child: const Text('NPK', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('NPK PHONSKA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Pupuk Majemuk N-P-K', style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Alokasi Aktif', style: TextStyle(color: Color(0xFF0369A1), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('Kuota RDKK', '${_kuotaDisetujuiNpk > 0 ? _kuotaDisetujuiNpk.toInt() : 400} Kg'),
                  _statItem('Sudah Dipakai', '${_totalNpkUsed.toInt()} Kg'),
                  _statItem('Sisa Tersedia', '${_sisaKuotaNpk.toInt()} Kg', isHighlight: true, color: const Color(0xFF0284C7)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (npkPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF0284C7),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text('$npkPercent% kuota musim tanam terpakai', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), textAlign: TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, {bool isHighlight = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? const Color(0xFF0F172A))),
      ],
    );
  }

  // =========================================================================
  // 7. TAB PEMBUKAAN PUPUK (GEOFENCING GPS & QR SCANNER SAK)
  // =========================================================================
  Widget _buildPembukaanTab() {
    // List alokasi yang belum dibuka
    final pendingDistributions = _distributions.where((d) => d.statusPenyaluran == 'MENUNGGU_PENGAMBILAN').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Text('Pembukaan Pupuk Fisik di Sawah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const Text('Validasi GPS Geofencing radius 100m dan pemindaian QR Code pada karung pupuk', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 14),

        // STEP 1: SELECT
        if (_pembukaanStep == 'select') ...[
          if (pendingDistributions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text('Belum Ada Alokasi Pupuk yang Siap Dibuka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Pastikan pengajuan Anda telah disetujui Admin untuk membuka sak pupuk di sawah.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            )
          else ...[
            const Text('Pilih Karung Alokasi yang Siap Dibuka:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            ...pendingDistributions.map((dist) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dist.namaPupuk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${dist.jumlahDisalurkan.toInt()} Kg • ${dist.namaLahan}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, visualDensity: VisualDensity.compact),
                        onPressed: () {
                          setState(() {
                            _selectedDistribution = dist;
                            _pembukaanStep = 'gps';
                          });
                        },
                        child: const Text('Buka Pupuk', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )),
          ],
        ],

        // STEP 2: GPS GEOFENCING
        if (_pembukaanStep == 'gps' && _selectedDistribution != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Verifikasi Geofencing GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _pembukaanStep = 'select'),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Distance Display
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _simulatedDistance <= 100 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _simulatedDistance <= 100 ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: _simulatedDistance <= 100 ? primaryGreen : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _simulatedDistance <= 100 ? 'Lokasi GPS Valid & Sesuai' : 'Lokasi Terlalu Jauh dari Lahan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _simulatedDistance <= 100 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              'Jarak dari titik sawah: $_simulatedDistance meter (Radius max: 100m)',
                              style: TextStyle(
                                color: _simulatedDistance <= 100 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Demo Simulator Buttons
                const Text('Uji Coba Geofencing (Demo):', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _simulatedDistance == 18 ? const Color(0xFFDCFCE7) : Colors.white,
                          side: BorderSide(color: _simulatedDistance == 18 ? primaryGreen : const Color(0xFFCBD5E1)),
                        ),
                        onPressed: () => setState(() => _simulatedDistance = 18),
                        child: const Text('✓ Di Sawah (18m)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _simulatedDistance == 850 ? const Color(0xFFFEE2E2) : Colors.white,
                          side: BorderSide(color: _simulatedDistance == 850 ? Colors.red : const Color(0xFFCBD5E1)),
                        ),
                        onPressed: () => setState(() => _simulatedDistance = 850),
                        child: const Text('✕ Luar (850m)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Button
                if (_simulatedDistance <= 100)
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      label: const Text('SCAN QR PADA KARUNG PUPUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => setState(() => _pembukaanStep = 'scan'),
                    ),
                  )
                else
                  const Text('Dekati titik lahan sawah Anda untuk mengaktifkan pemindai karung pupuk.', style: TextStyle(color: Colors.red, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],

        // STEP 3: SCAN QR KARUNG
        if (_pembukaanStep == 'scan' && _selectedDistribution != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pemindai QR Karung Pupuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _pembukaanStep = 'gps'),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Viewfinder UI Mockup
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryGreen, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Atau Masukkan Kode Token QR Karung:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _manualQrCtrl,
                  decoration: InputDecoration(
                    hintText: _selectedDistribution!.qrCodeHash,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste, size: 18),
                      onPressed: () => _manualQrCtrl.text = _selectedDistribution!.qrCodeHash,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isProcessingOpen
                        ? null
                        : () async {
                            final code = _manualQrCtrl.text.trim().isNotEmpty ? _manualQrCtrl.text.trim() : _selectedDistribution!.qrCodeHash;
                            setState(() => _isProcessingOpen = true);
                            final res = await SubsidyService.scanQrBag(
                              qrToken: code,
                              latitude: _selectedDistribution!.latitude ?? -7.531234,
                              longitude: _selectedDistribution!.longitude ?? 112.551234,
                            );
                            setState(() => _isProcessingOpen = false);

                            if (res['success'] == true) {
                              setState(() {
                                _lastOpenSuccess = {
                                  'pupuk': _selectedDistribution!.namaPupuk,
                                  'jumlah': '${_selectedDistribution!.jumlahDisalurkan.toInt()} Kg',
                                  'lahan': _selectedDistribution!.namaLahan,
                                  'jarak': '$_simulatedDistance m',
                                  'token': code,
                                };
                                _pembukaanStep = 'success';
                              });
                              await _loadAllData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Gagal memvalidasi QR Karung.')),
                              );
                            }
                          },
                    child: _isProcessingOpen
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Validasi & Buka Pupuk di Sawah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],

        // STEP 4: SUCCESS RECEIPT
        if (_pembukaanStep == 'success' && _lastOpenSuccess != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: primaryGreen, size: 54),
                const SizedBox(height: 10),
                const Text('PUPUK RESMI DIBUKA DI SAWAH!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkEmerald)),
                const SizedBox(height: 4),
                const Text('Validasi lokasi GPS dan QR Karung sukses tercatat.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                const Divider(height: 24),
                _receiptRow('Jenis Pupuk', _lastOpenSuccess!['pupuk']),
                _receiptRow('Jumlah Pupuk', _lastOpenSuccess!['jumlah']),
                _receiptRow('Lokasi Sawah', _lastOpenSuccess!['lahan']),
                _receiptRow('Jarak Validasi GPS', _lastOpenSuccess!['jarak']),
                _receiptRow('Status Validasi', 'VALID (Radius Sesuai)'),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      setState(() {
                        _pembukaanStep = 'select';
                        _activeNav = 7; // Buka riwayat
                      });
                    },
                    child: const Text('Buka Riwayat Pembukaan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // =========================================================================
  // 8. TAB RIWAYAT PEMBUKAAN
  // =========================================================================
  Widget _buildRiwayatTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Riwayat Pembukaan Sak Pupuk (${_scans.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Text('Daftar karung pupuk bersubsidi yang telah divalidasi GPS di lahan', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 10),
        if (_scans.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('Belum ada riwayat pembukaan karung pupuk.', style: TextStyle(color: Colors.grey))),
          )
        else
          ..._scans.map((scan) => Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                        Text(scan.jenisPupuk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: Text(scan.statusValidasi, style: const TextStyle(color: primaryGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${scan.jumlahPupuk} • ${scan.namaLahan}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('${scan.tanggal} — ${scan.waktu}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  ],
                ),
              )),
      ],
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Text(badge, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Text(subtitle, style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'DISETUJUI':
      case 'DIJADWALKAN_DISTRIBUSI':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'Disetujui';
        break;
      case 'TERSALURKAN':
        bg = const Color(0xFFE0E7FF);
        text = const Color(0xFF4338CA);
        label = 'Tersalurkan';
        break;
      case 'SURVEI_LAPANGAN':
      case 'DITUGASKAN_KE_PPL':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1D4ED8);
        label = 'Survei PPL';
        break;
      case 'PERLU_PERBAIKAN_BERKAS':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        label = 'Perlu Revisi';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'Verifikasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildMiniStepper(String status) {
    int currentStep = 1;
    if (['MENUNGGU_VERIFIKASI_BERKAS', 'PERLU_PERBAIKAN_BERKAS'].contains(status)) currentStep = 2;
    if (['DITUGASKAN_KE_PPL', 'SURVEI_LAPANGAN'].contains(status)) currentStep = 3;
    if (['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI'].contains(status)) currentStep = 4;
    if (status == 'TERSALURKAN') currentStep = 5;

    return Row(
      children: List.generate(5, (index) {
        final isPassed = index < currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isPassed ? primaryGreen : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFullProgressStepper(String status) {
    int currentStep = 1;
    if (['MENUNGGU_VERIFIKASI_BERKAS', 'PERLU_PERBAIKAN_BERKAS'].contains(status)) currentStep = 2;
    if (['DITUGASKAN_KE_PPL'].contains(status)) currentStep = 3;
    if (['SURVEI_LAPANGAN'].contains(status)) currentStep = 4;
    if (['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI'].contains(status)) currentStep = 5;
    if (status == 'TERSALURKAN') currentStep = 6;

    final steps = ['Diajukan', 'Verifikasi', 'Tugas PPL', 'Survei', 'Disetujui', 'Tersalurkan'];

    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = (i + 1) <= currentStep;
        final isCurrent = (i + 1) == currentStep;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDone ? primaryGreen : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? darkEmerald : (isDone ? primaryGreen : const Color(0xFFCBD5E1)),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text('${i + 1}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  // =========================================================================
  // MAIN BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slateBg,
      appBar: AppBar(
        title: const Text('E-Pupuk Mojokerto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: darkEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllData,
            tooltip: 'Segarkan',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              color: primaryGreen,
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Banner (#064E3B)
                    _buildTopBanner(),
                    const SizedBox(height: 14),

                    // Horizontal Pill Tabs
                    _buildPillNavigation(),
                    const SizedBox(height: 16),

                    // Active Tab Content
                    if (_activeNav == 0) _buildDashboardTab(),
                    if (_activeNav == 1) _buildProfileTab(),
                    if (_activeNav == 2) _buildLandsTab(),
                    if (_activeNav == 3) _buildApplicationTab(),
                    if (_activeNav == 4) _buildStatusTab(),
                    if (_activeNav == 5) _buildKuotaTab(),
                    if (_activeNav == 6) _buildPembukaanTab(),
                    if (_activeNav == 7) _buildRiwayatTab(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
