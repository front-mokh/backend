import 'dart:io';

import 'package:flutter/material.dart';

class AppFileUtils {
  AppFileUtils._();

  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxDocumentBytes = 10 * 1024 * 1024;
  static const int maxUploadBytes = 50 * 1024 * 1024;

  static String extension(String source) {
    final path = Uri.tryParse(source)?.path ?? source;
    final name = path.split('/').last.toLowerCase();
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1);
  }

  static String displayName(String source) {
    final uri = Uri.tryParse(source);
    final path = uri?.path.isNotEmpty == true ? uri!.path : source;
    final value = path.split('/').last;
    if (value.isEmpty) return 'Pièce jointe';
    return Uri.decodeComponent(value);
  }

  static bool isImage(String source) {
    return const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    }.contains(extension(source));
  }

  static bool isPdf(String source) => extension(source) == 'pdf';

  static bool isVideo(String source) {
    return const {'mp4', 'mov', 'm4v', 'webm'}.contains(extension(source));
  }

  static IconData icon(String source) {
    if (isPdf(source)) return Icons.picture_as_pdf_outlined;
    if (isVideo(source)) return Icons.play_circle_outline;
    if (isImage(source)) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  static String typeLabel(String source) {
    if (isPdf(source)) return 'Document PDF';
    if (isVideo(source)) return 'Vidéo';
    if (isImage(source)) return 'Image';
    return 'Fichier';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} Ko';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} Mo';
  }

  static String? sizeError({
    required int bytes,
    required int maxBytes,
    String subject = 'Ce fichier',
  }) {
    if (bytes <= maxBytes) return null;
    return '$subject dépasse la limite de ${formatBytes(maxBytes)}.';
  }

  static Future<int?> pathSize(String path) async {
    try {
      return File(path).length();
    } catch (_) {
      return null;
    }
  }
}
