import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class CollaborationReviewSection extends StatefulWidget {
  final Collaboration collaboration;
  final String reviewedName;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const CollaborationReviewSection({
    super.key,
    required this.collaboration,
    required this.reviewedName,
    required this.onSubmit,
  });

  @override
  State<CollaborationReviewSection> createState() =>
      _CollaborationReviewSectionState();
}

class _CollaborationReviewSectionState
    extends State<CollaborationReviewSection> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.collaboration.currentUserReview;
    final otherReviews =
        (widget.collaboration.reviews ?? const <CollaborationReview>[])
            .where((item) => item.id != review?.id)
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          review == null ? _reviewPrompt() : _submittedReview(review),
          if (otherReviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            _publicReviews(otherReviews),
          ],
        ],
      ),
    );
  }

  Widget _reviewPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star_border_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évaluer la collaboration',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Votre avis aide à construire un classement fiable.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _openReviewSheet,
            icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
            label: Text(
              'Laisser un avis',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _submittedReview(CollaborationReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_outlined, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Votre avis',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            _stars(review.rating, size: 18),
          ],
        ),
        if (review.publicComment != null &&
            review.publicComment!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            review.publicComment!,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (review.status == 'hidden') ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Cet avis n'est pas visible publiquement.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (review.wouldWorkAgain != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                review.wouldWorkAgain!
                    ? Icons.handshake_outlined
                    : Icons.do_not_disturb_on_outlined,
                size: 17,
                color: review.wouldWorkAgain!
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.wouldWorkAgain!
                      ? 'Prêt à retravailler ensemble'
                      : 'Ne souhaite pas retravailler ensemble',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _publicReviews(List<CollaborationReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.border.withValues(alpha: 0.7)),
        const SizedBox(height: 8),
        Text(
          'Avis publiés',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        ...reviews.map(_publicReviewItem),
      ],
    );
  }

  Widget _publicReviewItem(CollaborationReview review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _reviewerName(review),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              _stars(review.rating, size: 16),
            ],
          ),
          if (review.publicComment != null &&
              review.publicComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.publicComment!,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _reviewerName(CollaborationReview review) {
    final user = review.reviewer;
    if (user == null) {
      return review.reviewerRole == 'brand' ? 'Marque' : 'Créateur';
    }
    if (user.isBrand) {
      final name = user.brandProfile?.name.trim() ?? '';
      return name.isEmpty ? 'Marque' : name;
    }
    final creatorName = user.creatorProfile?.fullName.trim() ?? '';
    return creatorName.isEmpty ? 'Créateur' : creatorName;
  }

  Future<void> _openReviewSheet() async {
    var rating = 0;
    var communicationRating = 0;
    var qualityRating = 0;
    var reliabilityRating = 0;
    var professionalismRating = 0;
    var wouldWorkAgain = true;
    final commentController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (rating == 0 || _isSubmitting) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(this.context);

              setState(() => _isSubmitting = true);
              setSheetState(() {});

              final payload = <String, dynamic>{'rating': rating};
              void addRating(String key, int value) {
                if (value > 0) payload[key] = value;
              }

              addRating('communication_rating', communicationRating);
              addRating('quality_rating', qualityRating);
              addRating('reliability_rating', reliabilityRating);
              addRating('professionalism_rating', professionalismRating);
              payload['would_work_again'] = wouldWorkAgain;

              final comment = commentController.text.trim();
              if (comment.isNotEmpty) payload['public_comment'] = comment;

              try {
                await widget.onSubmit(payload);
                if (!mounted) return;
                setState(() => _isSubmitting = false);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Avis enregistré'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ApiService.messageFromError(e)),
                    backgroundColor: AppColors.error,
                  ),
                );
                setState(() => _isSubmitting = false);
                setSheetState(() {});
              }
            }

            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return PopScope(
              canPop: !_isSubmitting,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.textSecondary,
                            tooltip: 'Fermer',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Avis sur ${widget.reviewedName}',
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notez votre expérience après cette collaboration.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ratingRow(
                        label: 'Note globale',
                        value: rating,
                        isRequired: true,
                        onChanged: (value) =>
                            setSheetState(() => rating = value),
                      ),
                      const SizedBox(height: 12),
                      _ratingRow(
                        label: 'Communication',
                        value: communicationRating,
                        onChanged: (value) =>
                            setSheetState(() => communicationRating = value),
                      ),
                      _ratingRow(
                        label: 'Qualité',
                        value: qualityRating,
                        onChanged: (value) =>
                            setSheetState(() => qualityRating = value),
                      ),
                      _ratingRow(
                        label: 'Fiabilité',
                        value: reliabilityRating,
                        onChanged: (value) =>
                            setSheetState(() => reliabilityRating = value),
                      ),
                      _ratingRow(
                        label: 'Professionnalisme',
                        value: professionalismRating,
                        onChanged: (value) =>
                            setSheetState(() => professionalismRating = value),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: wouldWorkAgain,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(
                          alpha: 0.32,
                        ),
                        onChanged: (value) =>
                            setSheetState(() => wouldWorkAgain = value),
                        title: Text(
                          'Je retravaillerais avec ce profil',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: 'Commentaire public',
                          hintText: 'Décrivez ce qui s’est bien passé...',
                          labelStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                          ),
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.placeholder,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: rating == 0 || _isSubmitting
                              ? null
                              : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Publier l’avis',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    commentController.dispose();
  }

  Widget _ratingRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isRequired ? '$label *' : label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          _interactiveStars(value, onChanged),
        ],
      ),
    );
  }

  Widget _interactiveStars(int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(starValue),
            icon: Icon(
              starValue <= value
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ),
        );
      }),
    );
  }

  Widget _stars(int value, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < value ? Icons.star_rounded : Icons.star_border_rounded,
          color: AppColors.warning,
          size: size,
        );
      }),
    );
  }
}
