// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lib/data/services/auth_service.dart';
import 'lib/data/services/chat_service.dart';
import 'lib/data/services/presence_service.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env.example',
    isOptional: true,
  );
  authServiceTest();
  chatServiceTest();
  presenceServiceTest();
}
