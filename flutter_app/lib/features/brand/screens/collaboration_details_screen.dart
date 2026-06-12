import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/websocket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class BrandCollaborationDetailsScreen extends StatefulWidget {
  final int id;
  const BrandCollaborationDetailsScreen({super.key, required this.id});

  @override
  State<BrandCollaborationDetailsScreen> createState() => _State();
}

class _State extends State<BrandCollaborationDetailsScreen> {
  Collaboration? _collaboration;
  bool _isLoading = true;
  bool _isCompleting = false;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _heartbeatTimer;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _readReceiptSubscription;

  @override
  void initState() {
    super.initState();
    _startPresenceTracking();
    _load();
    _setupWebSocket();
  }

  void _startPresenceTracking() {
    ApiService().sendHeartbeat(widget.id).catchError((_) {});
    ApiService()
        .markCollabAsRead(widget.id)
        .catchError((_) => <String, dynamic>{});

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ApiService().sendHeartbeat(widget.id).catchError((_) {});
    });
  }

  void _setupWebSocket() {
    _messageSubscription = WebSocketService().messages.listen((msgData) {
      final message = Message.fromJson(msgData);
      if (!mounted ||
          _collaboration == null ||
          message.collaborationId != widget.id) {
        return;
      }

      final currentUserId = context.read<AuthProvider>().user?.id;
      setState(() {
        _collaboration!.messages ??= [];
        if (!_collaboration!.messages!.any((m) => m.id == message.id)) {
          _collaboration!.messages!.add(message);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      });

      if (message.senderId != currentUserId) {
        _markAsRead();
      }
    });
    _readReceiptSubscription = WebSocketService().readReceipts.listen(
      _applyReadState,
    );
    WebSocketService().subscribeToCollaboration(widget.id);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _messageSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    WebSocketService().unsubscribeFromCollaboration();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getCollaboration(widget.id);
      if (mounted) {
        setState(() {
          _collaboration = data;
          _isLoading = false;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isCollaborationLocked {
    final status = _collaboration?.status;
    return status == 'completed' || status == 'cancelled';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      case 'active':
      case 'in_progress':
        return 'En cours';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'active':
      case 'in_progress':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _completeCollaboration() async {
    final collaboration = _collaboration;
    if (collaboration == null || _isCollaborationLocked) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Terminer la collaboration',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Cette action marquera la collaboration comme terminée.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Terminer',
              style: GoogleFonts.inter(color: AppColors.success),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCompleting = true);
    try {
      final updated = await ApiService().completeCollaboration(
        collaboration.id,
      );
      if (!mounted) return;
      setState(() => _collaboration = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collaboration terminée'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _markAsRead() async {
    try {
      final payload = await ApiService().markCollabAsRead(widget.id);
      if (mounted) _applyReadState(payload);
    } catch (_) {}
  }

  void _applyReadState(Map<String, dynamic> payload) {
    final collaborationId = int.tryParse(
      payload['collaboration_id']?.toString() ?? '',
    );
    if (!mounted ||
        _collaboration == null ||
        collaborationId != _collaboration!.id) {
      return;
    }

    setState(() {
      _collaboration = _collaboration!.copyWith(
        brandLastReadAt:
            payload['brand_last_read_at']?.toString() ??
            _collaboration!.brandLastReadAt,
        creatorLastReadAt:
            payload['creator_last_read_at']?.toString() ??
            _collaboration!.creatorLastReadAt,
        brandLastSeenAt:
            payload['brand_last_seen_at']?.toString() ??
            _collaboration!.brandLastSeenAt,
        creatorLastSeenAt:
            payload['creator_last_seen_at']?.toString() ??
            _collaboration!.creatorLastSeenAt,
        unreadCount: int.tryParse(payload['unread_count']?.toString() ?? ''),
      );
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _updateSubmission(int subId, String status) async {
    try {
      await ApiService().updateSubmissionStatus(subId, status);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut mis à jour avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur de mise à jour"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_isCollaborationLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette collaboration est terminée'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    try {
      final formData = FormData.fromMap({'content': text});
      await ApiService().sendCollaborationMessage(widget.id, formData);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'envoi"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendAttachment() async {
    if (_isCollaborationLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette collaboration est terminée'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'pdf',
        'mp4',
        'mov',
      ],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      final path = result.files.single.path!;
      final formData = FormData.fromMap({
        'attachment': await MultipartFile.fromFile(
          path,
          filename: result.files.single.name,
        ),
      });
      await ApiService().sendCollaborationMessage(widget.id, formData);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'envoi du fichier"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _isImageUrl(String url) {
    return RegExp(
      r'\.(jpg|jpeg|png|gif|webp|bmp)(\?.*)?$',
      caseSensitive: false,
    ).hasMatch(url);
  }

  Future<void> _openAttachment(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  bool _isSeenByOther(Message message, int? currentUserId) {
    final collaboration = _collaboration;
    if (currentUserId == null || collaboration == null) return false;
    if (message.senderId != currentUserId) return false;

    final otherReadAt = currentUserId == collaboration.brandId
        ? collaboration.creatorLastReadAt
        : collaboration.brandLastReadAt;
    if (otherReadAt == null) return false;

    final readAt = DateTime.tryParse(otherReadAt);
    final sentAt = DateTime.tryParse(message.createdAt);
    if (readAt == null || sentAt == null) return false;

    return !readAt.toUtc().isBefore(sentAt.toUtc());
  }

  Widget _messageMeta(Message message, bool isMine, int? currentUserId) {
    final metaColor = isMine
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textTertiary;
    final seen = _isSeenByOther(message, currentUserId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.createdAt.length >= 16
              ? message.createdAt.substring(11, 16)
              : message.createdAt,
          style: GoogleFonts.inter(fontSize: 11, color: metaColor),
        ),
        if (isMine) ...[
          const SizedBox(width: 6),
          Icon(seen ? Icons.done_all : Icons.check, size: 13, color: metaColor),
          const SizedBox(width: 2),
          Text(
            seen ? 'Vu' : 'Envoyé',
            style: GoogleFonts.inter(fontSize: 11, color: metaColor),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _collaboration?.announcement?.title ?? 'Collaboration',
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: AppColors.surface,
                    child: TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Détails'),
                        Tab(text: 'Messages'),
                        Tab(text: 'Livrables'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(),
                        _buildMessagesTab(),
                        _buildDeliverablesTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailsTab() {
    final collaboration = _collaboration;
    final announcement = collaboration?.announcement;
    final creator = collaboration?.creator?.creatorProfile;
    if (collaboration == null) return const SizedBox.shrink();

    final statusColor = _statusColor(collaboration.status);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusLabel(collaboration.status),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _detailCard(
            Icons.campaign_outlined,
            'Campagne',
            announcement?.title ?? 'Annonce #${collaboration.announcementId}',
          ),
          _detailCard(
            Icons.person_outline,
            'Créateur',
            creator?.fullName ?? 'Créateur',
          ),
          _detailCard(
            Icons.attach_money,
            'Budget proposé',
            '${collaboration.application?.proposedBudget.toInt() ?? 0} DA',
          ),
          if (announcement?.deadline != null)
            _detailCard(
              Icons.calendar_today_outlined,
              'Deadline candidature',
              announcement!.deadline,
            ),
          if (collaboration.completedAt != null)
            _detailCard(
              Icons.check_circle_outline,
              'Date de fin',
              collaboration.completedAt!,
            ),
          const SizedBox(height: 16),
          if (!_isCollaborationLocked)
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCompleting ? null : _completeCollaboration,
                icon: _isCompleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                label: Text(
                  'Terminer la collaboration',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    final currentUserId = context.read<AuthProvider>().user?.id;
    return Column(
      children: [
        Expanded(
          child: _collaboration?.messages?.isEmpty ?? true
              ? Center(
                  child: Text(
                    'Aucun message',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _collaboration!.messages!.length,
                  itemBuilder: (context, i) {
                    final msg = _collaboration!.messages![i];
                    final isMine = msg.senderId == currentUserId;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMine ? 16 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 16),
                          ),
                          border: isMine
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.attachment != null &&
                                msg.attachment!.isNotEmpty) ...[
                              InkWell(
                                onTap: () => _openAttachment(msg.attachment!),
                                child: _isImageUrl(msg.attachment!)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          msg.attachment!,
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.6,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color:
                                                        AppColors.textTertiary,
                                                  ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.attach_file,
                                            size: 18,
                                            color: isMine
                                                ? Colors.white
                                                : AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Pièce jointe',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isMine
                                                    ? Colors.white
                                                    : AppColors.primary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              if (msg.content != null)
                                const SizedBox(height: 8),
                            ],
                            if (msg.content != null)
                              Text(
                                msg.content!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isMine ? Colors.white : AppColors.text,
                                  height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 4),
                            _messageMeta(msg, isMine, currentUserId),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        _isCollaborationLocked ? _lockedFooter() : _messageComposer(),
      ],
    );
  }

  Widget _messageComposer() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
            onPressed: _sendAttachment,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                hintStyle: GoogleFonts.inter(color: AppColors.placeholder),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _lockedFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Text(
        'Actions verrouillées',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDeliverablesTab() {
    final subs = _collaboration?.submissions ?? [];
    if (subs.isEmpty) {
      return Center(
        child: Text(
          'Aucun livrable soumis pour le moment',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subs.length,
      itemBuilder: (context, i) {
        final sub = subs[i];
        final typeName = sub.deliverableType?.name ?? 'Livrable #${sub.id}';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    typeName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sub.status == 'approved'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : sub.status == 'rejected'
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sub.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: sub.status == 'approved'
                            ? AppColors.success
                            : sub.status == 'rejected'
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (sub.url != null && sub.url!.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(sub.url!)),
                  child: Text(
                    sub.url!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
              if (sub.attachment != null && sub.attachment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(sub.attachment!)),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Voir la pièce jointe',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!_isCollaborationLocked &&
                  (sub.status == 'submitted' || sub.status == 'pending')) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateSubmission(sub.id, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: Text(
                          'Rejeter',
                          style: GoogleFonts.inter(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateSubmission(sub.id, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text(
                          'Approuver',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _detailCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
