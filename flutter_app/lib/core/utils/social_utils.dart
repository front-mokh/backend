import 'package:flutter/material.dart';

IconData getSocialIcon(String url) {
  if (url.isEmpty) return Icons.link;
  final lowerUrl = url.toLowerCase();

  if (lowerUrl.contains('instagram')) return Icons.camera_alt;
  if (lowerUrl.contains('twitter') || lowerUrl.contains('x.com')) {
    return Icons.alternate_email;
  }
  if (lowerUrl.contains('facebook')) return Icons.facebook;
  if (lowerUrl.contains('linkedin')) return Icons.work;
  if (lowerUrl.contains('youtube')) return Icons.play_circle;
  if (lowerUrl.contains('tiktok')) return Icons.music_note;
  if (lowerUrl.contains('github')) return Icons.code;
  if (lowerUrl.contains('pinterest')) return Icons.push_pin;
  if (lowerUrl.contains('snapchat')) return Icons.photo_camera_front;
  if (lowerUrl.contains('whatsapp')) return Icons.chat;

  return Icons.link;
}

String getSocialPlatformName(String url) {
  if (url.isEmpty) return 'Site Web';
  final lowerUrl = url.toLowerCase();

  if (lowerUrl.contains('instagram')) return 'Instagram';
  if (lowerUrl.contains('twitter') || lowerUrl.contains('x.com')) {
    return 'X (Twitter)';
  }
  if (lowerUrl.contains('facebook')) return 'Facebook';
  if (lowerUrl.contains('linkedin')) return 'LinkedIn';
  if (lowerUrl.contains('youtube')) return 'YouTube';
  if (lowerUrl.contains('tiktok')) return 'TikTok';
  if (lowerUrl.contains('github')) return 'GitHub';
  if (lowerUrl.contains('pinterest')) return 'Pinterest';
  if (lowerUrl.contains('snapchat')) return 'Snapchat';
  if (lowerUrl.contains('whatsapp')) return 'WhatsApp';

  return 'Site Web';
}
