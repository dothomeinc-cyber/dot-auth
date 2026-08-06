import 'package:dot_auth/dot_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapAuthError', () {
    test('never leaks whether an account exists', () {
      // If these differ, the sign-in form becomes an email-enumeration oracle.
      final notFound = mapAuthError('user-not-found');
      expect(notFound, mapAuthError('wrong-password'));
      expect(notFound, mapAuthError('invalid-credential'));
      expect(notFound, mapAuthError('invalid-login-credentials'));
    });

    test('covers the phone and OTP codes', () {
      expect(mapAuthError('invalid-verification-code'), isNotEmpty);
      expect(mapAuthError('session-expired'), contains('expired'));
      expect(mapAuthError('invalid-phone-number'), isNotEmpty);
      expect(mapAuthError('quota-exceeded'), isNotEmpty);
    });

    test('covers the linking codes', () {
      expect(mapAuthError('credential-already-in-use'), isNotEmpty);
      expect(mapAuthError('provider-already-linked'), isNotEmpty);
    });

    test('falls back for codes it has never seen', () {
      expect(mapAuthError('some-code-firebase-added-last-week'), isNotEmpty);
    });

    test('messages are sentence case and end with a full stop', () {
      const codes = [
        'invalid-email',
        'user-disabled',
        'email-already-in-use',
        'weak-password',
        'requires-recent-login',
        'invalid-verification-code',
        'too-many-requests',
        'network-request-failed',
        'anything-unknown',
      ];
      for (final code in codes) {
        final message = mapAuthError(code);
        expect(message, endsWith('.'), reason: code);
        expect(message[0], message[0].toUpperCase(), reason: code);
      }
    });

    test('messages avoid blaming the user or apologising', () {
      const codes = ['invalid-email', 'wrong-password', 'too-many-requests'];
      for (final code in codes) {
        final message = mapAuthError(code).toLowerCase();
        expect(message, isNot(contains('sorry')), reason: code);
        expect(message, isNot(contains('oops')), reason: code);
      }
    });
  });
}
