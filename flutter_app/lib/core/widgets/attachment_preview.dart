import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/file_utils.dart';

class AppAttachmentPreview extends StatelessWidget {
  const AppAttachmentPreview({
    super.key,
    required this.source,
    this.inverse = false,
    this.maxWidth,
    this.imageHeight = 180,
  });

  final String source;
  final bool inverse;
  final double? maxWidth;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    if (AppFileUtils.isImage(source)) return _imagePreview(context);

    final foreground = inverse ? Colors.white : AppColors.text;
    final secondary = inverse ? Colors.white70 : AppColors.textSecondary;
    final background = inverse
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.surfaceElevated;
    final border = inverse
        ? Colors.white.withValues(alpha: 0.16)
        : AppColors.border;

    return Container(
      constraints: maxWidth == null
          ? null
          : BoxConstraints(maxWidth: maxWidth!),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: inverse
                  ? Colors.white.withValues(alpha: 0.16)
                  : AppColors.primaryLightest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              AppFileUtils.icon(source),
              color: inverse ? Colors.white : AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppFileUtils.typeLabel(source),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFileUtils.displayName(source),
                  style: GoogleFonts.inter(fontSize: 12, color: secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.open_in_new, size: 16, color: secondary),
        ],
      ),
    );
  }

  Widget _imagePreview(BuildContext context) {
    final width = maxWidth ?? MediaQuery.sizeOf(context).width * 0.6;
    final borderRadius = BorderRadius.circular(12);
    final isRemote =
        source.startsWith('http://') || source.startsWith('https://');

    return ClipRRect(
      borderRadius: borderRadius,
      child: isRemote
          ? Image.network(
              source,
              width: width,
              height: imageHeight,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _brokenImage(width, imageHeight),
            )
          : Image.file(
              File(source),
              width: width,
              height: imageHeight,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _brokenImage(width, imageHeight),
            ),
    );
  }

  Widget _brokenImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: inverse
          ? Colors.white.withValues(alpha: 0.12)
          : AppColors.surfaceElevated,
      child: Icon(
        Icons.broken_image_outlined,
        color: inverse ? Colors.white70 : AppColors.textTertiary,
      ),
    );
  }
}
