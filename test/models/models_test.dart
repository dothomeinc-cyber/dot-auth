import 'package:dot_auth/dot_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// These are the regression tests for the bug that made `clearError()` a no-op.
///
/// The old models resolved nullable fields with `error ?? this.error`, so
/// passing `null` was indistinguishable from omitting the argument and the old
/// value survived. One failed sign-in then poisoned every attempt after it —
/// and because the email screen detected success with `error == null`, a later
/// *successful* sign-in would not navigate.
void main() {
  group('copyWith clears nullable fields', () {
    test('EmailAuthModel.clearError clears', () {
      const model = EmailAuthModel(error: 'Email or password is incorrect.');
      expect(model.clearError().error, isNull);
    });

    test('EmailAuthModel.copyWith(error: null) clears', () {
      const model = EmailAuthModel(error: 'boom');
      expect(model.copyWith(error: null).error, isNull);
    });

    test('EmailAuthModel.copyWith keeps error when the argument is omitted', () {
      const model = EmailAuthModel(error: 'boom');
      expect(model.copyWith(isLoading: true).error, 'boom');
    });

    test('EmailAuthModel.copyWith clears email', () {
      const model = EmailAuthModel(email: 'a@b.com');
      expect(model.copyWith(email: null).email, isNull);
    });

    test('PhoneAuthModel.clearError clears', () {
      const model = PhoneAuthModel(error: 'That code is incorrect.');
      expect(model.clearError().error, isNull);
    });

    test('PhoneAuthModel.copyWith clears verificationId independently', () {
      const model = PhoneAuthModel(verificationId: 'abc', resendToken: 7);
      expect(model.copyWith(verificationId: null).verificationId, isNull);
      expect(model.copyWith(verificationId: null).resendToken, 7);
      expect(model.copyWith(error: 'x').verificationId, 'abc');
    });

    test('PhoneAuthModel.copyWith clears resendToken', () {
      const model = PhoneAuthModel(resendToken: 7);
      expect(model.copyWith(resendToken: null).resendToken, isNull);
    });

    test('AuthStateModel.copyWith clears errorMessage', () {
      final model = AuthStateModel.error('nope');
      expect(model.copyWith(errorMessage: null).errorMessage, isNull);
    });

    test('AuthStateModel.copyWith clears user', () {
      final model = AuthStateModel.authenticated(const UserModel(uid: 'u1'));
      expect(model.copyWith(user: null).user, isNull);
    });

    test('UserModel.copyWith clears email but keeps untouched fields', () {
      const user = UserModel(uid: 'u1', email: 'a@b.com', displayName: 'Ann');
      expect(user.copyWith(email: null).email, isNull);
      expect(user.copyWith(email: null).displayName, 'Ann');
      expect(user.copyWith(displayName: 'Bee').email, 'a@b.com');
    });
  });

  group('AuthStateModel', () {
    test('factories set the matching flags', () {
      expect(AuthStateModel.authenticated(const UserModel(uid: 'u'))
          .isAuthenticated, isTrue);
      expect(AuthStateModel.unauthenticated().isUnauthenticated, isTrue);
      expect(AuthStateModel.error('x').hasError, isTrue);
    });

    test('isResolving covers both pre-Firebase and in-flight states', () {
      expect(AuthStateModel.initial().isResolving, isTrue);
      expect(AuthStateModel.loading().isResolving, isTrue);
      expect(AuthStateModel.unauthenticated().isResolving, isFalse);
    });

    test('an error attached to an authenticated session keeps the session', () {
      // deleteAccount() failing must not sign the user out.
      final model = AuthStateModel.authenticated(const UserModel(uid: 'u1'))
          .copyWith(errorMessage: 'Sign in again to confirm it is you.');
      expect(model.isAuthenticated, isTrue);
      expect(model.errorMessage, isNotNull);
    });
  });

  group('PhoneAuthModel derived flags', () {
    test('isCodeSent follows verificationId', () {
      expect(const PhoneAuthModel().isCodeSent, isFalse);
      expect(const PhoneAuthModel(verificationId: 'v').isCodeSent, isTrue);
    });

    test('isBusy covers both network steps', () {
      expect(
        const PhoneAuthModel(status: PhoneAuthStatus.sendingCode).isBusy,
        isTrue,
      );
      expect(
        const PhoneAuthModel(status: PhoneAuthStatus.verifying).isBusy,
        isTrue,
      );
      expect(
        const PhoneAuthModel(status: PhoneAuthStatus.codeSent).isBusy,
        isFalse,
      );
    });

    test('canResend is false before any code was sent', () {
      expect(const PhoneAuthModel().canResend, isFalse);
    });

    test('canResend is false while the cooldown runs', () {
      const model = PhoneAuthModel(verificationId: 'v', resendSeconds: 12);
      expect(model.canResend, isFalse);
    });

    test('canResend is false while busy', () {
      const model = PhoneAuthModel(
        verificationId: 'v',
        status: PhoneAuthStatus.verifying,
      );
      expect(model.canResend, isFalse);
    });

    test('canResend is true once the cooldown ends', () {
      const model = PhoneAuthModel(
        verificationId: 'v',
        status: PhoneAuthStatus.codeSent,
      );
      expect(model.canResend, isTrue);
    });
  });

  group('UserModel', () {
    test('round-trips through JSON', () {
      final user = UserModel(
        uid: 'u1',
        email: 'a@b.com',
        phoneNumber: '+919876543210',
        displayName: 'Ann',
        isEmailVerified: true,
        providerIds: const ['phone', 'password'],
        creationTime: DateTime.utc(2026, 1, 1),
        lastSignInTime: DateTime.utc(2026, 6, 1),
      );
      expect(UserModel.fromJson(user.toJson()), user);
    });

    test('survives a JSON payload with missing optional keys', () {
      final user = UserModel.fromJson({'uid': 'u1'});
      expect(user.uid, 'u1');
      expect(user.isEmailVerified, isFalse);
      expect(user.providerIds, isEmpty);
    });

    test('reports connected sign-in methods', () {
      const user = UserModel(uid: 'u1', providerIds: ['phone']);
      expect(user.hasPhoneProvider, isTrue);
      expect(user.hasPasswordProvider, isFalse);
    });

    test('equal values compare equal so consumers stop rebuilding', () {
      // Without ==, every identical emission from authStateChanges() would
      // rebuild everything watching currentUserProvider.
      const a = UserModel(uid: 'u1', providerIds: ['phone']);
      const b = UserModel(uid: 'u1', providerIds: ['phone']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different provider lists are not equal', () {
      const a = UserModel(uid: 'u1', providerIds: ['phone']);
      const b = UserModel(uid: 'u1', providerIds: ['phone', 'password']);
      expect(a, isNot(b));
    });

    test('empty is a usable sentinel', () {
      expect(UserModel.empty.isEmpty, isTrue);
      expect(const UserModel(uid: 'u1').isEmpty, isFalse);
    });
  });
}
