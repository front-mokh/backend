import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/social_utils.dart';
import '../../../core/widgets/app_state_widgets.dart';

class BrandCreatorsScreen extends StatefulWidget {
  const BrandCreatorsScreen({super.key});

  @override
  State<BrandCreatorsScreen> createState() => _BrandCreatorsScreenState();
}

class _BrandCreatorsScreenState extends State<BrandCreatorsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<User> _creators = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService().getCategories(),
        ApiService().getCreators(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Category>;
        _creators = results[1] as List<User>;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ApiService.messageFromError(e);
        });
      }
    }
  }

  Future<void> _loadCreators({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final creators = await ApiService().getCreators(
        search: _searchController.text,
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      setState(() {
        _creators = creators;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ApiService.messageFromError(e);
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadCreators(),
    );
  }

  void _selectCategory(int? id) {
    setState(() => _selectedCategoryId = id);
    _loadCreators(showLoading: true);
  }

  String _creatorName(User creator) {
    final profile = creator.creatorProfile;
    final name = profile?.fullName.trim() ?? '';
    return name.isEmpty ? 'Créateur' : name;
  }

  String _initials(User creator) {
    final profile = creator.creatorProfile;
    final first = profile?.firstName.trim() ?? '';
    final last = profile?.lastName.trim() ?? '';
    final value =
        '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}';
    return value.isEmpty ? 'C' : value.toUpperCase();
  }

  String _valueOr(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _ratingText(double rating) {
    return rating == rating.roundToDouble()
        ? rating.toStringAsFixed(0)
        : rating.toStringAsFixed(1);
  }

  Widget _reputationPills(ReputationSummary summary) {
    final average = summary.averageRating;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _metricPill(
          average == null ? Icons.star_border_rounded : Icons.star_rounded,
          average == null
              ? 'Nouveau'
              : '${_ratingText(average)} (${summary.reviewsCount})',
          AppColors.warning,
        ),
        if (summary.completedCollaborationsCount > 0)
          _metricPill(
            Icons.task_alt_rounded,
            '${summary.completedCollaborationsCount} terminé${summary.completedCollaborationsCount > 1 ? 's' : ''}',
            AppColors.success,
          ),
        if (summary.reliabilityScore > 0)
          _metricPill(
            Icons.workspace_premium_outlined,
            'Score ${summary.reliabilityScore}',
            AppColors.primary,
          ),
      ],
    );
  }

  Widget _metricPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reputationPanel(ReputationSummary summary) {
    final average = summary.averageRating;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                average == null
                    ? Icons.star_border_rounded
                    : Icons.star_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  average == null
                      ? 'Pas encore évalué'
                      : '${_ratingText(average)} / 5 sur ${summary.reviewsCount} avis',
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
          _reputationPills(summary),
          if (summary.wouldWorkAgainRate != null) ...[
            const SizedBox(height: 10),
            Text(
              '${summary.wouldWorkAgainRate}% des clients souhaitent retravailler avec ce profil.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Rechercher un créateur',
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
                          _loadCreators(showLoading: true);
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
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
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('Tous', null),
                ..._categories.map((category) {
                  return _filterChip(category.name, category.id);
                }),
              ],
            ),
          ),
          Expanded(
            child: _isLoading ? const AppLoadingState() : _buildBodyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyState() {
    if (_errorMessage != null && _creators.isEmpty) {
      return AppRefreshableState(
        onRefresh: _loadInitialData,
        child: AppErrorState(
          message: _errorMessage!,
          onRetry: () => _loadInitialData(),
        ),
      );
    }

    if (_creators.isEmpty) {
      return AppRefreshableState(
        onRefresh: () => _loadCreators(),
        child: _emptyState(),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadCreators(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _creators.length,
        itemBuilder: (context, index) => _creatorCard(_creators[index]),
      ),
    );
  }

  Widget _filterChip(String label, int? id) {
    final selected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Text(label),
        onSelected: (_) => _selectCategory(id),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.text,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLightest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun créateur trouvé',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre recherche',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _creatorCard(User creator) {
    final profile = creator.creatorProfile;
    final categories = creator.categories ?? const <Category>[];
    final image = profile?.profilePicture;
    final name = _creatorName(creator);
    final nickname = profile?.nickname?.trim();
    final reputation = creator.reputationSummary;

    return InkWell(
      onTap: () => _showCreatorDetails(creator),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLightest,
              backgroundImage: image != null && image.isNotEmpty
                  ? CachedNetworkImageProvider(image)
                  : null,
              child: image == null || image.isEmpty
                  ? Text(
                      _initials(creator),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (nickname != null && nickname.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@$nickname',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (reputation != null) ...[
                    const SizedBox(height: 8),
                    _reputationPills(reputation),
                  ],
                  const SizedBox(height: 10),
                  if (categories.isEmpty)
                    Text(
                      'Catégorie non renseignée',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: categories.take(3).map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLightest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatorDetails(User creator) {
    final profile = creator.creatorProfile;
    final socialLinks = creator.socialLinks ?? const <SocialLink>[];
    final categories = creator.categories ?? const <Category>[];
    final reputation = creator.reputationSummary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primaryLightest,
                      backgroundImage:
                          profile?.profilePicture != null &&
                              profile!.profilePicture!.isNotEmpty
                          ? CachedNetworkImageProvider(profile.profilePicture!)
                          : null,
                      child:
                          profile?.profilePicture == null ||
                              profile!.profilePicture!.isEmpty
                          ? Text(
                              _initials(creator),
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
                            _creatorName(creator),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          if (profile?.nickname != null &&
                              profile!.nickname!.trim().isNotEmpty)
                            Text(
                              '@${profile.nickname}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            creator.email,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (reputation != null) ...[
                  _reputationPanel(reputation),
                  const SizedBox(height: 18),
                ],
                _detailRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  _valueOr(profile?.phone, 'Non renseigné'),
                ),
                if (profile?.bio != null && profile!.bio!.trim().isNotEmpty)
                  _sectionText('Bio', profile.bio!),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 18),
                  _sectionTitle('Liens sociaux'),
                  ...socialLinks.map(_socialLinkTile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _sectionText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialLinkTile(SocialLink link) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
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
