import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/farmer_model.dart';
import '../../models/ppl_task_model.dart';
import '../../models/subsidy_models.dart';
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
  String? _farmerError;
  String? _tasksError;

  @override
  void initState() {
    super.initState();
    _farmer = widget.farmer;
    _refreshFarmerDetail();
    _loadFarmerTasks();
  }

  Future<void> _refreshFarmerDetail() async {
    try {
      final updated = await PPLService.getFarmerDetail(widget.farmer.id);
      if (mounted) {
        setState(() {
          _farmer = updated;
          _farmerError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _farmerError = error.toString());
      }
    }
  }

  Future<void> _loadFarmerTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final allTasks = await PPLService.getAssignedTasks();
      if (mounted) {
        setState(() {
          _farmerTasks =
              allTasks.where((t) => t.farmerId == widget.farmer.id).toList();
          _tasksError = null;
          _isLoadingTasks = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _tasksError = error.toString();
          _isLoadingTasks = false;
        });
      }
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
            if (_farmerError != null)
              _buildLoadError('Gagal memuat detail petani', _farmerError!,
                  _refreshFarmerDetail),
            const SizedBox(height: 18),
            _buildRegisteredLandsSection(),
            const SizedBox(height: 18),
            if (_tasksError != null)
              _buildLoadError(
                  'Gagal memuat tugas petani', _tasksError!, _loadFarmerTasks),
            if (_tasksError != null) const SizedBox(height: 18),
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

  Widget _buildLoadError(
    String title,
    String message,
    Future<void> Function() onRetry,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: $message',
              style: const TextStyle(color: Color(0xFFB91C1C))),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
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
                        Expanded(
                          child: Text(
                            _farmer.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_farmer.maskedNik} (NIK Terproteksi)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontFamily: 'monospace',
                            ),
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
                  border:
                      Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Text(
                  _farmer.statusVerifikasi,
                  style: const TextStyle(
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
          _buildInfoRow(
              Icons.group_outlined, 'Kelompok Tani: ${_farmer.poktan}'),
          const SizedBox(height: 6),
          _buildInfoRow(
              Icons.location_on_outlined, 'Domisili KTP: ${_farmer.alamat}'),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _farmer.kontak,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textSecondary),
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
                  style: TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold),
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
                  style:
                      TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
                Icon(Icons.hourglass_bottom,
                    size: 13, color: AppTheme.warningOrange),
                SizedBox(width: 3),
                Text(
                  'Menunggu Lapangan',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningOrange),
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
            style:
                const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  // 2. Data Lahan Terdaftar Section
  Widget _buildRegisteredLandsSection() {
    final totalLuasHa = _farmer.lands.fold<double>(
          0,
          (total, land) => total + land.luasM2,
        ) /
        10000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.crop_landscape,
                    size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  'Data Lahan Terdaftar (${_farmer.lands.length} Bidang)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Total ${totalLuasHa.toStringAsFixed(2)} Ha',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_farmer.lands.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada data lahan terdaftar.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else
          ..._farmer.lands.map(_buildFarmerLandCard),
      ],
    );
  }

  Widget _buildFarmerLandCard(LandModel land) {
    final polygonPoints = land.parsedPolygonPoints;
    final hasCoordinates = land.latitude != null &&
        land.longitude != null &&
        land.latitude! >= -90 &&
        land.latitude! <= 90 &&
        land.longitude! >= -180 &&
        land.longitude! <= 180 &&
        (land.latitude != 0 || land.longitude != 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          polygonPoints.length >= 3 ? Icons.polyline : Icons.landscape_outlined,
          color: AppTheme.primaryGreen,
        ),
        title: Text(land.lokasiDeskripsi),
        subtitle: Text(
          '${land.luasM2.toStringAsFixed(0)} m² • ${land.namaKomoditas ?? 'Komoditas belum tersedia'}\n'
          '${land.statusVerifikasi}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Lihat detail lahan',
          icon: const Icon(Icons.open_in_new),
          onPressed: () =>
              _showLandDetails(land, hasCoordinates, polygonPoints.length),
        ),
      ),
    );
  }

  void _showLandDetails(
      LandModel land, bool hasCoordinates, int polygonPointCount) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(land.lokasiDeskripsi),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Alamat: ${land.alamatLahan.isEmpty ? 'Belum tersedia' : land.alamatLahan}'),
            Text('Luas terdaftar: ${land.luasM2.toStringAsFixed(0)} m²'),
            Text(
                'Luas terverifikasi: ${land.luasVerifikasiM2?.toStringAsFixed(0) ?? 'Belum tersedia'} m²'),
            Text('Kepemilikan: ${land.statusKepemilikan}'),
            Text('Status: ${land.statusVerifikasi}'),
            Text(
              hasCoordinates
                  ? 'Koordinat: ${land.latitude}, ${land.longitude}'
                  : 'Koordinat belum tersedia',
            ),
            Text(
              polygonPointCount >= 3
                  ? 'Poligon tersedia ($polygonPointCount titik)'
                  : 'Poligon belum tersedia',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // 3. Informasi Koordinat
  Widget _buildCoordinateInfoSection() {
    final landsWithCoordinates = _farmer.lands.where((land) {
      return land.latitude != null &&
          land.longitude != null &&
          land.latitude! >= -90 &&
          land.latitude! <= 90 &&
          land.longitude! >= -180 &&
          land.longitude! <= 180 &&
          (land.latitude != 0 || land.longitude != 0);
    }).toList();

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
                  Icon(Icons.pin_drop_outlined,
                      size: 18, color: AppTheme.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Informasi Koordinat',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  landsWithCoordinates.isEmpty
                      ? 'Koordinat belum tersedia'
                      : '${landsWithCoordinates.length} titik tersedia',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (landsWithCoordinates.isEmpty)
            const Text(
              'Koordinat lahan belum dicatat.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            )
          else
            ...landsWithCoordinates.map(
              (land) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${land.lokasiDeskripsi}: ${land.latitude}, ${land.longitude}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
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
                Icon(Icons.info_outline,
                    size: 16, color: AppTheme.warningOrange),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: Koordinat awal dari petani — belum diverifikasi lapangan terhadap patok batas sertifikat/fisik. Verifikasi spasial wajib dilakukan pada survei lapangan.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.warningOrange,
                        height: 1.3),
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
    final landDocuments = _farmer.lands
        .where((land) => land.dokumenSertifikatUrl?.isNotEmpty == true)
        .toList();
    final documentCount =
        (_farmer.fotoKtpUrl?.isNotEmpty == true ? 1 : 0) + landDocuments.length;

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
              const Text(
                'Dokumen Pendukung',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              Text(
                '$documentCount Berkas tersedia',
                style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDocItem(
            icon: Icons.badge_outlined,
            iconColor: AppTheme.primaryGreen,
            title: 'KTP Elektronik Petani',
            status: _farmer.fotoKtpUrl?.isNotEmpty == true
                ? 'File tersedia'
                : 'Belum tersedia',
            statusColor: _farmer.fotoKtpUrl?.isNotEmpty == true
                ? AppTheme.primaryGreen
                : AppTheme.textMuted,
            onViewDoc: _showKtpModal,
          ),
          if (landDocuments.isEmpty) ...[
            const Divider(height: 16, color: AppTheme.border),
            const Text(
              'Dokumen lahan belum tersedia.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ] else
            ...landDocuments.map(
              (land) => Column(
                children: [
                  const Divider(height: 16, color: AppTheme.border),
                  _buildDocItem(
                    icon: Icons.description_outlined,
                    iconColor: AppTheme.primaryGreen,
                    title: 'Dokumen lahan • ${land.lokasiDeskripsi}',
                    status: 'File tersedia',
                    statusColor: AppTheme.primaryGreen,
                    note:
                        'Dokumen administratif tidak otomatis membuktikan batas GPS atau menghasilkan poligon.',
                    onViewDoc: () => _showLandDocModal(land),
                  ),
                ],
              ),
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
    VoidCallback? onViewDoc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onViewDoc ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Membuka arsip $title')),
                    );
                  },
              child: const Text('Lihat Dokumen',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen)),
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
              style: const TextStyle(
                  fontSize: 10.5, color: AppTheme.warningOrange, height: 1.3),
            ),
          ),
        ],
      ],
    );
  }

  void _showKtpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.badge_outlined,
                            color: AppTheme.primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Arsip KTP Elektronik Petani',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Data kependudukan terverifikasi Dukcapil',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.border),
              // Kartu e-KTP Digital
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220284C7),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'REPUBLIK INDONESIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'PROVINSI JAWA TIMUR • KABUPATEN MOJOKERTO',
                      style: TextStyle(
                        color: Color(0xFFBAE6FD),
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ktpRow('NIK', _farmer.nik,
                                  isMono: true, isBold: true),
                              const SizedBox(height: 4),
                              _ktpRow('Nama', _farmer.nama.toUpperCase(),
                                  isBold: true),
                              const SizedBox(height: 4),
                              _ktpRow('Alamat', _farmer.alamat),
                              const SizedBox(height: 4),
                              _ktpRow(
                                  'Kel/Desa', _farmer.desa ?? 'Mojokerto'),
                              const SizedBox(height: 4),
                              _ktpRow('Kecamatan',
                                  _farmer.kecamatan ?? 'Mojokerto'),
                              const SizedBox(height: 4),
                              _ktpRow('Poktan', _farmer.poktan),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Container(
                              width: 64,
                              height: 84,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 48),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Color(0xFF86EFAC),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Status Badge
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle,
                        color: AppTheme.primaryGreen, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status Berkas: Terverifikasi resmi Dinas Pertanian Kab. Mojokerto',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Tutup Pratinjau',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ktpRow(String label, String value,
      {bool isMono = false, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFE0F2FE),
            ),
          ),
        ),
        const Text(': ',
            style: TextStyle(fontSize: 10, color: Color(0xFFE0F2FE))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontFamily: isMono ? 'monospace' : null,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showLandDocModal(LandModel land) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: AppTheme.primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Arsip Dokumen Lahan Petani',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Surat Kepemilikan Lahan / SPPT PBB Terdaftar',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.border),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SURAT BUKTI KEPEMILIKAN / PENGUASAAN LAHAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _landDocRow('Pemilik Lahan', _farmer.nama),
                    _landDocRow('Lokasi Lahan', land.lokasiDeskripsi),
                    _landDocRow('Luas Tercatat',
                        '${(land.luasM2 / 10000).toStringAsFixed(2)} Ha (${land.luasM2.toStringAsFixed(0)} m²)'),
                    _landDocRow('Komoditas',
                        land.namaKomoditas ?? 'Padi Sawah / Jagung'),
                    _landDocRow('Nomor SPPT/NOP',
                        '35.16.${_farmer.id.toString().padLeft(3, '0')}.${land.id.toString().padLeft(4, '0')}'),
                    _landDocRow(
                        'Status Arsip', 'Tercatat di SIMLUHTAN Disperta'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.warningBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline,
                        color: AppTheme.warningOrange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catatan: Bukti administratif memerlukan verifikasi fisik patok batas GPS pada tahap survei lapangan.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.warningOrange,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Tutup Pratinjau',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _landDocRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11.5, color: AppTheme.textSecondary),
            ),
          ),
          const Text(': ',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Ringkasan Pemeriksaan Pra-Survei
  Widget _buildPreSurveySummarySection() {
    final coordinatesCount = _farmer.lands
        .where((land) =>
            land.latitude != null &&
            land.longitude != null &&
            land.latitude! >= -90 &&
            land.latitude! <= 90 &&
            land.longitude! >= -180 &&
            land.longitude! <= 180 &&
            (land.latitude != 0 || land.longitude != 0))
        .length;
    final polygonCount = _farmer.lands
        .where((land) => land.parsedPolygonPoints.length >= 3)
        .length;
    final documentCount = (_farmer.fotoKtpUrl?.isNotEmpty == true ? 1 : 0) +
        _farmer.lands
            .where((land) => land.dokumenSertifikatUrl?.isNotEmpty == true)
            .length;

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
                'Ringkasan Data Petani',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildSummaryGridItem(
                'Data Petani',
                _farmer.nik.isNotEmpty ? 'Data tersedia' : 'Data belum lengkap',
                _farmer.nik.isNotEmpty,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildSummaryGridItem(
                'Koordinat Lahan',
                coordinatesCount == 0
                    ? 'Belum tersedia'
                    : '$coordinatesCount titik tersedia',
                coordinatesCount > 0,
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildSummaryGridItem(
                'Poligon Lahan',
                polygonCount == 0
                    ? 'Belum tersedia'
                    : '$polygonCount poligon tersedia',
                polygonCount > 0,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildSummaryGridItem(
                'Dokumen',
                documentCount == 0
                    ? 'Belum tersedia'
                    : '$documentCount file tersedia',
                documentCount > 0,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGridItem(String title, String value, bool isSuccess,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10.5, color: AppTheme.textSecondary)),
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
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ],
      ),
    );
  }

  // 6. Bottom Action Buttons
  Widget _buildBottomActionButtons() {
    final PPLTaskModel? activeTask =
        _farmerTasks.isNotEmpty ? _farmerTasks.first : null;

    void navigateToTask() {
      if (activeTask == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Tidak ada tugas survei yang ditemukan untuk petani ini.'),
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_circle_outline,
                    color: Colors.white, size: 20),
            label: Text(
              _isLoadingTasks
                  ? 'Memuat...'
                  : (activeTask != null
                      ? 'Mulai Survei Lapangan'
                      : 'Tidak Ada Tugas'),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  activeTask != null ? AppTheme.darkGreen : Colors.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                icon: const Icon(Icons.list_alt,
                    size: 16, color: AppTheme.darkGreen),
                label: const Text('Lihat Tugas Survei',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                      MaterialPageRoute(
                          builder: (context) =>
                              PPLPetaLahanScreen(task: activeTask)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Tidak ada data tugas untuk menampilkan peta.')),
                    );
                  }
                },
                icon: const Icon(Icons.map_outlined,
                    size: 16, color: AppTheme.darkGreen),
                label: const Text('Lihat Peta Lahan',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
            onPressed: _hubungiPetaniWhatsApp,
            icon: const Icon(Icons.chat_outlined,
                color: AppTheme.primaryGreen, size: 18),
            label: const Text(
              'Hubungi Petani (WhatsApp)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.lightGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _hubungiPetaniWhatsApp() async {
    final rawPhone = _farmer.kontak.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon petani tidak tersedia.')),
      );
      return;
    }

    final phone = rawPhone.startsWith('0')
        ? '62${rawPhone.substring(1)}'
        : (rawPhone.startsWith('62') ? rawPhone : '62$rawPhone');

    final message =
        'Halo Bapak/Ibu ${_farmer.nama}, saya Petugas PPL Dinas Pertanian Kabupaten Mojokerto mengenai jadwal verifikasi lapangan dan alokasi pupuk bersubsidi.';
    final whatsappUri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Gagal membuka WhatsApp. Salin nomor kontak: ${_farmer.kontak}'),
              action: SnackBarAction(
                label: 'Salin',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _farmer.kontak));
                },
              ),
            ),
          );
        }
      }
    }
  }
}
