import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../widgets/onboarding_exit_button.dart';

class BrandInfoScreen extends StatefulWidget {
  const BrandInfoScreen({super.key});

  @override
  State<BrandInfoScreen> createState() => _BrandInfoScreenState();
}

class _BrandInfoScreenState extends State<BrandInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  String? _logoPath;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingProvider>();
    _nameController.text = data.brandName;
    _phoneController.text = data.phone;
    _locationController.text = data.location;
    _descriptionController.text = data.description;
    _websiteController.text = data.website;
    _logoPath = data.logo.isNotEmpty ? data.logo : null;

    _nameController.addListener(_syncDraft);
    _phoneController.addListener(_syncDraft);
    _locationController.addListener(_syncDraft);
    _descriptionController.addListener(_syncDraft);
    _websiteController.addListener(_syncDraft);
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncDraft);
    _phoneController.removeListener(_syncDraft);
    _locationController.removeListener(_syncDraft);
    _descriptionController.removeListener(_syncDraft);
    _websiteController.removeListener(_syncDraft);
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    context.read<OnboardingProvider>().updateBrandInfo(
      brandName: _nameController.text,
      phone: _phoneController.text,
      location: _locationController.text,
      description: _descriptionController.text,
      website: _websiteController.text,
      logo: _logoPath ?? '',
    );

    if (_phoneError != null && mounted) {
      setState(() => _phoneError = null);
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    if (!mounted) return;
    setState(() => _logoPath = image.path);
    context.read<OnboardingProvider>().updateBrandInfo(logo: image.path);
  }

  void _next() {
    final onboarding = context.read<OnboardingProvider>();
    final brandName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();
    final phoneError = onboarding.validateBrandPhoneNumber(phone);
    if (phoneError != null) {
      setState(() => _phoneError = phoneError);
      return;
    }
    if (brandName.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom et la localisation sont requis'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    onboarding.updateBrandInfo(
      brandName: brandName,
      phone: phone,
      location: location,
      description: _descriptionController.text.trim(),
      website: _websiteController.text.trim(),
      logo: _logoPath ?? '',
    );
    onboarding.updateStep(2);
    context.push('/onboarding/brand/social');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Informations de la marque',
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
          children: [
            _buildProgressBar(1, 3),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickLogo,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLightest,
                    backgroundImage: _logoPath != null
                        ? FileImage(File(_logoPath!))
                        : null,
                    child: _logoPath == null
                        ? const Icon(
                            Icons.business,
                            size: 40,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildField(
              'Nom de la marque *',
              'Votre marque',
              _nameController,
              Icons.business_outlined,
            ),
            _buildField(
              'Téléphone *',
              '0212345678',
              _phoneController,
              Icons.phone_outlined,
              keyboard: TextInputType.phone,
              error: _phoneError,
            ),
            _buildField(
              'Localisation *',
              'Alger, Algérie',
              _locationController,
              Icons.location_on_outlined,
            ),
            _buildField(
              'Site web',
              'https://votremarque.com',
              _websiteController,
              Icons.language_outlined,
              keyboard: TextInputType.url,
            ),
            _buildField(
              'Description',
              'Décrivez votre marque...',
              _descriptionController,
              Icons.info_outline,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
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

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
              errorText: error,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
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
          ),
        ],
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
