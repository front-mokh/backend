import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_status.dart';

class CreatorApplicationDetailsScreen extends StatefulWidget {
  final int id;
  const CreatorApplicationDetailsScreen({super.key, required this.id});

  @override
  State<CreatorApplicationDetailsScreen> createState() =>
      _CreatorApplicationDetailsScreenState();
}

class _CreatorApplicationDetailsScreenState
    extends State<CreatorApplicationDetailsScreen> {
  Application? _application;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getApplication(widget.id);
      if (!mounted) return;
      setState(() {
        _application = data;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _statusLabel(String status) {
    return AppStatus.applicationLabel(status);
  }

  Color _statusColor(String status) {
    return AppStatus.applicationColor(status);
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final application = _application;
    final announcement = application?.announcement;
    final brand = announcement?.user?.brandProfile?.name ?? 'Marque';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Détails candidature',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : application == null
          ? _notFound()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusHeader(application),
                    const SizedBox(height: 20),
                    _sectionTitle('Annonce'),
                    _infoCard(
                      Icons.campaign_outlined,
                      announcement?.title ??
                          'Annonce #${application.announcementId}',
                      onTap: () => context.push(
                        '/creator/announcement/${application.announcementId}',
                      ),
                    ),
                    _infoCard(Icons.business_outlined, brand),
                    if (announcement?.category != null)
                      _infoCard(
                        Icons.category_outlined,
                        announcement!.category!.name,
                      ),
                    _infoCard(
                      Icons.attach_money,
                      '${application.proposedBudget.toInt()} DA proposés',
                      color: AppColors.accent,
                    ),
                    _infoCard(
                      Icons.calendar_today_outlined,
                      'Envoyée le ${_formatDate(application.createdAt)}',
                    ),
                    if (announcement != null) ...[
                      const SizedBox(height: 20),
                      _sectionTitle('Budget annonce'),
                      _infoCard(
                        Icons.payments_outlined,
                        '${announcement.budgetMin.toInt()} - ${announcement.budgetMax.toInt()} DA',
                        color: AppColors.accent,
                      ),
                      _infoCard(
                        Icons.event_outlined,
                        'Deadline ${_formatDate(announcement.deadline)}',
                      ),
                      if ((announcement.platforms ?? []).isNotEmpty ||
                          (announcement.deliverables ?? []).isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _sectionTitle('Livrables requis'),
                        _requiredDeliverables(announcement),
                      ],
                    ],
                    const SizedBox(height: 20),
                    _sectionTitle('Votre message'),
                    _bodyCard(application.message),
                    if (announcement?.description != null) ...[
                      const SizedBox(height: 20),
                      _sectionTitle('Description annonce'),
                      _bodyCard(announcement!.description),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: application == null || _isLoading
          ? null
          : _actions(application),
    );
  }

  Widget _notFound() {
    return Center(
      child: Text(
        'Candidature introuvable',
        style: GoogleFonts.inter(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _statusHeader(Application application) {
    final color = _statusColor(application.status);
    final collaboration = application.collaboration;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(application.status),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            application.status == 'accepted' && collaboration != null
                ? 'Votre candidature a été acceptée. La collaboration est prête.'
                : application.status == 'rejected'
                ? "Cette candidature n'a pas été retenue."
                : 'Votre candidature est en attente de réponse.',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(Application application) {
    final collaboration = application.collaboration;
    final announcement = application.announcement;
    if (collaboration == null && announcement == null) {
      return const SizedBox.shrink();
    }

    final isCollaborationAction =
        application.status == 'accepted' && collaboration != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: isCollaborationAction
              ? ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/creator/collaboration/${collaboration.id}',
                  ),
                  icon: const Icon(Icons.work_outline, color: Colors.white),
                  label: Text(
                    'Ouvrir la collaboration',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/creator/announcement/${announcement!.id}'),
                  icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                  label: Text(
                    "Voir l'annonce",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _bodyCard(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
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
      return _bodyCard('Aucun livrable spécifique renseigné.');
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

  Widget _infoCard(
    IconData icon,
    String value, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }
}
