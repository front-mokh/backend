import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../widgets/onboarding_exit_button.dart';

class CreatorInfoScreen extends StatefulWidget {
  const CreatorInfoScreen({super.key});

  @override
  State<CreatorInfoScreen> createState() => _CreatorInfoScreenState();
}

class _CreatorInfoScreenState extends State<CreatorInfoScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  String? _profilePicturePath;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingProvider>();
    _firstNameController.text = data.firstName;
    _lastNameController.text = data.lastName;
    _nicknameController.text = data.nickname;
    _phoneController.text = data.phone;
    _bioController.text = data.bio;
    _profilePicturePath = data.profilePicture.isNotEmpty
        ? data.profilePicture
        : null;

    _firstNameController.addListener(_syncDraft);
    _lastNameController.addListener(_syncDraft);
    _nicknameController.addListener(_syncDraft);
    _phoneController.addListener(_syncDraft);
    _bioController.addListener(_syncDraft);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_syncDraft);
    _lastNameController.removeListener(_syncDraft);
    _nicknameController.removeListener(_syncDraft);
    _phoneController.removeListener(_syncDraft);
    _bioController.removeListener(_syncDraft);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    context.read<OnboardingProvider>().updateCreatorInfo(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      nickname: _nicknameController.text,
      phone: _phoneController.text,
      bio: _bioController.text,
      profilePicture: _profilePicturePath ?? '',
    );

    if (_phoneError != null && mounted) {
      setState(() => _phoneError = null);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      if (!mounted) return;
      setState(() => _profilePicturePath = image.path);
      context.read<OnboardingProvider>().updateCreatorInfo(
        profilePicture: image.path,
      );
    }
  }

  void _next() {
    final onboarding = context.read<OnboardingProvider>();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final phoneError = onboarding.validatePhoneNumber(phone);
    if (phoneError != null) {
      setState(() => _phoneError = phoneError);
      return;
    }
    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le prénom et le nom sont requis'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    onboarding.updateCreatorInfo(
      firstName: firstName,
      lastName: lastName,
      nickname: _nicknameController.text.trim(),
      phone: phone,
      bio: _bioController.text.trim(),
      profilePicture: _profilePicturePath ?? '',
    );
    onboarding.updateStep(2);

    context.push('/onboarding/creator/social');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Informations personnelles',
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
            // Progress indicator
            _buildProgressBar(1, 3),
            const SizedBox(height: 24),

            // Profile picture
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLightest,
                    backgroundImage: _profilePicturePath != null
                        ? FileImage(File(_profilePicturePath!))
                        : null,
                    child: _profilePicturePath == null
                        ? const Icon(
                            Icons.person,
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

            // Form fields
            _buildField(
              'Prénom *',
              'Votre prénom',
              _firstNameController,
              Icons.person_outline,
            ),
            _buildField(
              'Nom *',
              'Votre nom',
              _lastNameController,
              Icons.person_outline,
            ),
            _buildField(
              'Pseudo',
              'Votre pseudo (optionnel)',
              _nicknameController,
              Icons.alternate_email,
            ),
            _buildField(
              'Téléphone *',
              '0612345678',
              _phoneController,
              Icons.phone_outlined,
              keyboard: TextInputType.phone,
              error: _phoneError,
            ),
            _buildField(
              'Bio',
              'Parlez de vous...',
              _bioController,
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
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: i < current ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
