import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/social_utils.dart';
import '../../widgets/onboarding_exit_button.dart';

class BrandSocialScreen extends StatefulWidget {
  const BrandSocialScreen({super.key});

  @override
  State<BrandSocialScreen> createState() => _BrandSocialScreenState();
}

class _BrandSocialScreenState extends State<BrandSocialScreen> {
  final _linkController = TextEditingController();
  late List<OnboardingSocialLink> _links;

  @override
  void initState() {
    super.initState();
    _links = List.from(context.read<OnboardingProvider>().links);
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  void _addLink() {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _links.add(
        OnboardingSocialLink(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: url,
        ),
      );
      _linkController.clear();
    });
    _syncLinks();
  }

  void _removeLink(int index) {
    setState(() => _links.removeAt(index));
    _syncLinks();
  }

  void _syncLinks() {
    context.read<OnboardingProvider>().setLinks(_links);
  }

  void _next() {
    if (_links.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins un lien social'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final onboarding = context.read<OnboardingProvider>();
    onboarding.links = _links;
    onboarding.updateStep(3);
    context.push('/onboarding/brand/industries');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Liens sociaux',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: const [OnboardingExitButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(2, 3),
            const SizedBox(height: 24),
            Text(
              'Ajoutez vos liens sociaux',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez les profils de votre marque',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _linkController,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: 'https://instagram.com/...',
                      prefixIcon: const Icon(
                        Icons.link,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _addLink(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addLink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._links.asMap().entries.map((entry) {
              final link = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      getSocialIcon(link.url),
                      size: 22,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getSocialPlatformName(link.url),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            link.url,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.error,
                      ),
                      onPressed: () => _removeLink(entry.key),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Suivant',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Row(
      children: List.generate(
        total,
        (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: i < current ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
