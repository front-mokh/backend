import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class CreatorAnnouncementsScreen extends StatefulWidget {
  const CreatorAnnouncementsScreen({super.key});

  @override
  State<CreatorAnnouncementsScreen> createState() => _State();
}

class _State extends State<CreatorAnnouncementsScreen> {
  final _searchController = TextEditingController();
  List<Announcement> _announcements = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService().getOpenAnnouncements(),
        ApiService().getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _announcements = results[0] as List<Announcement>;
          _categories = results[1] as List<Category>;
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
      final matchesCategory =
          _selectedCategoryId == null ||
          announcement.category?.id == _selectedCategoryId;
      final matchesSearch =
          query.isEmpty ||
          announcement.title.toLowerCase().contains(query) ||
          announcement.description.toLowerCase().contains(query) ||
          (announcement.category?.name.toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Map<int?, int> get _categoryCounts {
    final counts = <int?, int>{null: _announcements.length};
    for (final category in _categories) {
      counts[category.id] = _announcements
          .where((announcement) => announcement.category?.id == category.id)
          .length;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _announcements.isEmpty
                      ? _emptyState(
                          'Aucune annonce disponible',
                          'Revenez plus tard pour de nouvelles opportunités',
                        )
                      : _filteredAnnouncements.isEmpty
                      ? _emptyState(
                          'Aucun résultat',
                          'Aucune annonce ne correspond aux filtres',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredAnnouncements.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_filteredAnnouncements[i]),
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
                _categoryChip('Toutes', null),
                ..._categories.map(
                  (category) => _categoryChip(category.name, category.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, int? categoryId) {
    final selected = _selectedCategoryId == categoryId;
    final count = _categoryCounts[categoryId] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Text('$label $count'),
        onSelected: (_) => setState(() => _selectedCategoryId = categoryId),
        backgroundColor: AppColors.background,
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

  Widget _emptyState(String title, String message) {
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
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
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

  Widget _buildCard(Announcement a) {
    return GestureDetector(
      onTap: () => context.push('/creator/announcement/${a.id}'),
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
              child: a.thumbnail != null
                  ? CachedNetworkImage(
                      imageUrl: a.thumbnail!,
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
            Text(
              a.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              a.description,
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
                if (a.category != null) ...[
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    a.category!.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.attach_money, size: 14, color: AppColors.accent),
                Text(
                  '${a.budgetMin.toInt()} - ${a.budgetMax.toInt()} DA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  a.deadline.length >= 10
                      ? a.deadline.substring(0, 10)
                      : a.deadline,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
