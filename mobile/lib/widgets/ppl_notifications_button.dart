import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/ppl_service.dart';

class PPLNotificationsButton extends StatefulWidget {
  const PPLNotificationsButton({super.key});

  @override
  State<PPLNotificationsButton> createState() => _PPLNotificationsButtonState();
}

class _PPLNotificationsButtonState extends State<PPLNotificationsButton> {
  bool _isLoading = false;

  Future<void> _openNotifications() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final notifications = await PPLService.getNotifications();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Notifikasi'),
            content: SizedBox(
              width: 420,
              child: notifications.isEmpty
                  ? const Text('Belum ada notifikasi.')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isRead = notification['is_read'] == true;
                        final createdAt = DateTime.tryParse(
                          notification['created_at']?.toString() ?? '',
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: isRead
                                ? AppTheme.textSecondary
                                : AppTheme.primaryGreen,
                          ),
                          title: Text(
                            notification['judul']?.toString() ??
                                'Notifikasi E-Pupuk',
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification['pesan']?.toString() ?? ''),
                              if (createdAt != null)
                                Text(
                                  MaterialLocalizations.of(context)
                                      .formatShortDate(createdAt),
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                          onTap: isRead
                              ? null
                              : () async {
                                  final id = notification['id'];
                                  if (id is! int) return;
                                  try {
                                    await PPLService.markNotificationRead(id);
                                    if (!dialogContext.mounted) return;
                                    setDialogState(
                                      () => notification['is_read'] = true,
                                    );
                                  } catch (error) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal memperbarui notifikasi: $error',
                                          ),
                                        ),
                                      );
                                  }
                                },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Notifikasi gagal dimuat: $error')),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Notifikasi',
        icon: Icon(
          _isLoading ? Icons.hourglass_top : Icons.notifications_none_outlined,
          color: AppTheme.textPrimary,
        ),
        onPressed: _isLoading ? null : _openNotifications,
      );
}
