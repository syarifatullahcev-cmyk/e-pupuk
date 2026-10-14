import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/subsidy_models.dart';
import '../../models/user_model.dart';
import '../../services/subsidy_service.dart';

class RiwayatPengajuanScreen extends StatefulWidget {
  final UserModel user;

  const RiwayatPengajuanScreen({super.key, required this.user});

  @override
  State<RiwayatPengajuanScreen> createState() => _RiwayatPengajuanScreenState();
}

class _RiwayatPengajuanScreenState extends State<RiwayatPengajuanScreen> {
  static const Color primaryGreen = Color(0xFF16A34A);

  bool _isLoading = true;
  List<ApplicationModel> _applications = [];
  List<DistributionModel> _distributions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apps = await SubsidyService.getApplications();
    final dists = await SubsidyService.getDistributions();

    setState(() {
      _applications = apps;
      _distributions = dists;
      _isLoading = false;
    });
  }

  // Cari tiket QR untuk pengajuan tertentu
  DistributionModel? _findDistributionForApp(int appId) {
    try {
      return _distributions.firstWhere((d) => d.applicationId == appId);
    } catch (_) {
      return null;
    }
  }

  // Tampilkan Modal Tiket QR Penebusan Pupuk
  void _showQrTicketDialog(DistributionModel dist) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Kartu E-Tiket
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 40, color: Colors.white),
                    const SizedBox(height: 6),
                    const Text(
                      'TIKET RESMI PENEBUSAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'E-Pupuk Kabupaten Mojokerto',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Isi Konten Tiket
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Kotak QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: dist.qrCodeHash.isNotEmpty ? dist.qrCodeHash : 'INVALID',
                        version: QrVersions.auto,
                        size: 190.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hash Token Cuplikan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Token: ${dist.qrCodeHash.length > 20 ? "${dist.qrCodeHash.substring(0, 20)}..." : dist.qrCodeHash}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Detail Data Penebusan
                    _ticketRow('Penerima', widget.user.nama),
                    _ticketRow('Jenis Pupuk', dist.namaPupuk),
                    _ticketRow('Alokasi Tebus', '${dist.jumlahDisalurkan.toInt()} Kg'),
                    _ticketRow('Lokasi Lahan', dist.namaLahan),
                    _ticketRow(
                      'Status',
                      dist.statusPenyaluran == 'SELESAI' ? 'Sudah Ditebus' : 'Siap Diambil di Kios',
                      valueColor: dist.statusPenyaluran == 'SELESAI' ? Colors.grey : primaryGreen,
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Perlihatkan layar ini ke petugas kios resmi untuk diverifikasi.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol Tutup
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup Tiket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Badge Status Desain Bersih & Elegan
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
      case 'SELESAI':
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
      case 'DITOLAK':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        label = 'Ditolak';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Riwayat & Status Tebus'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada riwayat pengajuan pupuk.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primaryGreen,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final app = _applications[index];
                      final dist = _findDistributionForApp(app.id);
                      final isApproved = app.status == 'DISETUJUI' ||
                          app.status == 'DIJADWALKAN_DISTRIBUSI' ||
                          app.status == 'TERSALURKAN' ||
                          dist != null;

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baris Header: Pupuk & Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.grass, color: primaryGreen, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        app.namaPupuk ?? 'Pupuk Bersubsidi',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildStatusBadge(app.status),
                                ],
                              ),
                              const Divider(height: 24),

                              // Info Data
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Jumlah Diajukan:', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                                  Text(
                                    '${app.jumlahDiajukan.toInt()} Kg',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Lokasi Lahan:', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                                  Text(
                                    app.lokasiLahan ?? 'Lahan Petani',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                                  ),
                                ],
                              ),

                              // Tombol Lihat QR Jika Sudah Disetujui
                              if (isApproved && dist != null) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.qr_code, color: primaryGreen),
                                    label: const Text(
                                      'Tampilkan Tiket QR Code',
                                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: primaryGreen, width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: () => _showQrTicketDialog(dist),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
