import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/social_utils.dart';

class BrandApplicationDetailsScreen extends StatefulWidget {
  final int id;
  const BrandApplicationDetailsScreen({super.key, required this.id});

  @override
  State<BrandApplicationDetailsScreen> createState() =>
      _BrandApplicationDetailsScreenState();
}

class _BrandApplicationDetailsScreenState
    extends State<BrandApplicationDetailsScreen> {
  Application? _application;
  bool _isLoading = true;
  bool _isUpdating = false;

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

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      if (status == 'accepted') {
        await ApiService().acceptApplication(widget.id);
      } else {
        await ApiService().rejectApplication(widget.id);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Candidature acceptée'
                : 'Candidature refusée',
          ),
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
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'withdrawn':
        return 'Retirée';
      default:
        return 'En attente';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
      case 'withdrawn':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _creatorName(User? user) {
    final profile = user?.creatorProfile;
    final name = profile?.fullName.trim() ?? '';
    return name.isEmpty ? 'Créateur' : name;
  }

  String _initials(User? user) {
    final profile = user?.creatorProfile;
    final first = profile?.firstName.trim() ?? '';
    final last = profile?.lastName.trim() ?? '';
    final value =
        '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}';
    return value.isEmpty ? 'C' : value.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final application = _application;

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
                    _creatorHeader(application),
                    const SizedBox(height: 16),
                    _statusPanel(application),
                    const SizedBox(height: 20),
                    _sectionTitle('Message'),
                    _bodyCard(application.message),
                    const SizedBox(height: 20),
                    _sectionTitle('Annonce'),
                    _infoCard(
                      Icons.campaign_outlined,
                      application.announcement?.title ??
                          'Annonce #${application.announcementId}',
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
                    _creatorProfile(application.user),
                  ],
                ),
              ),
            ),
      bottomNavigationBar:
          application == null || _isLoading || !_hasActions(application)
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

  Widget _creatorHeader(Application application) {
    final user = application.user;
    final profile = user?.creatorProfile;
    final image = profile?.profilePicture;
    final name = _creatorName(user);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryLightest,
            backgroundImage: image != null && image.isNotEmpty
                ? CachedNetworkImageProvider(image)
                : null,
            child: image == null || image.isEmpty
                ? Text(
                    _initials(user),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                if (profile?.nickname != null &&
                    profile!.nickname!.trim().isNotEmpty)
                  Text(
                    '@${profile.nickname}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 8),
                _statusBadge(application.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPanel(Application application) {
    final collaboration = application.collaboration;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor(application.status).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusColor(application.status).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            application.status == 'accepted'
                ? Icons.check_circle_outline
                : application.status == 'rejected'
                ? Icons.cancel_outlined
                : Icons.hourglass_top_outlined,
            color: _statusColor(application.status),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              application.status == 'accepted' && collaboration != null
                  ? 'Une collaboration est ouverte pour cette candidature.'
                  : _statusLabel(application.status),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _statusColor(application.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creatorProfile(User? user) {
    final profile = user?.creatorProfile;
    final categories = user?.categories ?? const <Category>[];
    final socialLinks = user?.socialLinks ?? const <SocialLink>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile?.bio != null && profile!.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Bio'),
          _bodyCard(profile.bio!),
        ],
        if (profile?.phone != null && profile!.phone.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Contact'),
          _infoCard(Icons.phone_outlined, profile.phone),
        ],
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Catégories'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  category.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (socialLinks.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Liens sociaux'),
          ...socialLinks.map(_socialLinkCard),
        ],
      ],
    );
  }

  bool _hasActions(Application application) {
    return (application.status == 'accepted' &&
            application.collaboration != null) ||
        application.status == 'pending';
  }

  Widget _actions(Application application) {
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
        child:
            application.status == 'accepted' &&
                application.collaboration != null
            ? SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/brand/collaboration/${application.collaboration!.id}',
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
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpdating
                          ? null
                          : () => _updateStatus('rejected'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Refuser',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating
                          ? null
                          : () => _updateStatus('accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Accepter',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
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

  Widget _infoCard(IconData icon, String value, {Color? color}) {
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
        ],
      ),
    );
  }

  Widget _socialLinkCard(SocialLink link) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(getSocialIcon(link.url), size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                getSocialPlatformName(link.url),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
