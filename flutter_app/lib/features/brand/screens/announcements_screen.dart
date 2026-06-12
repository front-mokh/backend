import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class BrandAnnouncementsScreen extends StatefulWidget {
  const BrandAnnouncementsScreen({super.key});

  @override
  State<BrandAnnouncementsScreen> createState() =>
      _BrandAnnouncementsScreenState();
}

class _BrandAnnouncementsScreenState extends State<BrandAnnouncementsScreen> {
  final _searchController = TextEditingController();
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService().getMyAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Announcement> get _filteredAnnouncements {
    final query = _searchController.text.trim().toLowerCase();
    return _announcements.where((announcement) {
      final status = _announcementStatus(announcement);
      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      final matchesSearch =
          query.isEmpty ||
          announcement.title.toLowerCase().contains(query) ||
          announcement.description.toLowerCase().contains(query) ||
          (announcement.category?.name.toLowerCase().contains(query) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Map<String, int> get _statusCounts {
    final counts = {
      'all': _announcements.length,
      'open': 0,
      'expired': 0,
      'closed': 0,
    };
    for (final announcement in _announcements) {
      final status = _announcementStatus(announcement);
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }

  String _announcementStatus(Announcement announcement) {
    final deadline = DateTime.tryParse(announcement.deadline);
    if (announcement.status == 'open' &&
        deadline != null &&
        deadline.isBefore(DateTime.now())) {
      return 'expired';
    }
    return announcement.status;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.success;
      case 'closed':
        return AppColors.error;
      case 'expired':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'closed':
        return 'Fermé';
      case 'expired':
        return 'Expiré';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push('/brand/create-announcement');
          if (created == true) {
            await _loadAnnouncements();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Nouvelle',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _announcements.isEmpty
                      ? _buildEmptyState()
                      : _filteredAnnouncements.isEmpty
                      ? _buildNoResultsState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadAnnouncements,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredAnnouncements.length,
                            itemBuilder: (context, index) =>
                                _buildAnnouncementCard(
                                  _filteredAnnouncements[index],
                                ),
                          ),
                        ),
                ),
              ],
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
              hintText: 'Rechercher une annonce',
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
                _filterChip('Toutes', 'all'),
                _filterChip('Ouvertes', 'open'),
                _filterChip('Expirées', 'expired'),
                _filterChip('Fermées', 'closed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    final count = _statusCounts[value] ?? 0;
    final color = value == 'all' ? AppColors.primary : _statusColor(value);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Text('$label $count'),
        onSelected: (_) => setState(() => _statusFilter = value),
        backgroundColor: AppColors.background,
        selectedColor: color,
        side: BorderSide(color: selected ? color : AppColors.border),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : color,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              Icons.campaign_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune annonce",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Créez votre première annonce pour commencer",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune annonce ne correspond aux filtres',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final status = _announcementStatus(announcement);
    return GestureDetector(
      onTap: () async {
        await context.push('/brand/announcement/${announcement.id}');
        if (mounted) await _loadAnnouncements();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
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
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.textTertiary,
                          size: 48,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _countPill(
                  'Total',
                  announcement.applicationsCount ?? 0,
                  AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                _countPill(
                  'Attente',
                  announcement.applicationsPendingCount ?? 0,
                  AppColors.warning,
                ),
                const SizedBox(width: 6),
                _countPill(
                  'Acceptées',
                  announcement.applicationsAcceptedCount ?? 0,
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (announcement.category != null) ...[
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    announcement.category!.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.attach_money, size: 14, color: AppColors.accent),
                Text(
                  '${announcement.budgetMin.toInt()} - ${announcement.budgetMax.toInt()} DA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$label $count',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
