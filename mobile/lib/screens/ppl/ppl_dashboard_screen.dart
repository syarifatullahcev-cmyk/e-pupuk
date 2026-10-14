import 'package:flutter/material.dart';
import '../../models/ppl_task_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/ppl_service.dart';
import '../auth/login_screen.dart';
import 'satellite_measure_screen.dart';

class PPLDashboardScreen extends StatefulWidget {
  final UserModel user;

  const PPLDashboardScreen({super.key, required this.user});

  @override
  State<PPLDashboardScreen> createState() => _PPLDashboardScreenState();
}

class _PPLDashboardScreenState extends State<PPLDashboardScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryGreen = Color(0xFF16A34A);

  List<PPLTaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await PPLService.getAssignedTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari portal PPL?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  // Buka Modal Form Survei Fisik + Citra Satelit
  void _openSurveyForm(PPLTaskModel task) {
    final luasController = TextEditingController(text: task.luasLahanM2 > 0 ? task.luasLahanM2.toInt().toString() : '');
    final keteranganLahanController = TextEditingController(text: 'Saluran irigasi aktif dan pematang sawah rapi.');
    final keteranganTanamanController = TextEditingController(text: 'Sesuai komoditas ${task.komoditas}.');
    final catatanPplController = TextEditingController(text: 'Lahan memenuhi syarat kelayakan fisik untuk subsidi pupuk.');

    String kondisiLahan = 'BAIK';
    String kondisiTanaman = 'SESUAI';
    String rekomendasi = 'SETUJU';
    bool isMeasuredWithSatellite = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header Sheet
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Survei Lapangan PPL',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Pengajuan #${task.id} • ${task.namaPetani}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tombol Bintang: Ukur dari Citra Satelit
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.satellite_alt_rounded, color: Color(0xFF4ADE80), size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'Pengukuran Citra Satelit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Buka peta satelit resolusi tinggi untuk memetakan poligon sudut pematang sawah dan menghitung luas aktual secara otomatis.',
                                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.3),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.crop_free_rounded, color: Colors.white, size: 18),
                                  label: const Text(
                                    'Buka Peta Satelit & Ukur Sawah',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () async {
                                    final measuredArea = await Navigator.push<double>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SatelliteMeasureScreen(
                                          initialLat: task.latitude,
                                          initialLng: task.longitude,
                                          namaLahan: '${task.lokasiLahan} (${task.namaPetani})',
                                        ),
                                      ),
                                    );

                                    if (measuredArea != null && measuredArea > 0) {
                                      setModalState(() {
                                        luasController.text = measuredArea.toStringAsFixed(1);
                                        isMeasuredWithSatellite = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                              if (isMeasuredWithSatellite) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14532D),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Terukur Satelit: ${luasController.text} m²',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Input Luas Lahan Aktual (m²)
                        const Text(
                          'Luas Lahan Aktual Lapangan (m²)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: luasController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            suffixText: 'm²',
                            prefixIcon: const Icon(Icons.square_foot, color: primaryGreen),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Kondisi Fisik Lahan
                        const Text(
                          'Kondisi Fisik Lahan',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: kondisiLahan,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'BAIK', child: Text('BAIK - Irigasi & Pematang Normal')),
                            DropdownMenuItem(value: 'SEDANG', child: Text('SEDANG - Cukup Layak')),
                            DropdownMenuItem(value: 'BURUK', child: Text('BURUK - Kering / Banjir')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => kondisiLahan = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Kondisi Tanaman
                        const Text(
                          'Kesesuaian Komoditas Tanaman',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: kondisiTanaman,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'SESUAI', child: Text('SESUAI - Tanaman Sesuai Data Poktan')),
                            DropdownMenuItem(value: 'TIDAK_SESUAI', child: Text('TIDAK SESUAI - Komoditas Berbeda')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => kondisiTanaman = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Catatan PPL
                        const Text(
                          'Catatan Lapangan Petugas PPL',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: catatanPplController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Lahan siap tanam, irigasi lancar...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rekomendasi PPL
                        const Text(
                          'Rekomendasi Petugas PPL ke Admin Dinas',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: rekomendasi,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'SETUJU', child: Text('SETUJU - Rekomendasikan Alokasi Penuh')),
                            DropdownMenuItem(value: 'PERBAIKAN', child: Text('PERBAIKAN - Butuh Revisi Berkas')),
                            DropdownMenuItem(value: 'TOLAK', child: Text('TOLAK - Tidak Memenuhi Syarat')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => rekomendasi = val);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tombol Submit Laporan
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final luas = double.tryParse(luasController.text) ?? task.luasLahanM2;
                              final res = await PPLService.submitSurvey(
                                applicationId: task.id,
                                kondisiFisikLahan: kondisiLahan,
                                keteranganFisikLahan: keteranganLahanController.text,
                                kondisiTanaman: kondisiTanaman,
                                keteranganTanaman: keteranganTanamanController.text,
                                luasLahanAktualM2: luas,
                                catatanPpl: catatanPplController.text,
                                rekomendasi: rekomendasi,
                              );

                              if (!mounted) return;
                              Navigator.pop(context); // Tutup modal

                              if (res['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: primaryGreen,
                                    content: Text('✅ ${res['message']}'),
                                  ),
                                );
                                _loadTasks();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('❌ ${res['message']}'),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Serahkan Hasil Survei ke Admin Dinas',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'SURVEI_LAPANGAN':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1D4ED8);
        label = 'Sedang Disurvei';
        break;
      case 'MENUNGGU_PERSETUJUAN_AKHIR':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'Survei Selesai';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'Perlu Disurvei';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Portal PPL Lapangan'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _handleLogout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kartu Profil Petugas PPL
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFDBEAFE),
                            child: const Icon(Icons.badge_rounded, color: primaryBlue, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.user.nama,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Petugas Penyuluh Lapangan (PPL)',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Tugas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Tugas Survei Sawah',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_tasks.length} Pengajuan',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // List Kartu Tugas
                  if (_tasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Belum ada tugas disposisi survei baru dari Admin.'),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final isCompleted = task.status == 'MENUNGGU_PERSETUJUAN_AKHIR';

                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pengajuan #${task.id}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                    ),
                                    _buildStatusBadge(task.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  task.namaPetani,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.grass, size: 16, color: primaryGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${task.namaPupuk} • ${task.jumlahDiajukan.toInt()} Kg',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.terrain, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${task.lokasiLahan} (${task.luasLahanM2.toInt()} m²)',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),

                                // Tombol Aksi PPL
                                if (!isCompleted)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.satellite_alt_rounded, color: Colors.white, size: 18),
                                      label: const Text(
                                        'Survei Fisik & Ukur Citra Satelit',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryGreen,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                      ),
                                      onPressed: () {
                                        _openSurveyForm(task);
                                      },
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '✅ Laporan Survei Telah Diteruskan ke Admin',
                                      style: TextStyle(
                                        color: Color(0xFF15803D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
