import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../widgets/onboarding_exit_button.dart';

class BrandIndustriesScreen extends StatefulWidget {
  const BrandIndustriesScreen({super.key});

  @override
  State<BrandIndustriesScreen> createState() => _BrandIndustriesScreenState();
}

class _BrandIndustriesScreenState extends State<BrandIndustriesScreen> {
  List<Industry> _industries = [];
  Set<int> _selected = {};
  bool _isLoadingIndustries = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selected = context.read<OnboardingProvider>().industries.toSet();
    _loadIndustries();
  }

  Future<void> _loadIndustries() async {
    try {
      final industries = await ApiService().getIndustries();
      if (mounted) {
        setState(() {
          _industries = industries;
          _isLoadingIndustries = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingIndustries = false);
    }
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un secteur'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final onboarding = context.read<OnboardingProvider>();
    onboarding.industries = _selected.toList();

    try {
      await ApiService().storeBrandProfile(
        name: onboarding.brandName,
        phone: onboarding.phone,
        location: onboarding.location,
        description: onboarding.description.isNotEmpty
            ? onboarding.description
            : null,
        website: onboarding.website.isNotEmpty ? onboarding.website : null,
        logoPath: onboarding.logo.isNotEmpty ? onboarding.logo : null,
        links: onboarding.links.map((l) => l.url).toList(),
        industries: _selected.toList(),
      );

      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      onboarding.resetData();
      context.go('/onboarding/success');
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.errorMessage(e)),
          backgroundColor: AppColors.error,
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleIndustry(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    context.read<OnboardingProvider>().setIndustries(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Secteurs',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: const [OnboardingExitButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(3, 3),
            const SizedBox(height: 24),
            Text(
              "Choisissez vos secteurs d'activité",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les industries pertinentes pour votre marque',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoadingIndustries
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _industries.map((ind) {
                        final isSelected = _selected.contains(ind.id);
                        return GestureDetector(
                          onTap: () => _toggleIndustry(ind.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              ind.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.text,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Terminer',
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
