import 'package:flutter/material.dart';

import 'create_announcement_screen.dart';

class EditAnnouncementScreen extends StatelessWidget {
  final int id;
  const EditAnnouncementScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return CreateAnnouncementScreen(announcementId: id);
  }
}
