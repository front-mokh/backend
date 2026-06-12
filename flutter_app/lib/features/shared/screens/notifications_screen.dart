import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _State();
}

class _State extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().getNotifications();
      if (mounted) {
        setState(() {
          _notifications = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _extractId(String route) {
    final match = RegExp(r'/(\d+)(?:\?|$)').firstMatch(route);
    return match?.group(1);
  }

  String? _paramId(AppNotification notification) {
    final params = notification.data?['params'];
    if (params is Map) return params['id']?.toString();
    return null;
  }

  String? _flutterRouteFor(AppNotification notification) {
    final route = notification.data?['route']?.toString();
    if (route == null || route.isEmpty) return null;

    if (route.contains('/brand/application-details/')) {
      final id = _paramId(notification) ?? _extractId(route);
      return id == null ? null : '/brand/application/$id';
    }
    if (route.contains('/brand/collaboration-details/')) {
      final id = _paramId(notification) ?? _extractId(route);
      return id == null ? null : '/brand/collaboration/$id';
    }
    if (route.contains('/creator/collaboration-details/')) {
      final id = _paramId(notification) ?? _extractId(route);
      return id == null ? null : '/creator/collaboration/$id';
    }
    if (route == '/creator/applications') return route;
    if (route == '/brand/announcements') return route;

    return route;
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    if (!notification.isRead) {
      await ApiService().markNotificationAsRead(notification.id);
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            _notifications[index] = notification.copyWith(
              readAt: DateTime.now().toIso8601String(),
            );
          }
        });
      }
    }

    final route = _flutterRouteFor(notification);
    if (route != null && mounted) context.push(route);
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_application':
        return Icons.person_add_outlined;
      case 'application_accepted':
        return Icons.check_circle_outline;
      case 'application_rejected':
        return Icons.cancel_outlined;
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'collaboration_started':
        return Icons.work_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                await ApiService().markAllNotificationsAsRead();
                _load();
              },
              child: Text(
                'Tout lire',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (_, i) {
                  final n = _notifications[i];
                  return Dismissible(
                    key: Key(n.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: AppColors.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await ApiService().deleteNotification(n.id);
                      setState(() => _notifications.removeAt(i));
                    },
                    child: InkWell(
                      onTap: () => _handleNotificationTap(n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? AppColors.surface
                              : AppColors.primaryLightest.withValues(
                                  alpha: 0.3,
                                ),
                          border: Border(
                            bottom: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: n.isRead
                                    ? AppColors.surfaceElevated
                                    : AppColors.primaryLightest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _typeIcon(n.type),
                                size: 22,
                                color: n.isRead
                                    ? AppColors.textTertiary
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: n.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.body,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
