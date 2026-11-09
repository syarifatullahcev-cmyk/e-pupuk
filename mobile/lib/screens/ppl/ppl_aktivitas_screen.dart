import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/ppl_task_model.dart';
import '../../models/user_model.dart';
import '../../services/ppl_service.dart';
import '../../widgets/ppl_notifications_button.dart';
import 'ppl_detail_tugas_screen.dart';

class PPLAktivitasScreen extends StatefulWidget {
  final UserModel user;

  const PPLAktivitasScreen({super.key, required this.user});

  @override
  State<PPLAktivitasScreen> createState() => _PPLAktivitasScreenState();
}

class _PPLAktivitasScreenState extends State<PPLAktivitasScreen> {
  List<PPLTaskModel> _tasks = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await PPLService.getAssignedTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _loadError = null;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.toString();
          _isLoading = false;
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
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history,
                  color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'E-PUPUK MOJOKERTO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Tugas & Survei',
                  style: TextStyle(
                    fontSize: 16,
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
              child: Text(_initials,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistik Aktivitas
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Tugas Ditugaskan',
                    value: '${_tasks.length}',
                    subtitle: 'Data dari server',
                    color: AppTheme.primaryGreen,
                    icon: Icons.task_alt,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Poligon Tersimpan',
                    value:
                        '${_tasks.where((task) => task.parsedPolygonPoints.length >= 3).length}',
                    subtitle: 'Memiliki batas survei',
                    color: const Color(0xFF2563EB),
                    icon: Icons.polyline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Text(
              'Tugas Lapangan',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              )
            else if (_loadError != null)
              _buildLoadError()
            else if (_tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Belum ada tugas lapangan yang tercatat.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ..._tasks.map(_buildTaskItem),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String get _initials {
    final parts = widget.user.nama.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return '?';
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }

  Widget _buildLoadError() {
    return Center(
      child: Column(
        children: [
          Text(
            'Gagal memuat tugas: $_loadError',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB91C1C)),
          ),
          TextButton.icon(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(PPLTaskModel task) {
    final Color statusColor;
    final IconData statusIcon;
    if (task.status == 'MENUNGGU_PERSETUJUAN_AKHIR' ||
        task.status == 'DISETUJUI') {
      statusColor = AppTheme.primaryGreen;
      statusIcon = Icons.check_circle_outline;
    } else if (task.status == 'PERLU_PERBAIKAN_BERKAS' ||
        task.status == 'DITOLAK_LAPANGAN') {
      statusColor = AppTheme.warningOrange;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF2563EB);
      statusIcon = Icons.timelapse;
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PPLDetailTugasScreen(task: task),
        ),
      ),
      child: _buildActivityItem(
        title: task.taskIdCode,
        subtitle: '${task.namaPetani} • ${task.lokasiLahan}',
        time: task.jadwal,
        status: task.statusLabel,
        statusColor: statusColor,
        icon: statusIcon,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withOpacity(0.12),
            child: Icon(icon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(time,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
