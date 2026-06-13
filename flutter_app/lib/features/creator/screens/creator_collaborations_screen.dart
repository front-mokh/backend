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
import '../../../core/utils/app_status.dart';
import '../../../core/widgets/app_state_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreatorCollaborationsScreen extends StatefulWidget {
  const CreatorCollaborationsScreen({super.key});

  @override
  State<CreatorCollaborationsScreen> createState() => _State();
}

class _State extends State<CreatorCollaborationsScreen> {
  final _searchController = TextEditingController();
  List<Collaboration> _collaborations = [];
  bool _isLoading = true;
  String? _errorMessage;
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final data = await ApiService().getCollaborations();
      if (mounted) {
        setState(() {
          _collaborations = data;
          _isLoading = false;
          _errorMessage = null;
        });
        await _syncRealtimeSubscriptions();
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

  List<Collaboration> get _filteredCollaborations {
    final query = _searchController.text.trim().toLowerCase();
    return _collaborations.where((collaboration) {
      final brandName =
          collaboration.brand?.brandProfile?.name.toLowerCase() ?? '';
      final title = collaboration.announcement?.title.toLowerCase() ?? '';
      final matchesStatus = _filter == 'all' || collaboration.status == _filter;
      final matchesSearch =
          query.isEmpty || brandName.contains(query) || title.contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Map<String, int> get _statusCounts {
    final counts = {
      'all': _collaborations.length,
      'in_progress': 0,
      'completed': 0,
      'cancelled': 0,
    };
    for (final collaboration in _collaborations) {
      if (counts.containsKey(collaboration.status)) {
        counts[collaboration.status] = counts[collaboration.status]! + 1;
      }
    }
    return counts;
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
          _buildHeader(),
          Expanded(
            child: _isLoading ? const AppLoadingState() : _buildBodyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyState() {
    if (_errorMessage != null && _collaborations.isEmpty) {
      return AppRefreshableState(
        onRefresh: () => _load(showLoading: false),
        child: AppErrorState(message: _errorMessage!, onRetry: () => _load()),
      );
    }

    if (_collaborations.isEmpty) {
      return AppRefreshableState(
        onRefresh: () => _load(showLoading: false),
        child: const AppEmptyState(
          icon: Icons.work_outline,
          title: 'Aucune collaboration',
        ),
      );
    }

    if (_filteredCollaborations.isEmpty) {
      return AppRefreshableState(
        onRefresh: () => _load(showLoading: false),
        child: const AppEmptyState(
          icon: Icons.search_off,
          title: 'Aucun résultat',
          message: 'Aucune collaboration ne correspond aux filtres',
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(showLoading: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _filteredCollaborations.length,
        itemBuilder: (_, i) => _card(_filteredCollaborations[i]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Rechercher une collaboration',
              hintStyle: GoogleFonts.inter(color: AppColors.placeholder),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textTertiary,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Tous', 'all'),
                _chip('En cours', 'in_progress'),
                _chip('Terminés', 'completed'),
                _chip('Annulés', 'cancelled'),
              ],
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
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          '$label ${_statusCounts[value] ?? 0}',
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
    return AppStatus.collaborationLabel(status);
  }

  Color _getStatusColor(String status) {
    return AppStatus.collaborationColor(status);
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
