import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreatorCollaborationsScreen extends StatefulWidget {
  const CreatorCollaborationsScreen({super.key});

  @override
  State<CreatorCollaborationsScreen> createState() => _State();
}

class _State extends State<CreatorCollaborationsScreen> {
  List<Collaboration> _collaborations = [];
  bool _isLoading = true;
  String _filter = 'all';
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  final Set<int> _subscribedCollaborationIds = {};

  @override
  void initState() {
    super.initState();
    _messageSubscription = WebSocketService().messages.listen(
      _handleRealtimeMessage,
    );
    _load();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    WebSocketService().unsubscribeFromCollaborationUpdates(
      _subscribedCollaborationIds,
    );
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService().getCollaborations(
        status: _filter == 'all' ? null : _filter,
      );
      if (mounted) {
        setState(() {
          _collaborations = data;
          _isLoading = false;
        });
        await _syncRealtimeSubscriptions();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncRealtimeSubscriptions() async {
    final nextIds = _collaborations.map((c) => c.id).toSet();
    final removed = _subscribedCollaborationIds.difference(nextIds);
    final added = nextIds.difference(_subscribedCollaborationIds);

    if (removed.isNotEmpty) {
      await WebSocketService().unsubscribeFromCollaborationUpdates(removed);
    }
    if (added.isNotEmpty) {
      await WebSocketService().subscribeToCollaborationUpdates(added);
    }

    _subscribedCollaborationIds
      ..clear()
      ..addAll(nextIds);
  }

  void _handleRealtimeMessage(Map<String, dynamic> data) {
    if (!mounted) return;

    final message = Message.fromJson(data);
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (message.senderId == currentUserId) return;

    final index = _collaborations.indexWhere(
      (collaboration) => collaboration.id == message.collaborationId,
    );
    if (index == -1) return;

    setState(() {
      final collaboration = _collaborations[index];
      _collaborations[index] = collaboration.copyWith(
        unreadCount: (collaboration.unreadCount ?? 0) + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _chip('Tous', 'all'),
                _chip('Actif', 'active'),
                _chip('En cours', 'in_progress'),
                _chip('Terminé', 'completed'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _collaborations.isEmpty
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
                            Icons.work_outline,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune collaboration',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _collaborations.length,
                      itemBuilder: (_, i) => _card(_collaborations[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: sel ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'canceled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return AppColors.success;
      case 'canceled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _card(Collaboration c) {
    final profile = c.brand?.brandProfile;
    final brandName = profile?.name ?? 'Marque';
    final logo = profile?.logo;
    final title = c.announcement?.title ?? 'Collaboration #${c.id}';
    final statusColor = _getStatusColor(c.status);

    return GestureDetector(
      onTap: () async {
        await context.push('/creator/collaboration/${c.id}');
        _load(showLoading: false);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLightest,
              backgroundImage: logo != null
                  ? CachedNetworkImageProvider(logo)
                  : null,
              child: logo == null
                  ? Text(
                      brandName.isNotEmpty ? brandName[0].toUpperCase() : 'M',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'avec $brandName',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusLabel(c.status),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (c.unreadCount != null && c.unreadCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${c.unreadCount}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
