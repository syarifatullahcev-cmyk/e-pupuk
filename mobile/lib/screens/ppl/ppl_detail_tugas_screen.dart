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
  String? _startError;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _handleStartSurvey() async {
    setState(() => _isStarting = true);
    try {
      final success = await PPLService.startSurvey(_task.id);
      if (mounted) {
        setState(() {
          _isStarting = false;
          _startError =
              success ? null : 'Server tidak mengonfirmasi pembaruan status.';
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Status tugas telah diperbarui menjadi SURVEI LAPANGAN'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PPLPetaLahanScreen(task: _task),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _startError = error.toString();
        });
      }
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
            if (_startError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Pembaruan status survei gagal: $_startError',
                style: const TextStyle(color: Color(0xFFB91C1C)),
              ),
              TextButton.icon(
                onPressed: _isStarting ? null : _handleStartSurvey,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
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
              const Icon(Icons.phone_outlined,
                  size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                _task.kontakPetani,
                style:
                    const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                _task.jadwal,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
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
              Icon(Icons.landscape_outlined,
                  size: 18, color: AppTheme.primaryGreen),
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
          _buildInfoRow(
            'Kode Bidang Lahan',
            _task.landId > 0 ? 'Lahan #${_task.landId}' : 'Belum tersedia',
          ),
          _buildInfoRow('Deskripsi Lahan', _task.lokasiLahan),
          _buildInfoRow('Alamat Lokasi', _task.alamatLahan),
          _buildInfoRow('Luas Permohonan (RDKK)',
              '${luasHa.toStringAsFixed(2)} Ha (${_task.luasLahanM2.toInt()} m²)'),
          _buildInfoRow('Komoditas Aktual', _task.komoditas),
          _buildInfoRow('Pupuk Diajukan',
              '${_task.namaPupuk} • ${_task.jumlahDiajukan.toInt()} Kg'),
          _buildInfoRow(
              'Titik Acuan Petani',
              _task.latitude == 0 && _task.longitude == 0
                  ? 'Belum tersedia'
                  : '${_task.latitude.toStringAsFixed(6)}, ${_task.longitude.toStringAsFixed(6)}'),
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
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
              Icon(Icons.alt_route_rounded,
                  size: 18, color: AppTheme.primaryGreen),
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
          _buildInfoRow('Status tugas', _task.statusLabel),
          _buildInfoRow(
            'Data survei',
            _task.hasSurvey ? 'Tersimpan' : 'Belum tersedia',
          ),
          _buildInfoRow(
            'Batas poligon',
            _task.parsedPolygonPoints.length >= 3
                ? '${_task.parsedPolygonPoints.length} titik tersimpan'
                : 'Belum tersedia',
          ),
          if (_task.rekomendasi?.isNotEmpty == true)
            _buildInfoRow('Rekomendasi', _task.rekomendasi!),
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
          const Icon(Icons.info_outline,
              color: AppTheme.primaryGreen, size: 20),
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
                  _task.catatanPenugasan?.trim().isNotEmpty == true
                      ? _task.catatanPenugasan!
                      : 'Tidak ada catatan penugasan dari Admin.',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF166534), height: 1.4),
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.satellite_alt_rounded,
                    color: Colors.white, size: 18),
            label: Text(
              _isStarting
                  ? 'Memulai Survei...'
                  : 'Buka Citra Satelit & Lokasi Lahan',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
            icon: const Icon(Icons.edit_note,
                color: AppTheme.primaryGreen, size: 20),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
