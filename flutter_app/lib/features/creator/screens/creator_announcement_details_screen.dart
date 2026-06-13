import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_status.dart';
import '../../../core/widgets/attachment_preview.dart';

class CreatorAnnouncementDetailsScreen extends StatefulWidget {
  final int id;
  const CreatorAnnouncementDetailsScreen({super.key, required this.id});

  @override
  State<CreatorAnnouncementDetailsScreen> createState() => _State();
}

class _State extends State<CreatorAnnouncementDetailsScreen> {
  Announcement? _announcement;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService().getAnnouncement(widget.id);
      if (mounted) {
        setState(() {
          _announcement = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcement = _announcement;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          "Détails de l'annonce",
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : announcement == null
          ? _emptyState()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: SafeArea(
                top: false,
                bottom: false,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _hero(announcement),
                    const SizedBox(height: 16),
                    _overviewGrid(announcement),
                    const SizedBox(height: 16),
                    _section(
                      title: 'Brief',
                      icon: Icons.description_outlined,
                      child: _paragraph(announcement.description),
                    ),
                    if (_hasValue(announcement.requirements)) ...[
                      const SizedBox(height: 12),
                      _section(
                        title: 'Exigences',
                        icon: Icons.fact_check_outlined,
                        child: _paragraph(announcement.requirements!),
                      ),
                    ],
                    if (_hasValue(announcement.targetAudience) ||
                        announcement.minFollowers != null ||
                        announcement.influencerTier != null) ...[
                      const SizedBox(height: 12),
                      _section(
                        title: 'Audience recherchée',
                        icon: Icons.groups_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_hasValue(announcement.targetAudience))
                              _detailLine(
                                'Cible',
                                announcement.targetAudience!,
                                Icons.person_search_outlined,
                              ),
                            if (announcement.influencerTier != null)
                              _detailLine(
                                'Niveau',
                                announcement.influencerTier!.name,
                                Icons.workspace_premium_outlined,
                              ),
                            if (announcement.minFollowers != null)
                              _detailLine(
                                'Abonnés minimum',
                                '${announcement.minFollowers}',
                                Icons.trending_up_outlined,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if ((announcement.platforms ?? []).isNotEmpty ||
                        (announcement.deliverables ?? []).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _section(
                        title: 'Livrables par plateforme',
                        icon: Icons.inventory_2_outlined,
                        child: _deliverablesByPlatform(announcement),
                      ),
                    ],
                    if (_hasValue(announcement.attachment)) ...[
                      const SizedBox(height: 12),
                      _attachment(announcement.attachment!),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: announcement == null || _isLoading
          ? null
          : _actionBar(announcement),
    );
  }

  Widget _hero(Announcement announcement) {
    final brandName = announcement.user?.brandProfile?.name;
    final alreadyApplied = announcement.currentUserApplication != null;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: announcement.thumbnail != null
                ? CachedNetworkImage(
                    imageUrl: announcement.thumbnail!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    errorWidget: (context, url, error) => _imageFallback(),
                  )
                : _imageFallback(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip(
                      _statusLabel(announcement),
                      _statusColor(announcement),
                    ),
                    if (alreadyApplied)
                      _statusChip('Candidature envoyée', AppColors.success),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement.title,
                  style: GoogleFonts.inter(
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                if (_hasValue(brandName)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          brandName!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: const Icon(
        Icons.campaign_outlined,
        color: AppColors.primary,
        size: 52,
      ),
    );
  }

  Widget _overviewGrid(Announcement announcement) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metric(
              width: itemWidth,
              icon: Icons.payments_outlined,
              label: 'Budget',
              value:
                  '${announcement.budgetMin.toInt()} - ${announcement.budgetMax.toInt()} DA',
              color: AppColors.accent,
            ),
            _metric(
              width: itemWidth,
              icon: Icons.event_available_outlined,
              label: 'Deadline',
              value: _formatDate(announcement.deadline),
              color: AppColors.info,
            ),
            _metric(
              width: itemWidth,
              icon: Icons.category_outlined,
              label: 'Catégorie',
              value: announcement.category?.name ?? 'Non renseignée',
              color: AppColors.primary,
            ),
            _metric(
              width: itemWidth,
              icon: Icons.assignment_outlined,
              label: 'Candidatures',
              value: '${announcement.applicationsCount ?? 0}',
              color: AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _metric({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: width,
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        height: 1.55,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _detailLine(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
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

  Widget _deliverablesByPlatform(Announcement announcement) {
    final platforms = announcement.platforms ?? const <PlatformModel>[];
    final deliverables =
        announcement.deliverables ?? const <DeliverableWithPivot>[];

    if (deliverables.isEmpty && platforms.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: platforms.map((platform) => _chip(platform.name)).toList(),
      );
    }

    if (platforms.isEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: deliverables
            .map(
              (deliverable) => _chip(
                '${deliverable.quantity} x ${deliverable.name}',
                color: AppColors.accentLight,
                textColor: AppColors.text,
              ),
            )
            .toList(),
      );
    }

    final children = <Widget>[];
    for (final platform in platforms) {
      final platformDeliverables = deliverables
          .where((deliverable) => deliverable.platformId == platform.id)
          .toList();
      children.add(
        _platformDeliverablesBlock(platform.name, platformDeliverables),
      );
    }

    final orphanDeliverables = deliverables
        .where(
          (deliverable) => !platforms.any(
            (platform) => platform.id == deliverable.platformId,
          ),
        )
        .toList();
    if (orphanDeliverables.isNotEmpty) {
      children.add(_platformDeliverablesBlock('Autres', orphanDeliverables));
    }

    return Column(children: children);
  }

  Widget _platformDeliverablesBlock(
    String platformName,
    List<DeliverableWithPivot> deliverables,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  platformName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (deliverables.isEmpty)
            Text(
              'Aucun livrable spécifique demandé',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: deliverables
                  .map(
                    (deliverable) => _chip(
                      '${deliverable.quantity} x ${deliverable.name}',
                      color: AppColors.surface,
                      textColor: AppColors.text,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    String label, {
    Color color = AppColors.primaryLightest,
    Color textColor = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _attachment(String url) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        child: AppAttachmentPreview(source: url, imageHeight: 160),
      ),
    );
  }

  Widget _actionBar(Announcement announcement) {
    final currentApplication = announcement.currentUserApplication;
    final unavailable = _isUnavailable(announcement);

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
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: currentApplication != null
                ? () => context.push(
                    '/creator/application/${currentApplication.id}',
                  )
                : unavailable
                ? null
                : () async {
                    final applied = await context.push<bool>(
                      '/creator/apply/${widget.id}',
                    );
                    if (applied == true) {
                      await _load();
                    }
                  },
            icon: Icon(
              currentApplication != null
                  ? Icons.assignment_turned_in_outlined
                  : unavailable
                  ? Icons.lock_outline
                  : Icons.send_outlined,
              size: 20,
            ),
            label: Text(
              currentApplication != null
                  ? 'Voir ma candidature'
                  : unavailable
                  ? 'Candidatures fermées'
                  : 'Postuler à cette annonce',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentApplication != null
                  ? AppColors.success
                  : AppColors.primary,
              disabledBackgroundColor: AppColors.disabled,
              disabledForegroundColor: AppColors.textTertiary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primaryLightest,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Annonce introuvable',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Cette annonce n'est plus disponible.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  bool _isUnavailable(Announcement announcement) {
    return announcement.status != 'open' || _isExpired(announcement.deadline);
  }

  bool _isExpired(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    final deadline = DateUtils.dateOnly(parsed.toLocal());
    final today = DateUtils.dateOnly(DateTime.now());
    return deadline.isBefore(today);
  }

  String _effectiveStatus(Announcement announcement) {
    if (announcement.status != 'open') return 'closed';
    if (_isExpired(announcement.deadline)) return 'expired';
    return 'open';
  }

  String _statusLabel(Announcement announcement) {
    return AppStatus.announcementLabel(_effectiveStatus(announcement));
  }

  Color _statusColor(Announcement announcement) {
    return AppStatus.announcementColor(_effectiveStatus(announcement));
  }

  String _formatDate(String value) {
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }
}
