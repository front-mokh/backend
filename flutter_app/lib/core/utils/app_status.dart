import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppStatus {
  AppStatus._();

  static String announcementLabel(String status) {
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

  static Color announcementColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.success;
      case 'closed':
        return AppColors.error;
      case 'expired':
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.textTertiary;
    }
  }

  static String applicationLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'withdrawn':
        return 'Retirée';
      case 'pending':
      default:
        return 'En attente';
    }
  }

  static Color applicationColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
      case 'withdrawn':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  static String collaborationLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      case 'active':
      case 'in_progress':
        return 'En cours';
      default:
        return status;
    }
  }

  static Color collaborationColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'active':
        return AppColors.info;
      case 'in_progress':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  static String submissionLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Refusé';
      case 'submitted':
        return 'Soumis';
      case 'pending':
      default:
        return 'En attente';
    }
  }

  static Color submissionColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'submitted':
        return AppColors.info;
      case 'pending':
      default:
        return AppColors.primary;
    }
  }
}
