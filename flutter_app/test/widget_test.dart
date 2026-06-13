import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/models/models.dart';
import 'package:mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: '.env', isOptional: true);
  });

  test('parses numeric boolean API fields safely', () {
    final socialLink = SocialLink.fromJson({
      'id': 1,
      'url': 'https://instagram.com/example',
      'is_verified': 0,
    });
    final message = Message.fromJson({
      'id': 1,
      'collaboration_id': 1,
      'sender_id': 1,
      'content': 'Bonjour',
      'attachment': null,
      'is_read': 1,
      'created_at': '2026-06-12T00:00:00.000000Z',
    });

    expect(socialLink.isVerified, isFalse);
    expect(message.isRead, isTrue);
  });

  test('parses string ids in deliverable payloads safely', () {
    final submission = DeliverableSubmission.fromJson({
      'id': '9',
      'collaboration_id': '4',
      'deliverable_type_id': '12',
      'url': 'https://example.com/video',
      'attachment': null,
      'status': 'submitted',
      'feedback': null,
      'created_at': '2026-06-12T00:00:00.000000Z',
      'deliverable_type': {
        'id': '12',
        'name': 'Story',
        'icon_name': null,
        'platform_id': '3',
      },
    });
    final deliverable = DeliverableWithPivot.fromJson({
      'id': '12',
      'name': 'Story',
      'icon_name': null,
      'platform_id': '3',
      'pivot': {'quantity': '2'},
    });

    expect(submission.id, 9);
    expect(submission.collaborationId, 4);
    expect(submission.deliverableTypeId, 12);
    expect(submission.deliverableType?.platformId, 3);
    expect(deliverable.id, 12);
    expect(deliverable.platformId, 3);
    expect(deliverable.quantity, 2);
  });

  testWidgets('renders login screen when unauthenticated', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
