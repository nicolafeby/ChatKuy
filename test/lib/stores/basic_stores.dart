import 'package:chatkuy/stores/base/base_store.dart';
import 'package:chatkuy/stores/button/button_store.dart';
import 'package:chatkuy/stores/password_field/password_field_store.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> basicStoresTest() async {
  group('BaseStore', () {
    test('defaults selectedIndex to chat tab and updates on tap', () {
      final store = BaseStore();

      expect(store.selectedIndex, 1);

      store.onTapItem(2);

      expect(store.selectedIndex, 2);
    });
  });

  group('PasswordFieldStore', () {
    test('validates password requirements in order', () {
      final store = PasswordFieldStore();

      expect(store.passwordError, isNull);
      expect(store.isVerifyPasswordValid, isFalse);

      store.setPassword('short');
      expect(store.passwordError, 'Minimal 8 karakter');

      store.setPassword('lowercase');
      expect(store.passwordError, 'Butuh 1 huruf besar');

      store.setPassword('LOWERCASE');
      expect(store.passwordError, 'Butuh 1 huruf kecil');

      store.setPassword('Password');
      expect(store.passwordError, 'Butuh 1 angka');

      store.setPassword('Password1');
      expect(store.passwordError, 'Butuh 1 karakter spesial');

      store.setPassword('Password1!');
      expect(store.passwordError, isNull);
      expect(store.isVerifyPasswordValid, isTrue);
    });

    test('validates confirmation password and visibility toggle', () {
      final store = PasswordFieldStore();

      store.setPassword('Password1!');
      store.setConfirmPassword('Password2!');

      expect(store.confirmPasswordError, 'Konfirmasi password tidak cocok');
      expect(store.isCreatePasswordValid, isFalse);

      store.setConfirmPassword('Password1!');
      expect(store.confirmPasswordError, isNull);
      expect(store.isCreatePasswordValid, isTrue);

      store.toggleVisibility();
      expect(store.isPasswordVisible, isTrue);
    });
  });

  group('ButtonStore', () {
    testWidgets('starts countdown and formats remaining time', (tester) async {
      final store = ButtonStore();

      store.startCountdown(value: 65);

      expect(store.remainingSeconds, 65);
      expect(store.formattedTime, '1:05');
      expect(store.isDisabled, isTrue);
      expect(store.isButtonClicked, isTrue);

      await tester.pump(const Duration(seconds: 1));

      expect(store.remainingSeconds, 64);
      expect(store.formattedTime, '1:04');

      store.dispose();
    });

    testWidgets('countdown reaches zero and enables button again',
        (tester) async {
      final store = ButtonStore();
      addTearDown(store.dispose);

      store.startCountdown(value: 1);
      await tester.pump(const Duration(seconds: 1));

      expect(store.remainingSeconds, 0);
      expect(store.formattedTime, '0');
      expect(store.isDisabled, isFalse);
    });
  });
}
