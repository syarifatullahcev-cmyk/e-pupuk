import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/farmer_model.dart';
import '../../models/user_model.dart';
import '../../services/ppl_service.dart';
import 'ppl_detail_petani_screen.dart';

class PPLDataPetaniScreen extends StatefulWidget {
  final UserModel user;

  const PPLDataPetaniScreen({super.key, required this.user});

  @override
  State<PPLDataPetaniScreen> createState() => _PPLDataPetaniScreenState();
}

class _PPLDataPetaniScreenState extends State<PPLDataPetaniScreen> {
  List<FarmerModel> _farmers = [];
  bool _isLoading = true;
  String _selectedDesa = 'Semua Desa';
  String _selectedStatus = 'Status Verifikasi';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _desaOptions = [
    'Semua Desa',
    'Tanjungrejo',
    'Sukamaju',
    'Sumberrejo',
    'Kebondalem',
    'Sentonorejo',
  ];

  final List<String> _statusOptions = [
    'Status Verifikasi',
    'Menunggu',
    'Dalam Proses',
    'Perlu Perbaikan',
    'Terverifikasi',
  ];

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    setState(() => _isLoading = true);
    final data = await PPLService.getFarmers(
      search: _searchController.text,
      desa: _selectedDesa,
      status: _selectedStatus,
    );
    if (mounted) {
      setState(() {
        _farmers = data;
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
          onRefresh: _loadFarmers,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 16),
                _buildTitleSection(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFiltersRow(),
                const SizedBox(height: 18),
                _buildListHeader(),
                const SizedBox(height: 12),
                _buildFarmersList(),
                const SizedBox(height: 20),
                _buildPrivacyNoticeBanner(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Top Header
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
                  'Data Petani',
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
              onPressed: () {},
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text(
                'AH',
                style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Title Section
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Data Petani',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Kelola data petani dan periksa informasi lahan.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // 3. Search Bar
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
          hintText: 'Cari nama, NIK, atau desa...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _loadFarmers();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onChanged: (val) {
          _loadFarmers();
        },
      ),
    );
  }

  // 4. Filters Row
  Widget _buildFiltersRow() {
    return Row(
      children: [
        // Dropdown Semua Desa
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDesa,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                items: _desaOptions.map((String d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(d, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _selectedDesa = newVal);
                    _loadFarmers();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Dropdown Status Verifikasi
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                items: _statusOptions.map((String s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _selectedStatus = newVal);
                    _loadFarmers();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 5. List Header
  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Petani (${_farmers.length} Binaan)',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Row(
          children: const [
            CircleAvatar(radius: 3, backgroundColor: AppTheme.primaryGreen),
            SizedBox(width: 5),
            Text(
              'Sinkron GPS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 6. Farmers List
  Widget _buildFarmersList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_farmers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: const [
            Icon(Icons.search_off, size: 40, color: AppTheme.textMuted),
            SizedBox(height: 8),
            Text(
              'Tidak ada data petani yang sesuai kriteria.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _farmers.map((farmer) => _buildFarmerCard(farmer)).toList(),
    );
  }

  Widget _buildFarmerCard(FarmerModel farmer) {
    Color avatarBg = AppTheme.lightGreen;
    Color avatarText = AppTheme.primaryGreen;
    Color badgeColor = AppTheme.warningOrange;
    Color badgeBg = AppTheme.warningBg;
    IconData badgeIcon = Icons.hourglass_top_outlined;
    String badgeText = farmer.statusVerifikasi;

    if (farmer.statusVerifikasi.toLowerCase().contains('proses')) {
      avatarBg = AppTheme.infoBg;
      avatarText = AppTheme.infoBlue;
      badgeColor = AppTheme.infoBlue;
      badgeBg = AppTheme.infoBg;
      badgeIcon = Icons.cached;
      badgeText = 'Dalam Proses';
    } else if (farmer.statusVerifikasi.toLowerCase().contains('perbaikan')) {
      avatarBg = const Color(0xFFFDE8E8);
      avatarText = const Color(0xFFE02424);
      badgeColor = AppTheme.warningOrange;
      badgeBg = AppTheme.warningBg;
      badgeIcon = Icons.warning_amber_rounded;
      badgeText = 'Perlu Perbaikan';
    } else if (farmer.statusVerifikasi.toLowerCase().contains('terverifikasi')) {
      avatarBg = AppTheme.lightGreen;
      avatarText = AppTheme.primaryGreen;
      badgeColor = AppTheme.primaryGreen;
      badgeBg = AppTheme.lightGreen;
      badgeIcon = Icons.check_circle_outline;
      badgeText = 'Terverifikasi';
    } else {
      // Default Menunggu
      badgeText = 'Menunggu';
      badgeIcon = Icons.hourglass_top_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Row 1: Avatar, Name, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  farmer.initials,
                  style: TextStyle(
                    color: avatarText,
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
                      children: [
                        Flexible(
                          child: Text(
                            farmer.nama,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          farmer.maskedNik,
                          style: const TextStyle(
                            fontSize: 12,
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
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 3),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Info Box: Alamat & Lahan
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Desa ${farmer.desa ?? "Tanjungrejo"}, Kec. ${farmer.kecamatan ?? "Mojosari"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.crop_landscape, size: 15, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Text(
                          '${farmer.jumlahLahan} Lahan (${farmer.totalLuasHa.toString().replaceAll('.', ',')} Ha total)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        farmer.poktan,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Footer Card: Tanggal & Action Lihat Detail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diperbarui: ${farmer.diperbarui}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PPLDetailPetaniScreen(farmer: farmer),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: AppTheme.primaryGreen),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Privacy Notice Banner
  Widget _buildPrivacyNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.shield_outlined, color: AppTheme.infoBlue, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data NIK disamarkan sesuai regulasi privasi data. Data dalam prototipe ini adalah sampel simulasi untuk penugasan PPL Mojokerto.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.infoBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
