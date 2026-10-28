import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/ppl_task_model.dart';
import '../../services/ppl_service.dart';
import 'ppl_form_survei_screen.dart';
import 'ppl_peta_lahan_screen.dart';

class PPLDetailTugasScreen extends StatefulWidget {
  final PPLTaskModel task;

  const PPLDetailTugasScreen({super.key, required this.task});

  @override
  State<PPLDetailTugasScreen> createState() => _PPLDetailTugasScreenState();
}

class _PPLDetailTugasScreenState extends State<PPLDetailTugasScreen> {
  late PPLTaskModel _task;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _handleStartSurvey() async {
    setState(() => _isStarting = true);
    final success = await PPLService.startSurvey(_task.id);
    if (mounted) {
      setState(() => _isStarting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status tugas telah diperbarui menjadi SURVEI LAPANGAN'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PPLPetaLahanScreen(task: _task),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Tugas Survei',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              _task.taskIdCode,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _task.statusLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Petani & Poktan
            _buildFarmerInfoCard(),
            const SizedBox(height: 16),

            // Card Detail Bidang Lahan & Kuota Pupuk
            _buildLandDetailCard(luasHa),
            const SizedBox(height: 16),

            // Timeline Progres Verifikasi Lapangan
            _buildSurveyTimelineCard(),
            const SizedBox(height: 16),

            // Catatan Penugasan dari Admin Dinas
            _buildAdminNoteCard(),
            const SizedBox(height: 24),

            // Tombol Aksi Utama
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerInfoCard() {
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
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.lightGreen,
                child: Text(
                  _task.initials,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _task.namaPetani,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIK: ${_task.maskedNik}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _task.poktan,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                _task.kontakPetani,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                _task.jadwal,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandDetailCard(double luasHa) {
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
            children: const [
              Icon(Icons.landscape_outlined, size: 18, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text(
                'Data Bidang Lahan & Permohonan Pupuk',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Kode Bidang Lahan', 'PLN-001 (Blok Kebondalem)'),
          _buildInfoRow('Deskripsi Lahan', _task.lokasiLahan),
          _buildInfoRow('Alamat Lokasi', _task.alamatLahan),
          _buildInfoRow('Luas Permohonan (RDKK)', '${luasHa.toStringAsFixed(2)} Ha (${_task.luasLahanM2.toInt()} m²)'),
          _buildInfoRow('Komoditas Aktual', _task.komoditas),
          _buildInfoRow('Pupuk Diajukan', '${_task.namaPupuk} • ${_task.jumlahDiajukan.toInt()} Kg'),
          _buildInfoRow('Titik Acuan Petani', '${_task.latitude.toStringAsFixed(6)}, ${_task.longitude.toStringAsFixed(6)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyTimelineCard() {
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
            children: const [
              Icon(Icons.alt_route_rounded, size: 18, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text(
                'Tahapan Survei Lapangan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepItem(1, 'Verifikasi Berkas Administrasi', 'Disetujui Admin Dinas', true),
          _buildStepItem(2, 'Disposisi Petugas PPL Wilbin', 'Diterima oleh PPL Lapangan', true),
          _buildStepItem(3, 'Kunjungan Fisik & Validasi Petani', 'Pemeriksaan KTP & keberadaan petak', true),
          _buildStepItem(4, 'Citra Satelit & Plotting Poligon GIS', 'Tahap 4: Pengukuran batas tapak sawah', false, isCurrent: true),
          _buildStepItem(5, 'Sinkronisasi & Rekomendasi RDKK', 'Penerbitan surat rekomendasi alokasi pupuk', false),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title, String subtitle, bool isDone, {bool isCurrent = false}) {
    Color circleColor = const Color(0xFFE2E8F0);
    Color textColor = AppTheme.textMuted;
    Widget icon = Text('$step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor));

    if (isDone) {
      circleColor = AppTheme.primaryGreen;
      icon = const Icon(Icons.check, size: 14, color: Colors.white);
      textColor = AppTheme.textPrimary;
    } else if (isCurrent) {
      circleColor = AppTheme.primaryGreen;
      icon = Text('$step', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white));
      textColor = AppTheme.primaryGreen;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: circleColor,
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? AppTheme.primaryGreen : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNoteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instruksi Dinas Pertanian:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _task.catatanPenugasan ??
                      'Mohon pastikan patok batas sawah sisi saluran irigasi dicek langsung dengan pemilik petak berbatasan. Catat koordinat poligon minimal 4 titik batas tertutup WGS84.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.4),
                ),
              ],
            ),
          ),
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
            onPressed: _isStarting ? null : _handleStartSurvey,
            icon: _isStarting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.satellite_alt_rounded, color: Colors.white, size: 18),
            label: Text(
              _isStarting ? 'Memulai Survei...' : 'Buka Citra Satelit & Lokasi Lahan',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PPLFormSurveiScreen(task: _task),
                ),
              );
            },
            icon: const Icon(Icons.edit_note, color: AppTheme.primaryGreen, size: 20),
            label: const Text(
              'Formulir Hasil Survei Fisik',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
