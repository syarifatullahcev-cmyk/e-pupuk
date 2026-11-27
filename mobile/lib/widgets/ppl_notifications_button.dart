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
  int _unreadCount = 0;
  List<Map<String, dynamic>> _cachedNotifs = [];

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final notifications = await PPLService.getNotifications();
      if (mounted) {
        setState(() {
          _cachedNotifs = notifications;
          _unreadCount =
              notifications.where((n) => n['is_read'] != true).length;
        });
      }
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final notifications = await PPLService.getNotifications();
      if (!mounted) return;
      setState(() {
        _cachedNotifs = notifications;
        _unreadCount = notifications.where((n) => n['is_read'] != true).length;
      });

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (bottomSheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            size: 18,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Pemberitahuan Tugas PPL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_unreadCount > 0)
                      TextButton(
                        onPressed: () async {
                          try {
                            await PPLService.markAllNotificationsRead();
                          } catch (_) {
                            for (final n in _cachedNotifs) {
                              final id = n['id'];
                              if (id is int && n['is_read'] != true) {
                                await PPLService.markNotificationRead(id)
                                    .catchError((_) {});
                              }
                            }
                          }
                          if (mounted) {
                            setState(() {
                              for (var n in _cachedNotifs) {
                                n['is_read'] = true;
                              }
                              _unreadCount = 0;
                            });
                            setSheetState(() {});
                          }
                        },
                        child: const Text(
                          'Tandai Semua Dibaca',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                if (_cachedNotifs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 42, color: Color(0xFF94A3B8)),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada tugas atau notifikasi baru',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _cachedNotifs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = _cachedNotifs[index];
                        final isRead = notification['is_read'] == true;
                        final title = notification['judul']?.toString() ??
                            'Pemberitahuan Tugas PPL';
                        final message =
                            notification['pesan']?.toString() ?? '';
                        final createdAt = DateTime.tryParse(
                          notification['created_at']?.toString() ?? '',
                        );

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isRead
                                  ? Icons.check_circle_outline
                                  : Icons.assignment_turned_in_rounded,
                              size: 16,
                              color: isRead
                                  ? const Color(0xFF94A3B8)
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  MaterialLocalizations.of(context)
                                      .formatShortDate(createdAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: isRead
                              ? null
                              : () async {
                                  final id = notification['id'];
                                  if (id is! int) return;
                                  try {
                                    await PPLService.markNotificationRead(id);
                                    if (mounted) {
                                      setState(() {
                                        notification['is_read'] = true;
                                        _unreadCount = _cachedNotifs
                                            .where((n) => n['is_read'] != true)
                                            .length;
                                      });
                                      setSheetState(() {});
                                    }
                                  } catch (_) {}
                                },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tutup',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
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
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notifikasi',
          icon: Icon(
            _isLoading
                ? Icons.hourglass_top
                : Icons.notifications_none_outlined,
            color: AppTheme.textPrimary,
          ),
          onPressed: _isLoading ? null : _openNotifications,
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFE11D48),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              child: Center(
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
