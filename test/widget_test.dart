// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'lib/core/core_utils.dart';
import 'lib/data/models/models.dart';
import 'lib/data/services/auth_service.dart';
import 'lib/data/services/chat_service.dart';
import 'lib/data/services/hive_services.dart';
import 'lib/data/services/presence_service.dart';
import 'lib/stores/auth/validation_stores.dart';
import 'lib/stores/basic_stores.dart';
import 'lib/stores/friend/friend_stores.dart';
import 'lib/ui/chat/chat_room/widget/chat_appbar_widget.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  authServiceTest();
  hiveServiceTest();
  chatServiceTest();
  presenceServiceTest();
  chatAppbarWidgetTest();
  coreUtilsTest();
  modelsTest();
  basicStoresTest();
  authValidationStoresTest();
  friendStoresTest();
}
