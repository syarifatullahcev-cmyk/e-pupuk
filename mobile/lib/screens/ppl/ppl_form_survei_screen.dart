import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/ppl_task_model.dart';
import '../../services/ppl_service.dart';
import '../../services/location_service.dart';
import '../../services/subsidy_service.dart';
import '../../widgets/ppl_notifications_button.dart';
import 'ppl_pengukuran_batas_screen.dart';

class PPLFormSurveiScreen extends StatefulWidget {
  final PPLTaskModel task;
  final PPLSurveyMeasurement? measurement;

  const PPLFormSurveiScreen({
    super.key,
    required this.task,
    this.measurement,
  });

  @override
  State<PPLFormSurveiScreen> createState() => _PPLFormSurveiScreenState();
}

class _PPLFormSurveiScreenState extends State<PPLFormSurveiScreen> {
  late PPLTaskModel _task;

  // Form State
  String _validitasIdentitas = 'Belum Diperiksa';
  String _verifikasiLahan = 'Belum Diperiksa';
  String? _kondisiFisik;
  String? _kondisiTanaman;
  late final TextEditingController _komoditasController;
  PPLSurveyMeasurement? _measurement;

  // GPS State
  bool _isGpsRecorded = false;
  bool _isCapturingGps = false;
  double _gpsLat = 0.0;
  double _gpsLng = 0.0;
  String _gpsAccuracy = '';

  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, XFile> _surveyPhotos = {};

