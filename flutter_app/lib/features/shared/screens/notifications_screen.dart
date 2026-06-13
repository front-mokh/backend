import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/notification_route_mapper.dart';
import '../../../core/widgets/app_state_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _State();
}

class _State extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load(showLoading: true);
  }

  Future<void> _load({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final res = await ApiService().getNotifications();
      if (mounted) {
        setState(() {
          _notifications = res.data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ApiService.messageFromError(e);
        });
      }
    }
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

    final route = NotificationRouteMapper.routeFor(notification.data ?? {});
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
      body: _isLoading ? const AppLoadingState() : _buildBodyState(),
    );
  }

  Widget _buildBodyState() {
    if (_errorMessage != null && _notifications.isEmpty) {
      return AppRefreshableState(
        onRefresh: () => _load(),
        child: AppErrorState(message: _errorMessage!, onRetry: () => _load()),
      );
    }

    if (_notifications.isEmpty) {
      return AppRefreshableState(
        onRefresh: () => _load(),
        child: const AppEmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'Aucune notification',
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
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
                      : AppColors.primaryLightest.withValues(alpha: 0.3),
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
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
    );
  }
}
