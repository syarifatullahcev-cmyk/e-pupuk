import 'package:flutter/material.dart';
import '../../models/subsidy_models.dart';
import '../../services/subsidy_service.dart';

class PengajuanPupukScreen extends StatefulWidget {
  const PengajuanPupukScreen({super.key});

  @override
  State<PengajuanPupukScreen> createState() => _PengajuanPupukScreenState();
}

class _PengajuanPupukScreenState extends State<PengajuanPupukScreen> {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color lightGreenBg = Color(0xFFDCFCE7);

  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();

  List<LandModel> _lands = [];
  List<FertilizerModel> _fertilizers = [];
  LandModel? _selectedLand;
  FertilizerModel? _selectedFertilizer;
  DashboardStatsModel? _stats;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final lands = await SubsidyService.getLands();
    final ferts = await SubsidyService.getFertilizers();
    final stats = await SubsidyService.getStats();

    setState(() {
      _lands = lands;
      _fertilizers = ferts;
      _stats = stats;
      if (_lands.isNotEmpty) {
        _selectedLand = _lands.first;
      }
      if (_fertilizers.isNotEmpty) {
        _selectedFertilizer = _fertilizers.first;
      }
      _isLoading = false;
    });
  }

  // Hitung rekomendasi kuota berdasarkan luas lahan (standar kg per m2)
  double get _rekomendasiKuota {
    if (_selectedLand == null || _selectedFertilizer == null) return 0.0;
    final isUrea = _selectedFertilizer!.namaPupuk.toLowerCase().contains('urea');
    final kuotaTersedia = isUrea ? (_stats?.kuotaTersediaUrea ?? 500.0) : (_stats?.kuotaTersediaNpk ?? 400.0);

    // Estimasi kuota: Luas lahan / 10.000 * 300 kg (standar per hektar)
    final kuotaProporsional = (_selectedLand!.luasM2 / 10000.0) * (isUrea ? 250.0 : 300.0);
    return kuotaProporsional < kuotaTersedia ? kuotaProporsional : kuotaTersedia;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLand == null || _selectedFertilizer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lahan dan jenis pupuk terlebih dahulu.')),
      );
      return;
    }

    final jumlah = double.tryParse(_jumlahController.text.trim()) ?? 0.0;
    if (jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pengajuan harus lebih dari 0 Kg.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await SubsidyService.submitApplication(
      landId: _selectedLand!.id,
      fertilizerId: _selectedFertilizer!.id,
      jumlahDiajukan: jumlah,
      alamatLahan: _selectedLand!.alamatLahan,
      latitude: _selectedLand!.latitude,
      longitude: _selectedLand!.longitude,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: primaryGreen, size: 28),
              SizedBox(width: 8),
              Text('Pengajuan Terkirim'),
            ],
          ),
          content: Text(
            result['message'] ?? 'Pengajuan pupuk berhasil disimpan dan masuk antrean verifikasi Admin.',
            style: const TextStyle(color: Color(0xFF374151)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context, true); // Kembali ke dashboard dengan refresh
              },
              child: const Text('OK, Mengerti', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(result['message'] ?? 'Gagal mengirim pengajuan.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Ajukan Subsidi Pupuk'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner Informasional
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightGreenBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Formulir Pengajuan Musim Tanam',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF14532D),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pengajuan akan diverifikasi oleh Admin Dinas & disurvei oleh PPL.',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card Form Input
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Pilih Lahan
                            const Text(
                              'Pilih Lahan Pertanian',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            if (_lands.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: const Text(
                                  'Belum ada data lahan. Silakan daftarkan lahan terlebih dahulu di web atau hubungi PPL.',
                                  style: TextStyle(color: Color(0xFF92400E), fontSize: 12),
                                ),
                              )
                            else
                              DropdownButtonFormField<LandModel>(
                                value: _selectedLand,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.terrain, color: primaryGreen),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                items: _lands.map((land) {
                                  return DropdownMenuItem<LandModel>(
                                    value: land,
                                    child: Text(
                                      '${land.lokasiDeskripsi} (${land.luasM2.toInt()} m²)',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedLand = val);
                                },
                              ),
                            const SizedBox(height: 18),

                            // 2. Pilih Jenis Pupuk
                            const Text(
                              'Pilih Jenis Pupuk Bersubsidi',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<FertilizerModel>(
                              value: _selectedFertilizer,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.grass, color: primaryGreen),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              items: _fertilizers.map((fert) {
                                return DropdownMenuItem<FertilizerModel>(
                                  value: fert,
                                  child: Text(
                                    '${fert.namaPupuk} (${fert.jenis})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedFertilizer = val);
                              },
                            ),
                            const SizedBox(height: 18),

                            // 3. Batas Kuota & Kalkulasi
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Rekomendasi Batas Kuota:',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_rekomendasiKuota.toStringAsFixed(1)} Kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 4. Input Jumlah Pengajuan (Kg)
                            const Text(
                              'Jumlah Pupuk yang Diajukan (Kg)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _jumlahController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Contoh: 150',
                                suffixText: 'Kg',
                                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
                                prefixIcon: const Icon(Icons.scale, color: primaryGreen),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Harap masukkan jumlah pupuk.';
                                }
                                final n = double.tryParse(value.trim());
                                if (n == null || n <= 0) {
                                  return 'Masukkan angka yang valid lebih dari 0.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Tombol Submit
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.send_rounded, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Kirim Pengajuan Subsidi',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
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
}