  // Catatan & Rekomendasi
  final TextEditingController _catatanController = TextEditingController();
  int _rekomendasiOption = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _measurement = widget.measurement;
    _komoditasController = TextEditingController(text: _task.komoditas);
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _komoditasController.dispose();
    super.dispose();
  }

  Future<void> _captureSurveyPhoto(String slot) async {
    if (_isSaving) return;
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() => _surveyPhotos[slot] = photo);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat mengambil foto: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recordGps() async {
    setState(() => _isCapturingGps = true);
    final result = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isCapturingGps = false);

    if (result.isSuccess && result.position != null) {
      setState(() {
        _isGpsRecorded = true;
        _gpsLat = result.position!.latitude;
        _gpsLng = result.position!.longitude;
        _gpsAccuracy = result.accuracy != null
            ? '± ${result.accuracy!.toStringAsFixed(1)} m'
            : 'Diperoleh';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titik koordinat GPS berhasil direkam'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // If permission denied forever, offer to open settings
      if (result.status == LocationStatus.permissionDeniedForever) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Izin Lokasi Ditolak'),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await LocationService.openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen),
                child: const Text('Buka Pengaturan',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _measureBoundary() async {
    final measurement = await Navigator.push<PPLSurveyMeasurement>(
      context,
      MaterialPageRoute(
        builder: (context) => PPLPengukuranBatasScreen(task: _task),
      ),
    );
    if (measurement != null && mounted) {
      setState(() => _measurement = measurement);
    }
  }

  Future<void> _handleSaveSurvey() async {
    if (_isSaving) return;
    if (_validitasIdentitas == 'Belum Diperiksa' ||
        _verifikasiLahan == 'Belum Diperiksa' ||
        _kondisiFisik == null ||
        _kondisiTanaman == null ||
        _komoditasController.text.trim().isEmpty ||
        _rekomendasiOption == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua hasil pemeriksaan dan rekomendasi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_measurement == null ||
        _measurement!.polygonPoints.length < 3 ||
        _measurement!.areaM2 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukur dan validasi minimal tiga titik batas lahan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_surveyPhotos.containsKey('lahan') ||
        !_surveyPhotos.containsKey('patok')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Ambil foto kondisi lahan dan patok batas terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String rekomendasiStr = _rekomendasiOption == 1 ? 'SETUJU' : 'TOLAK';
    final uploadedPhotoUrls = <String>[];
    for (final entry in _surveyPhotos.entries) {
      final upload = await SubsidyService.uploadImage(entry.value, 'survei');
      if (upload['success'] != true) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(upload['message']?.toString() ??
                  'Gagal mengunggah foto survei.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      uploadedPhotoUrls.add(upload['url'] as String);
    }

    final started = await PPLService.startSurvey(_task.id);
    if (!started) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Status survei gagal dimulai. Periksa koneksi lalu coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await PPLService.submitSurvey(
      applicationId: _task.id,
      kondisiFisikLahan: _kondisiFisik!,
      keteranganFisikLahan:
          'Hasil verifikasi fisik: identitas $_validitasIdentitas, lahan $_verifikasiLahan',
      kondisiTanaman: _kondisiTanaman!,
      keteranganTanaman:
          'Komoditas aktual: ${_komoditasController.text.trim()}',
      luasLahanAktualM2: _measurement!.areaM2,
      catatanPpl: _catatanController.text.trim(),
      rekomendasi: rekomendasiStr,
      fotoSurveiUrls: uploadedPhotoUrls,
      polygonCoords: _measurement!.polygonCoordinates,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      final bool isSuccess = result['success'] == true;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: isSuccess ? AppTheme.primaryGreen : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isSuccess ? 'Survei Tersimpan' : 'Gagal Menyimpan',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            result['message'] ??
                (isSuccess
                    ? 'Hasil survei lapangan berhasil diserahkan.'
                    : 'Terjadi kesalahan saat menyimpan data survei.'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                if (isSuccess)
                  Navigator.pop(
                      context); // Return to previous screen only on success
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? AppTheme.primaryGreen : Colors.red,
              ),
              child: Text(isSuccess ? 'Selesai' : 'Tutup',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
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
                  'E-PUPUK KAB. MOJOKERTO',
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
          const PPLNotificationsButton(),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.darkGreen,
              child: const Text('AH',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-Header Navigasi & Mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back,
                          size: 14, color: AppTheme.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Detail Tugas Survei',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.shield_outlined,
                          size: 12, color: AppTheme.primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'Mode Pengisian Lapangan',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Judul Layar & Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Formulir Hasil Survei',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Tgl : ${DateFormat('d MMM y').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card Identitas Petani & Tugas Survei
            _buildFarmerSurveyCard(luasHa),
            const SizedBox(height: 18),

            // 1. HASIL PEMERIKSAAN LAPANGAN
            _buildSection1Pemeriksaan(),
            const SizedBox(height: 18),

            // 2. KOORDINAT & LOKASI LAPANGAN
            _buildSection2Koordinat(),
            const SizedBox(height: 18),

            // 3. DOKUMENTASI FOTO LAPANGAN
            _buildSection3Foto(),
            const SizedBox(height: 18),

            // 4. CATATAN LAPANGAN & REKOMENDASI
            _buildSection4Catatan(),
            const SizedBox(height: 22),

            // TOMBOL AKSI
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerSurveyCard(double luasHa) {
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppTheme.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _task.namaPetani,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _task.poktan,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _task.taskIdCode,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _task.desaKecamatan,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.crop_square,
                  size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Lahan #${_task.landId} — ${_task.lokasiLahan} (${luasHa.toStringAsFixed(1)} Ha / ${_task.luasLahanM2.toInt()} m²)',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Status: Sedang Dikerjakan',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PPL Wilbin II',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. HASIL PEMERIKSAAN LAPANGAN
  Widget _buildSection1Pemeriksaan() {
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
          _buildSectionHeaderNumber(1, 'Hasil Pemeriksaan Lapangan'),
          const SizedBox(height: 14),

          // Validitas Identitas
          const Text('Validitas Identitas Petani (NIK / KTP)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          _buildThreeWaySelector(
            currentValue: _validitasIdentitas,
            onChanged: (val) => setState(() => _validitasIdentitas = val),
          ),
          const SizedBox(height: 14),

          // Verifikasi Keberadaan Lahan
          const Text('Verifikasi Keberadaan Lahan',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          _buildThreeWaySelector(
            currentValue: _verifikasiLahan,
            onChanged: (val) => setState(() => _verifikasiLahan = val),
          ),
          const SizedBox(height: 14),

          // Kondisi Fisik Lahan
          const Text('Kondisi Fisik Lahan',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _kondisiFisik,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Pilih kondisi lahan',
            ),
            items: const [
              DropdownMenuItem(value: 'BAIK', child: Text('BAIK')),
              DropdownMenuItem(value: 'CUKUP', child: Text('CUKUP')),
              DropdownMenuItem(
                  value: 'TIDAK_LAYAK', child: Text('TIDAK_LAYAK')),
            ],
            onChanged: (value) => setState(() => _kondisiFisik = value),
          ),
          const SizedBox(height: 14),

          const Text('Kesesuaian Tanaman',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _kondisiTanaman,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Pilih kesesuaian tanaman',
            ),
            items: const [
              DropdownMenuItem(value: 'SESUAI', child: Text('SESUAI')),
              DropdownMenuItem(
                  value: 'TIDAK_SESUAI', child: Text('TIDAK_SESUAI')),
            ],
            onChanged: (value) => setState(() => _kondisiTanaman = value),
          ),
          const SizedBox(height: 14),
          const Text('Komoditas Aktual',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _komoditasController,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Catat komoditas yang ditemukan di lahan',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeWaySelector(
      {required String currentValue, required Function(String) onChanged}) {
    final options = [
      {'label': 'Belum Diperiksa', 'icon': Icons.horizontal_rule_rounded},
      {'label': 'Sesuai', 'icon': Icons.check_circle_outline},
      {'label': 'Tidak Sesuai', 'icon': Icons.highlight_off_rounded},
    ];

    return Row(
      children: options.map((opt) {
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = currentValue == label;

        Color bg = const Color(0xFFF1F5F9);
        Color fg = AppTheme.textSecondary;
        Color borderColor = Colors.transparent;

        if (isSelected) {
          if (label == 'Sesuai') {
            bg = const Color(0xFFE8F6EF);
            fg = AppTheme.primaryGreen;
            borderColor = AppTheme.primaryGreen.withOpacity(0.4);
          } else if (label == 'Tidak Sesuai') {
            bg = const Color(0xFFFEE2E2);
            fg = AppTheme.dangerRed;
            borderColor = AppTheme.dangerRed.withOpacity(0.4);
          } else {
            bg = const Color(0xFFE2E8F0);
            fg = AppTheme.textPrimary;
            borderColor = AppTheme.border;
          }
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => onChanged(label),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: fg),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 2. KOORDINAT & LOKASI LAPANGAN
  Widget _buildSection2Koordinat() {
    final hasFarmerCoordinates = _task.latitude != 0 || _task.longitude != 0;

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
            children: [
              _buildSectionHeaderNumber(2, 'Koordinat & Lokasi Lapangan'),
              const Text(
                'Standby Lapangan',
                style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Titik Usulan Petani Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TITIK USULAN PETANI',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                          letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Belum Terverifikasi',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasFarmerCoordinates
                      ? '${_task.latitude.toStringAsFixed(6)}, ${_task.longitude.toStringAsFixed(6)}'
                      : 'Koordinat awal belum tersedia',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  hasFarmerCoordinates
                      ? 'Koordinat awal dari petani - belum diverifikasi lapangan'
                      : 'Belum ada koordinat awal dari petani',
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Koordinat Faktual PPL
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
                  children: [
                    const Icon(Icons.gps_fixed,
                        size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    const Text(
                      'Koordinat Faktual Petugas PPL',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      _isGpsRecorded
                          ? 'Telah direkam'
                          : 'Koordinat belum direkam',
                      style: TextStyle(
                          fontSize: 10,
                          color: _isGpsRecorded
                              ? AppTheme.primaryGreen
                              : AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _isCapturingGps ? null : _recordGps,
                    icon: _isCapturingGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.my_location,
                            size: 16, color: Colors.white),
                    label: Text(
                      _isCapturingGps
                          ? 'Mencari Sinyal GPS...'
                          : 'Ambil Titik Koordinat GPS Aktual',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isGpsRecorded
                          ? '${_gpsLat.toStringAsFixed(6)}, ${_gpsLng.toStringAsFixed(6)}'
                          : '--.------, ---.------',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                    Text(
                      _isGpsRecorded ? _gpsAccuracy : 'Menunggu Sinyal GPS',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _task.poktan,
                  style:
                      const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Peta Preview Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Column(
              children: [
                const Icon(Icons.map_outlined,
                    size: 28, color: Color(0xFF60A5FA)),
                const SizedBox(height: 6),
                Text(
                  _isGpsRecorded
                      ? 'Koordinat GPS tercatat untuk referensi; poligon batas diukur terpisah.'
                      : 'Belum ada koordinat GPS dari perangkat.',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _task.poktan,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF93C5FD)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _measureBoundary,
            icon: const Icon(Icons.polyline),
            label: Text(_measurement == null
                ? 'Ukur Batas & Luas Lahan'
                : 'Ukur Ulang Batas Lahan'),
          ),
          if (_measurement != null) ...[
            const SizedBox(height: 6),
            Text(
              'Luas terukur: ${_measurement!.areaM2.toStringAsFixed(2)} m² '
              '(${_measurement!.polygonPoints.length} titik)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. DOKUMENTASI FOTO LAPANGAN
  Widget _buildSection3Foto() {
    final countTaken = _surveyPhotos.length;

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
            children: [
              _buildSectionHeaderNumber(3, 'Dokumentasi Foto Lapangan'),
              Text(
                '$countTaken/5 Terisi',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Foto 1: Lahan & Tanaman (Wajib)
          _buildPhotoBox(
            title: 'Foto Kondisi Lahan & Tanaman',
            isMandatory: true,
            isTaken: _surveyPhotos.containsKey('lahan'),
            icon: Icons.landscape_outlined,
            prompt: 'Ambil Foto Kondisi Lahan',
            subtitle: _surveyPhotos['lahan']?.name ??
                'Pastikan hamparan petak & vegetasi tampak jelas',
            onTap: () => _captureSurveyPhoto('lahan'),
          ),
          const SizedBox(height: 12),

          // Foto 2: Patok Batas (Wajib)
          _buildPhotoBox(
            title: 'Foto Patok Batas / Titik Sudut',
            isMandatory: true,
            isTaken: _surveyPhotos.containsKey('patok'),
            icon: Icons.crop_square_outlined,
            prompt: 'Ambil Foto Patok Batas',
            subtitle: _surveyPhotos['patok']?.name ??
                'Pastikan patok BPN / pembatas saluran jelas',
            onTap: () => _captureSurveyPhoto('patok'),
          ),
          const SizedBox(height: 12),

          // Foto 3: Pendukung / Petani (Opsional)
          _buildPhotoBox(
            title: 'Foto Pendukung / Petani di Lokasi',
            isMandatory: false,
            isTaken: _surveyPhotos.containsKey('pendukung'),
            icon: Icons.person_outline,
            prompt: 'Ambil Foto Tambahan',
            subtitle: _surveyPhotos['pendukung']?.name ??
                'Foto petani yang garap atau saluran irigasi',
            onTap: () => _captureSurveyPhoto('pendukung'),
          ),
          const SizedBox(height: 12),
          _buildPhotoBox(
            title: 'Foto Kondisi Tanaman',
            isMandatory: false,
            isTaken: _surveyPhotos.containsKey('tanaman'),
            icon: Icons.grass_outlined,
            prompt: 'Ambil Foto Tanaman',
            subtitle:
                _surveyPhotos['tanaman']?.name ?? 'Foto tanaman yang diperiksa',
            onTap: () => _captureSurveyPhoto('tanaman'),
          ),
          const SizedBox(height: 12),
          _buildPhotoBox(
            title: 'Foto Saluran atau Akses Lahan',
            isMandatory: false,
            isTaken: _surveyPhotos.containsKey('akses'),
            icon: Icons.water_outlined,
            prompt: 'Ambil Foto Saluran atau Akses',
            subtitle: _surveyPhotos['akses']?.name ??
                'Foto pendukung kondisi akses atau irigasi',
            onTap: () => _captureSurveyPhoto('akses'),
          ),
          const SizedBox(height: 14),

          // Info Box Patok Batas
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
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dokumentasi foto patok batas berfungsi sebagai bukti otentik visual di lapangan dan arsip validasi alokasi pupuk bersubsidi.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF1E40AF), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox({
    required String title,
    required bool isMandatory,
    required bool isTaken,
    required IconData icon,
    required String prompt,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMandatory
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMandatory ? 'Wajib' : 'Opsional',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isMandatory
                          ? const Color(0xFF1E40AF)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isTaken ? AppTheme.lightGreen : Colors.white,
                    child: Icon(
                      isTaken ? Icons.check : Icons.camera_alt_outlined,
                      color: isTaken
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTaken ? 'Foto Telah Diambil (Ketuk untuk ubah)' : prompt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTaken
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. CATATAN LAPANGAN & REKOMENDASI
  Widget _buildSection4Catatan() {
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
          _buildSectionHeaderNumber(4, 'Catatan Lapangan & Rekomendasi'),
          const SizedBox(height: 14),

          const Text(
            'Catatan Pengamatan Petugas PPL',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _catatanController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText:
                    'Catat hasil pengamatan, kendala, atau informasi tambahan...',
                hintStyle: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Rekomendasi Tindak Lanjut',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),

          // Radio 1: Tidak perlu tindak lanjut
          _buildRadioRecommendation(
            value: 1,
            title: 'Tidak perlu tindak lanjut (Lanjut Rekomendasi RDKK)',
            subtitle:
                'Lahan valid, komoditas sesuai kuota pupuk musim tanam I.',
          ),
          const SizedBox(height: 10),

          // Radio 2: Perlu tindak lanjut Admin
          _buildRadioRecommendation(
            value: 2,
            title: 'Perlu tindak lanjut Admin Dinas Pertanian',
            subtitle:
                'Terdapat anomali batas, alih fungsi lahan, atau perbedaan luas signifikan.',
          ),
        ],
      ),
    );
  }

  Widget _buildRadioRecommendation(
      {required int value, required String title, required String subtitle}) {
    final isSelected = _rekomendasiOption == value;

    return InkWell(
      onTap: () => setState(() => _rekomendasiOption = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
                    width: 2),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeaderNumber(int number, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: const Color(0xFFDBEAFE),
          child: Text(
            '$number',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSaveSurvey,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.assignment_turned_in_outlined,
                    color: Colors.white, size: 18),
            label: Text(
              _isSaving ? 'Menyimpan Hasil...' : 'Kirim Hasil Survei',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline, size: 14, color: AppTheme.primaryGreen),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Data survei dikirim ke server FastAPI dan disimpan ke database.',
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
