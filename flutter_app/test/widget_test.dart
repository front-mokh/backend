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

  testWidgets('renders login screen when unauthenticated', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
