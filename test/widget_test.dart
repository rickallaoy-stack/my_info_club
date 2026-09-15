import 'package:flutter_test/flutter_test.dart';

import 'package:club_informatique_app/features/auth/domain/validators/auth_validators.dart';

void main() {
  group('auth validators', () {
    test('password must be strong enough', () {
      expect(validatePassword('abcd123'), isNotNull);
      expect(validatePassword('Abcdef1!'), isNull);
    });

    test('confirmation must match the password', () {
      expect(validatePasswordConfirmation('Secret1!', 'Secret1!'), isNull);
      expect(
        validatePasswordConfirmation('Secret1!', 'Secret2!'),
        'Les mots de passe ne correspondent pas.',
      );
    });
  });
}
