import 'package:flutter_test/flutter_test.dart';
import 'package:dot_auth/dot_auth.dart';

void main() {
  // ── AuthStateModel ────────────────────────────────────────────────────

  group('AuthStateModel', () {
    test('initial() sets status to initial', () {
      final m = AuthStateModel.initial();
      expect(m.status, AuthStatus.initial);
      expect(m.user, isNull);
      expect(m.errorMessage, isNull);
    });

    test('loading() sets isLoading to true', () {
      expect(AuthStateModel.loading().isLoading, isTrue);
    });

    test('unauthenticated() sets isUnauthenticated to true', () {
      final m = AuthStateModel.unauthenticated();
      expect(m.isAuthenticated, isFalse);
      expect(m.isUnauthenticated, isTrue);
    });

    test('authenticated() stores user and sets isAuthenticated', () {
      const user = UserModel(uid: 'uid-1', email: 'a@b.com');
      final m = AuthStateModel.authenticated(user);
      expect(m.isAuthenticated, isTrue);
      expect(m.user, equals(user));
    });

    test('error() stores errorMessage', () {
      final m = AuthStateModel.error('oops');
      expect(m.status, AuthStatus.error);
      expect(m.errorMessage, 'oops');
    });

    test('copyWith() overrides only given fields', () {
      final original = AuthStateModel.unauthenticated();
      final copy = original.copyWith(status: AuthStatus.loading);
      expect(copy.status, AuthStatus.loading);
      expect(copy.user, isNull);
    });
  });

  // ── PhoneAuthModel ────────────────────────────────────────────────────

  group('PhoneAuthModel', () {
    test('initial() has all nulls and false flags', () {
      final m = PhoneAuthModel.initial();
      expect(m.phoneNumber, isNull);
      expect(m.verificationId, isNull);
      expect(m.isCodeSent, isFalse);
      expect(m.isLoading, isFalse);
      expect(m.error, isNull);
      expect(m.resendToken, isNull);
    });

    test('copyWith() updates only specified fields', () {
      final m = PhoneAuthModel.initial()
          .copyWith(phoneNumber: '+919876543210', isLoading: true);
      expect(m.phoneNumber, '+919876543210');
      expect(m.isLoading, isTrue);
      expect(m.isCodeSent, isFalse);
    });

    test('setVerificationData pattern sets isCodeSent', () {
      final m = PhoneAuthModel.initial().copyWith(
        verificationId: 'vid-abc',
        isCodeSent: true,
        isLoading: false,
        resendToken: 42,
      );
      expect(m.isCodeSent, isTrue);
      expect(m.verificationId, 'vid-abc');
      expect(m.resendToken, 42);
    });

    test('clearError() removes error', () {
      final m = PhoneAuthModel.initial().copyWith(error: 'err').clearError();
      expect(m.error, isNull);
    });

    test('setOtp() stores code', () {
      expect(PhoneAuthModel.initial().setOtp('123456').otpCode, '123456');
    });

    test('resendToken null is valid — Firebase handles gracefully', () {
      final m = PhoneAuthModel.initial().copyWith(resendToken: null);
      expect(m.resendToken, isNull);
    });
  });

  // ── EmailAuthModel ────────────────────────────────────────────────────

  group('EmailAuthModel', () {
    test('initial() defaults to signIn mode', () {
      final m = EmailAuthModel.initial();
      expect(m.mode, EmailAuthMode.signIn);
      expect(m.isLoading, isFalse);
      expect(m.isPasswordResetSent, isFalse);
      expect(m.error, isNull);
    });

    test('copyWith() switches mode', () {
      final m = EmailAuthModel.initial().copyWith(mode: EmailAuthMode.signUp);
      expect(m.mode, EmailAuthMode.signUp);
    });

    test('clearError() removes error only', () {
      final m =
          EmailAuthModel.initial().copyWith(error: 'fail').clearError();
      expect(m.error, isNull);
      expect(m.mode, EmailAuthMode.signIn);
    });

    test('isPasswordResetSent flag sets correctly', () {
      final m =
          EmailAuthModel.initial().copyWith(isPasswordResetSent: true);
      expect(m.isPasswordResetSent, isTrue);
    });

    test('setMode resets error and reset flag', () {
      final m = EmailAuthModel.initial()
          .copyWith(error: 'x', isPasswordResetSent: true)
          .copyWith(mode: EmailAuthMode.signIn, error: null, isPasswordResetSent: false);
      expect(m.error, isNull);
      expect(m.isPasswordResetSent, isFalse);
    });
  });

  // ── UserModel ─────────────────────────────────────────────────────────

  group('UserModel', () {
    test('empty has empty uid', () {
      expect(UserModel.empty.uid, '');
    });

    test('copyWith() creates updated copy', () {
      const u = UserModel(uid: 'abc', email: 'old@test.com');
      final updated = u.copyWith(email: 'new@test.com', displayName: 'Dev');
      expect(updated.uid, 'abc');
      expect(updated.email, 'new@test.com');
      expect(updated.displayName, 'Dev');
    });

    test('toJson() / fromJson() round-trips correctly', () {
      const u = UserModel(
        uid: 'uid-999',
        email: 'round@trip.com',
        phoneNumber: '+911234567890',
        isEmailVerified: true,
        isPhoneVerified: true,
      );
      final restored = UserModel.fromJson(u.toJson());
      expect(restored.uid, u.uid);
      expect(restored.email, u.email);
      expect(restored.phoneNumber, u.phoneNumber);
      expect(restored.isEmailVerified, isTrue);
      expect(restored.isPhoneVerified, isTrue);
    });

    test('fromJson() handles null optional fields', () {
      final u = UserModel.fromJson({'uid': 'x'});
      expect(u.uid, 'x');
      expect(u.email, isNull);
      expect(u.displayName, isNull);
      expect(u.isEmailVerified, isFalse);
    });

    test('toString() includes uid and email', () {
      const u = UserModel(uid: 'u1', email: 'a@b.com');
      expect(u.toString(), contains('u1'));
      expect(u.toString(), contains('a@b.com'));
    });
  });
}
