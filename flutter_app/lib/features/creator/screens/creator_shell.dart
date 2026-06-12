import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/app_colors.dart';

class CreatorShell extends StatefulWidget {
  final Widget child;
  const CreatorShell({super.key, required this.child});

  @override
  State<CreatorShell> createState() => _CreatorShellState();
}

class _CreatorShellState extends State<CreatorShell> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  bool _notificationSocketStarted = false;
  Timer? _notificationPollTimer;

  static const _tabs = [
    '/creator/announcements',
    '/creator/applications',
    '/creator/collaborations',
    '/creator/profile',
  ];

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Annonces';
      case 1:
        return 'Mes Candidatures';
      case 2:
        return 'Collaboration';
      case 3:
        return 'Profil';
      default:
        return '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    if (idx != -1 && idx != _currentIndex) setState(() => _currentIndex = idx);
    _setupNotificationBadge();
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    super.dispose();
  }

  void _setupNotificationBadge() {
    if (_notificationSocketStarted) return;
    _notificationSocketStarted = true;

    final user = context.read<AuthProvider>().user;
    _loadUnreadNotifications();
    if (user != null) {
      WebSocketService().onNotificationReceived = (_) =>
          _loadUnreadNotifications();
      WebSocketService().subscribeToUserNotifications(user.id);
    }
    _notificationPollTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _loadUnreadNotifications();
    });
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final data = await ApiService().getUnreadNotificationsCount();
      final count = int.tryParse(data['count'].toString()) ?? 0;
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _getTitle(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.text),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _unreadNotifications > 9
                            ? '9+'
                            : '$_unreadNotifications',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await context.push('/notifications');
              _loadUnreadNotifications();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.tabBarBg,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.15),
              offset: const Offset(0, -4),
              blurRadius: 12,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTab(Icons.campaign_outlined, 'Annonces', 0),
                _buildTab(Icons.description_outlined, 'Candidatures', 1),
                _buildTab(Icons.work_outline, 'Collaboration', 2),
                _buildTab(Icons.person_outline, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          context.go(_tabs[index]);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? AppColors.tabBarActive : AppColors.tabBarInactive,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isActive
                  ? AppColors.tabBarActive
                  : AppColors.tabBarInactive,
            ),
          ),
        ],
      ),
    );
  }
}
