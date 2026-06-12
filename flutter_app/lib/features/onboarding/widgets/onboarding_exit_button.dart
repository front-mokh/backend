import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingExitButton extends StatelessWidget {
  const OnboardingExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Se deconnecter',
      icon: const Icon(Icons.logout_outlined, color: AppColors.textSecondary),
      onPressed: () => _confirmLogout(context),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitter la configuration ?'),
        content: const Text(
          'Vous devrez terminer votre profil avant d\'utiliser l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se deconnecter'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    context.read<OnboardingProvider>().resetData();
    await context.read<AuthProvider>().logout();
  }
}
