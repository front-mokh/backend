import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class CreatorApplicationsScreen extends StatefulWidget {
  const CreatorApplicationsScreen({super.key});

  @override
  State<CreatorApplicationsScreen> createState() => _State();
}

class _State extends State<CreatorApplicationsScreen> {
  final _searchController = TextEditingController();
  List<Application> _applications = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

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
      final data = await ApiService().getMyApplications();
      if (mounted) {
        setState(() {
          _applications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Application> get _filteredApplications {
    final query = _searchController.text.trim().toLowerCase();
    return _applications.where((application) {
      final matchesStatus =
          _statusFilter == 'all' || application.status == _statusFilter;
      final matchesSearch =
          query.isEmpty ||
          application.message.toLowerCase().contains(query) ||
          (application.announcement?.title.toLowerCase().contains(query) ??
              false) ||
          (application.announcement?.category?.name.toLowerCase().contains(
                query,
              ) ??
              false);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Map<String, int> get _statusCounts {
    final counts = {
      'all': _applications.length,
      'pending': 0,
      'accepted': 0,
      'rejected': 0,
    };
    for (final application in _applications) {
      if (counts.containsKey(application.status)) {
        counts[application.status] = counts[application.status]! + 1;
      }
    }
    return counts;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      default:
        return s;
    }
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
                  child: _applications.isEmpty
                      ? _emptyState(
                          'Aucune candidature',
                          'Postulez aux annonces pour commencer',
                        )
                      : _filteredApplications.isEmpty
                      ? _emptyState(
                          'Aucun résultat',
                          'Aucune candidature ne correspond aux filtres',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredApplications.length,
                            itemBuilder: (_, i) =>
                                _applicationCard(_filteredApplications[i]),
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
              hintText: 'Rechercher dans mes candidatures',
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
                _filterChip('Attente', 'pending'),
                _filterChip('Acceptées', 'accepted'),
                _filterChip('Refusées', 'rejected'),
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
              Icons.description_outlined,
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

  Widget _applicationCard(Application app) {
    return GestureDetector(
      onTap: () async {
        await context.push('/creator/application/${app.id}');
        if (mounted) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    app.announcement?.title ?? 'Annonce #${app.announcementId}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
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
                    color: _statusColor(app.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(app.status),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(app.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              app.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: AppColors.accent),
                Text(
                  '${app.proposedBudget.toInt()} DA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
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
