import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../auth/login_screen.dart';
import '../auth/ppl_login_screen.dart';
import '../auth/register_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _portalKey = GlobalKey();
  final GlobalKey _keunggulanKey = GlobalKey();
  final GlobalKey _alurKey = GlobalKey();
  final GlobalKey _kontakKey = GlobalKey();

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showAdminInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings, color: Color(0xFF0F172A), size: 28),
            SizedBox(width: 10),
            Text(
              'Portal Admin Dinas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Portal Admin Verifikator Dinas Pertanian dikhususkan untuk penggunaan melalui perangkat komputer / Web Browser (Desktop View) demi kemudahan audit berkas KTP, SPPT, dan validasi kuota se-Kabupaten.\n\nSilakan akses melalui portal web resmi:\nhttp://localhost:5173/login/admin',
          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            _buildPortalSection(),
            _buildKeunggulanSection(),
            _buildAlurSection(),
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. NAVIGATION APP BAR
  // ==========================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      toolbarHeight: 68,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'E-PUPUK',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Kabupaten Mojokerto',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Tombol Masuk
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: const Text(
            'Masuk',
            style: TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        // Tombol Daftar Petani
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Daftar',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Popup Menu untuk Navigasi Cepat
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF334155)),
          onSelected: (val) {
            if (val == 'portal') _scrollToKey(_portalKey);
            if (val == 'keunggulan') _scrollToKey(_keunggulanKey);
            if (val == 'alur') _scrollToKey(_alurKey);
            if (val == 'kontak') _scrollToKey(_kontakKey);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'portal', child: Text('Pilihan Portal')),
            const PopupMenuItem(value: 'keunggulan', child: Text('Keunggulan Sistem')),
            const PopupMenuItem(value: 'alur', child: Text('Alur Pengajuan')),
            const PopupMenuItem(value: 'kontak', child: Text('Kontak & Bantuan')),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. HERO SECTION
  // ==========================================
  Widget _buildHeroSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Resmi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.primaryGreen),
                SizedBox(width: 6),
                Text(
                  'Portal Resmi Alokasi Pupuk Bersubsidi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Headline Utama
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.25,
                letterSpacing: -0.6,
              ),
              children: [
                TextSpan(text: 'Penyaluran Pupuk Bersubsidi di Mojokerto dengan '),
                TextSpan(
                  text: 'Mudah',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
                TextSpan(text: ', '),
                TextSpan(
                  text: 'Transparan',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
                TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Tepat Sasaran',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Deskripsi
          const Text(
            'Platform pelayanan digital bagi kelompok tani dan petani di seluruh Kabupaten Mojokerto untuk pengajuan alokasi kuota pupuk, verifikasi lapangan PPL, serta pengambilan pupuk menggunakan kode QR resmi.',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol CTA
          Row(
            children: [
              Expanded(
                flex: 6,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'Minta Subsidi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: OutlinedButton(
                  onPressed: () => _scrollToKey(_portalKey),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Pilih Portal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Hero Image Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/hero-gambar-landing-page.jpg',
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: const Color(0xFFE2E8F0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.agriculture_rounded, size: 48, color: AppTheme.primaryGreen),
                          SizedBox(height: 8),
                          Text(
                            'Smart Farming Mojokerto',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. PILIH PORTAL SECTION
  // ==========================================
  Widget _buildPortalSection() {
    return Container(
      key: _portalKey,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'AKSES LAYANAN TERPADU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih Portal Sesuai Peran Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistem terintegrasi untuk petani, tim penyuluh lapangan (PPL), serta admin verifikator dinas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Card 1: Portal Petani
          _buildRoleCard(
            isPopular: true,
            icon: Icons.person_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: AppTheme.primaryGreen,
            title: 'Portal Petani',
            description:
                'Pengajuan kuota alokasi pupuk bersubsidi, cek status verifikasi lahan, dan unduh QR Code penebusan pupuk di kios rekanan.',
            features: [
              'Pengajuan alokasi musim tanam (MT I, II, III)',
              'Generate E-Kupon & QR Code Tebus',
              'Tracking status survei PPL berkala',
            ],
            btnText: 'Masuk Portal Petani',
            btnColor: AppTheme.primaryGreen,
            btnIcon: Icons.arrow_forward_rounded,
            onBtnPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            secondaryAction: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Belum punya akun? Daftar Sekarang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Card 2: Portal Petugas PPL
          _buildRoleCard(
            isPopular: false,
            icon: Icons.assignment_ind_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            title: 'Portal Petugas PPL',
            description:
                'Penerimaan tugas survei sawah fisik, verifikasi komoditas vegetasi, geotagging koordinat batas lahan, dan berita acara digital.',
            features: [
              'Input GPS Poligon & foto lapangan langsung',
              'Verifikasi kecocokan jenis tanaman pangan',
              'Tanda tangan Berita Acara Lapangan Digital',
            ],
            btnText: 'Masuk Portal PPL',
            btnColor: const Color(0xFF2563EB),
            btnIcon: Icons.arrow_forward_rounded,
            onBtnPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PPLLoginScreen()),
              );
            },
          ),
          const SizedBox(height: 18),

          // Card 3: Portal Admin Dinas
          _buildRoleCard(
            isPopular: false,
            icon: Icons.admin_panel_settings_rounded,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF0F172A),
            title: 'Portal Admin Dinas',
            description:
                'Verifikasi dokumen KTP & bukti lahan, penugasan survei ke PPL, persetujuan kuota pupuk, dan pemantauan stok se-Kabupaten.',
            features: [
              'Validasi NIK Dukcapil & SPPT Lahan',
              'Disposisi penugasan PPL per desa',
              'Dashboard analitik dan audit serapan kuota',
            ],
            btnText: 'Informasi Portal Admin',
            btnColor: const Color(0xFF0F172A),
            btnIcon: Icons.open_in_browser_rounded,
            onBtnPressed: _showAdminInfoDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required bool isPopular,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> features,
    required String btnText,
    required Color btnColor,
    required IconData btnIcon,
    required VoidCallback onBtnPressed,
    Widget? secondaryAction,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPopular ? AppTheme.primaryGreen.withOpacity(0.35) : const Color(0xFFE2E8F0),
              width: isPopular ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ...features.map((feat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feat,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onBtnPressed,
                icon: Icon(btnIcon, size: 16),
                label: Text(
                  btnText,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (secondaryAction != null) secondaryAction,
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'PALING POPULER',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // 4. KEUNGGULAN SECTION
  // ==========================================
  Widget _buildKeunggulanSection() {
    return Container(
      key: _keunggulanKey,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'KEUNGGULAN SISTEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mengapa Menggunakan E-PUPUK?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mencegah penyalahgunaan subsidi pupuk melalui digitalisasi data terintegrasi dan transparan dari hulu ke hilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildFeatureCard(
            icon: Icons.fingerprint_rounded,
            title: 'Validasi NIK & SPPT',
            description:
                'Terhubung langsung dengan server kependudukan Dukcapil dan data blok lahan untuk memastikan petani pemilik dan penggarap valid.',
          ),
          const SizedBox(height: 14),

          _buildFeatureCard(
            icon: Icons.location_on_rounded,
            title: 'Geotagging GPS Poligon',
            description:
                'Petugas PPL memetakan batas koordinat fisik sawah langsung dari lapangan, meniadakan risiko klaim lahan fiktif atau ganda.',
          ),
          const SizedBox(height: 14),

          _buildFeatureCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'QR Code Anti-Duplikasi',
            description:
                'Pengambilan pupuk di kios pengecer resmi menggunakan token QR dinamis terenkripsi yang langsung hangus setelah ditransaksikan.',
          ),
          const SizedBox(height: 14),

          _buildFeatureCard(
            icon: Icons.support_agent_rounded,
            title: 'Layanan Aduan Cepat',
            description:
                'Saluran pengaduan langsung melalui WhatsApp Resmi Disperta dan posko pendampingan Poktan jika terjadi kendala pada penebusan.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. ALUR PENGAJUAN SECTION
  // ==========================================
  Widget _buildAlurSection() {
    return Container(
      key: _alurKey,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'ALUR PENGAJUAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '4 Langkah Mudah Pengajuan Alokasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tata cara ringkas dan teratur mulai dari pendaftaran hingga membawa pulang pupuk subsidi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildStepCard(
            stepNumber: '01',
            title: 'Daftar Akun Petani',
            description:
                'Isi data diri dengan 16-digit NIK e-KTP, nama lengkap, nomor HP aktif, dan pilih Kelompok Tani (Poktan) di desa Anda.',
            tag: 'Waktu proses: 5 Menit',
          ),
          const SizedBox(height: 14),

          _buildStepCard(
            stepNumber: '02',
            title: 'Ajukan Data Lahan',
            description:
                'Pilih jenis komoditas tanam (Padi/Jagung/Kedelai), kebutuhan jenis pupuk (Urea/NPK Phonska), dan unggah bukti kepemilikan/sewa.',
            tag: 'Integrasi e-RDKK',
          ),
          const SizedBox(height: 14),

          _buildStepCard(
            stepNumber: '03',
            title: 'Survei Lapangan PPL',
            description:
                'Petugas PPL setempat melakukan peninjauan fisik sawah, geotagging koordinat poligon, serta menandatangani berita acara verifikasi.',
            tag: 'Verifikasi 1x24 Jam',
          ),
          const SizedBox(height: 14),

          _buildStepCard(
            stepNumber: '04',
            title: 'Penebusan di Kios',
            description:
                'Tunjukkan QR Code resmi atau sebutkan NIK di kios resmi rekanan di kecamatan Anda. Bayar sesuai HET resmi pemerintah.',
            tag: 'Harga Eceran Tertinggi (HET)',
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. FOOTER SECTION
  // ==========================================
  Widget _buildFooterSection() {
    return Container(
      key: _kontakKey,
      color: const Color(0xFF020617),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Nama
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'E-PUPUK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Kabupaten Mojokerto',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Inovasi tata kelola subsidi pupuk digital Dinas Pertanian dan Ketahanan Pangan Kabupaten Mojokerto demi mewujudkan kedaulatan pangan daerah yang mandiri dan berdaya saing.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildFooterTag('SPBE Terverifikasi'),
              _buildFooterTag('Satu Data Pertanian'),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 20),

          // Kantor Pelayanan
          const Text(
            'KANTOR PELAYANAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dinas Pertanian dan Ketahanan Pangan\nKabupaten Mojokerto\nJl. RA Basuni No. 12, Sooko\nKabupaten Mojokerto, Jawa Timur 61361\nJam Layanan: Senin - Jumat, 07.30 - 16.00 WIB',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.6),
          ),
          const SizedBox(height: 20),

          // Kontak Resmi
          const Text(
            'KONTAK RESMI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          _buildContactRow(Icons.phone_rounded, '(0321) 321890'),
          const SizedBox(height: 6),
          _buildContactRow(Icons.email_outlined, 'distan@mojokertokab.go.id'),
          const SizedBox(height: 6),
          _buildContactRow(Icons.chat_bubble_outline_rounded, 'WhatsApp: 0812-3456-7890'),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 16),

          // Copyright
          Center(
            child: Text(
              '© 2026 Pemerintah Kabupaten Mojokerto.\nSeluruh Hak Cipta Dilindungi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF34D399)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

