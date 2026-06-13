import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_status.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/attachment_preview.dart';
import '../../../core/services/websocket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class CreatorCollaborationDetailsScreen extends StatefulWidget {
  final int id;
  const CreatorCollaborationDetailsScreen({super.key, required this.id});

  @override
  State<CreatorCollaborationDetailsScreen> createState() => _State();
}

class _State extends State<CreatorCollaborationDetailsScreen> {
  Collaboration? _collab;
  bool _isLoading = true;
  final _msgController = TextEditingController();
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
      if (!mounted || _collab == null || message.collaborationId != widget.id) {
        return;
      }

      final currentUserId = context.read<AuthProvider>().user?.id;
      setState(() {
        _collab!.messages ??= [];
        if (!_collab!.messages!.any((m) => m.id == message.id)) {
          _collab!.messages!.add(message);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
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
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getCollaboration(widget.id);
      if (mounted) {
        setState(() {
          _collab = data;
          _isLoading = false;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isCollaborationLocked {
    final status = _collab?.status;
    return status == 'completed' || status == 'cancelled';
  }

  String _statusLabel(String status) {
    return AppStatus.collaborationLabel(status);
  }

  Color _statusColor(String status) {
    return AppStatus.collaborationColor(status);
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
    if (!mounted || _collab == null || collaborationId != _collab!.id) {
      return;
    }

    setState(() {
      _collab = _collab!.copyWith(
        brandLastReadAt:
            payload['brand_last_read_at']?.toString() ??
            _collab!.brandLastReadAt,
        creatorLastReadAt:
            payload['creator_last_read_at']?.toString() ??
            _collab!.creatorLastReadAt,
        brandLastSeenAt:
            payload['brand_last_seen_at']?.toString() ??
            _collab!.brandLastSeenAt,
        creatorLastSeenAt:
            payload['creator_last_seen_at']?.toString() ??
            _collab!.creatorLastSeenAt,
        unreadCount: int.tryParse(payload['unread_count']?.toString() ?? ''),
      );
    });
  }

  Future<void> _send() async {
    if (_isCollaborationLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette collaboration est terminée'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    try {
      await ApiService().sendCollaborationMessage(
        widget.id,
        FormData.fromMap({'content': text}),
      );
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
      final pickedFile = result.files.single;
      final sizeError = AppFileUtils.sizeError(
        bytes: pickedFile.size,
        maxBytes: AppFileUtils.maxUploadBytes,
      );
      if (sizeError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sizeError), backgroundColor: AppColors.error),
        );
        return;
      }

      final path = pickedFile.path!;
      final formData = FormData.fromMap({
        'attachment': await MultipartFile.fromFile(
          path,
          filename: pickedFile.name,
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

  Future<void> _openAttachment(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  bool _isSeenByOther(Message message, int? currentUserId) {
    final collaboration = _collab;
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
          _collab?.announcement?.title ?? 'Collaboration',
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
    final collaboration = _collab;
    final announcement = collaboration?.announcement;
    final brand = collaboration?.brand?.brandProfile;
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
            Icons.business_outlined,
            'Marque',
            brand?.name ?? 'Marque',
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
          if (_isCollaborationLocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                'Les nouveaux messages et livrables sont verrouillés.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    final myId = context.read<AuthProvider>().user?.id;
    return Column(
      children: [
        Expanded(
          child: _collab?.messages?.isEmpty ?? true
              ? Center(
                  child: Text(
                    'Aucun message',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _collab!.messages!.length,
                  itemBuilder: (_, i) {
                    final m = _collab!.messages![i];
                    final mine = m.senderId == myId;
                    return Align(
                      alignment: mine
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
                          color: mine ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(mine ? 16 : 4),
                            bottomRight: Radius.circular(mine ? 4 : 16),
                          ),
                          border: mine
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m.attachment != null &&
                                m.attachment!.isNotEmpty) ...[
                              InkWell(
                                onTap: () => _openAttachment(m.attachment!),
                                child: AppAttachmentPreview(
                                  source: m.attachment!,
                                  inverse: mine,
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.6,
                                ),
                              ),
                              if (m.content != null) const SizedBox(height: 8),
                            ],
                            if (m.content != null)
                              Text(
                                m.content!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: mine ? Colors.white : AppColors.text,
                                  height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 4),
                            _messageMeta(m, mine, myId),
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
              controller: _msgController,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                hintStyle: GoogleFonts.inter(color: AppColors.placeholder),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: _send,
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
    final announcement = _collab?.announcement;
    final subs = _collab?.submissions ?? [];
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomSafeArea + (_isCollaborationLocked ? 16 : 104);

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          children: [
            if (announcement != null &&
                ((announcement.platforms ?? []).isNotEmpty ||
                    (announcement.deliverables ?? []).isNotEmpty)) ...[
              _deliverablesHeading('Livrables requis'),
              _requiredDeliverables(announcement),
              const SizedBox(height: 20),
            ],
            _deliverablesHeading('Livrables soumis'),
            if (subs.isEmpty)
              _emptySubmissionsCard()
            else
              ...subs.map(_submissionCard),
          ],
        ),
        if (!_isCollaborationLocked)
          Positioned(
            bottom: bottomSafeArea + 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _showSubmitDeliverableModal,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                "Soumettre un livrable",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _deliverablesHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _emptySubmissionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        'Aucun livrable soumis pour le moment',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _requiredDeliverables(Announcement announcement) {
    final platforms = announcement.platforms ?? const <PlatformModel>[];
    final deliverables =
        announcement.deliverables ?? const <DeliverableWithPivot>[];

    if (deliverables.isEmpty) {
      return _emptyRequiredDeliverablesCard();
    }

    final platformBlocks = platforms
        .map((platform) {
          final items = deliverables
              .where((deliverable) => deliverable.platformId == platform.id)
              .toList();
          return _deliverablePlatformBlock(platform.name, items);
        })
        .whereType<Widget>()
        .toList();

    final orphanDeliverables = deliverables
        .where(
          (deliverable) => !platforms.any(
            (platform) => platform.id == deliverable.platformId,
          ),
        )
        .toList();
    if (orphanDeliverables.isNotEmpty) {
      final block = _deliverablePlatformBlock('Autres', orphanDeliverables);
      if (block != null) platformBlocks.add(block);
    }

    if (platformBlocks.isEmpty) {
      final block = _deliverablePlatformBlock('Livrables', deliverables);
      if (block != null) platformBlocks.add(block);
    }

    return Column(children: platformBlocks);
  }

  Widget _emptyRequiredDeliverablesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        'Aucun livrable spécifique renseigné.',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget? _deliverablePlatformBlock(
    String platformName,
    List<DeliverableWithPivot> deliverables,
  ) {
    if (deliverables.isEmpty) return null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  platformName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...deliverables.map(
            (deliverable) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${deliverable.quantity} x ${deliverable.name}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submissionCard(DeliverableSubmission sub) {
    final title = _submissionTitle(sub);
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _submissionStatus(sub.status),
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
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                child: AppAttachmentPreview(
                  source: sub.attachment!,
                  imageHeight: 150,
                ),
              ),
            ),
          ],
          if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Retour de la marque:",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub.feedback!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _submissionTitle(DeliverableSubmission submission) {
    final typeName =
        submission.deliverableType?.name ?? 'Livrable #${submission.id}';
    final platformName = _submissionPlatformName(submission);
    if (platformName == null || platformName.isEmpty) return typeName;
    return '$typeName pour $platformName';
  }

  String? _submissionPlatformName(DeliverableSubmission submission) {
    final announcement = _collab?.announcement;
    final platforms = announcement?.platforms ?? const <PlatformModel>[];
    final deliverables =
        announcement?.deliverables ?? const <DeliverableWithPivot>[];
    int? platformId = submission.deliverableType?.platformId;
    if (platformId == null) {
      for (final deliverable in deliverables) {
        if (deliverable.id == submission.deliverableTypeId) {
          platformId = deliverable.platformId;
          break;
        }
      }
    }
    if (platformId == null) return null;
    for (final platform in platforms) {
      if (platform.id == platformId) return platform.name;
    }
    return null;
  }

  Widget _submissionStatus(String status) {
    final color = AppStatus.submissionColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppStatus.submissionLabel(status),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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

  void _showSubmitDeliverableModal() {
    final announcement = _collab?.announcement;
    final deliverables =
        announcement?.deliverables ?? const <DeliverableWithPivot>[];
    final platforms = announcement?.platforms ?? const <PlatformModel>[];
    if (deliverables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun livrable requis trouvé"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final platformsWithDeliverables = platforms
        .where(
          (platform) => deliverables.any(
            (deliverable) => deliverable.platformId == platform.id,
          ),
        )
        .toList();
    int? selectedPlatformId = platformsWithDeliverables.isNotEmpty
        ? platformsWithDeliverables.first.id
        : null;
    List<DeliverableWithPivot> visibleDeliverables() {
      if (selectedPlatformId == null) return deliverables;
      return deliverables
          .where((deliverable) => deliverable.platformId == selectedPlatformId)
          .toList();
    }

    int? selectedDeliverableId = visibleDeliverables().isNotEmpty
        ? visibleDeliverables().first.id
        : deliverables.first.id;
    final urlController = TextEditingController();
    File? selectedFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentDeliverables = visibleDeliverables();
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final bottomSafeArea = MediaQuery.of(context).padding.bottom;
            return SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  bottomInset + bottomSafeArea + 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Soumettre un livrable",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (platformsWithDeliverables.isNotEmpty) ...[
                      Text(
                        'Plateforme',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _modalDropdown<int>(
                        value: selectedPlatformId,
                        items: platformsWithDeliverables
                            .map(
                              (platform) => DropdownMenuItem<int>(
                                value: platform.id,
                                child: Text(
                                  platform.name,
                                  style: GoogleFonts.inter(
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedPlatformId = val;
                              final nextDeliverables = visibleDeliverables();
                              selectedDeliverableId =
                                  nextDeliverables.isNotEmpty
                                  ? nextDeliverables.first.id
                                  : null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    Text(
                      'Livrable concerné',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _modalDropdown<int>(
                      value: selectedDeliverableId,
                      items: currentDeliverables
                          .map(
                            (deliverable) => DropdownMenuItem<int>(
                              value: deliverable.id,
                              child: Text(
                                '${deliverable.quantity} x ${deliverable.name}',
                                style: GoogleFonts.inter(color: AppColors.text),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedDeliverableId = val);
                        }
                      },
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'URL du livrable (optionnel)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: urlController,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'Fichier joint (optionnel)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles();
                        if (result != null &&
                            result.files.single.path != null) {
                          final pickedFile = result.files.single;
                          final sizeError = AppFileUtils.sizeError(
                            bytes: pickedFile.size,
                            maxBytes: AppFileUtils.maxUploadBytes,
                          );
                          if (sizeError != null) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(sizeError),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          setModalState(() {
                            selectedFile = File(pickedFile.path!);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              color: selectedFile != null
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFile != null
                                    ? AppFileUtils.displayName(
                                        selectedFile!.path,
                                      )
                                    : 'Sélectionner un fichier',
                                style: GoogleFonts.inter(
                                  color: selectedFile != null
                                      ? AppColors.text
                                      : AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selectedFile != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () =>
                                    setModalState(() => selectedFile = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (selectedDeliverableId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sélectionnez un livrable'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                if (urlController.text.trim().isEmpty &&
                                    selectedFile == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Veuillez entrer une URL ou choisir un fichier',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                try {
                                  final formDataParams = <String, dynamic>{
                                    'deliverable_type_id':
                                        selectedDeliverableId,
                                  };
                                  if (urlController.text.trim().isNotEmpty) {
                                    formDataParams['url'] = urlController.text
                                        .trim();
                                  }
                                  if (selectedFile != null) {
                                    formDataParams['attachment'] =
                                        await MultipartFile.fromFile(
                                          selectedFile!.path,
                                          filename: selectedFile!.path
                                              .split('/')
                                              .last,
                                        );
                                  }

                                  await ApiService().submitDeliverable(
                                    widget.id,
                                    FormData.fromMap(formDataParams),
                                  );
                                  if (!context.mounted || !mounted) return;
                                  Navigator.pop(context);
                                  _load();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Livrable envoyé !'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                } on DioException catch (e) {
                                  if (context.mounted && mounted) {
                                    setModalState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ApiService.errorMessage(e),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted && mounted) {
                                    setModalState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erreur: ${e.toString()}',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Envoyer',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
