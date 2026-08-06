import 'package:dot_auth/dot_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/firebase_mocks.dart';

void main() {
  setUpAll(registerFirebaseFallbacks);

  late MockFirebaseAuth auth;

  ProviderContainer makeContainer({DotAuthConfig? config}) {
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        if (config != null) dotAuthConfigProvider.overrideWithValue(config),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    resetMocktailState();
    auth = MockFirebaseAuth();
  });

  group('sendCode', () {
    test('stores the number and moves to codeSent when the SMS goes out',
        () async {
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer();
      await container
          .read(phoneAuthProvider.notifier)
          .sendCode('+919876543210');

      final state = container.read(phoneAuthProvider);
      expect(state.status, PhoneAuthStatus.codeSent);
      expect(state.phoneNumber, '+919876543210');
      expect(state.verificationId, 'vid-1');
      expect(state.resendToken, 42);
      expect(state.error, isNull);
    });

    test('surfaces a mapped message when verification fails', () async {
      stubVerifyPhoneNumber(
        auth,
        (c) => c.failed(FirebaseAuthException(code: 'invalid-phone-number')),
      );

      final container = makeContainer();
      await container.read(phoneAuthProvider.notifier).sendCode('+9199');

      final state = container.read(phoneAuthProvider);
      expect(state.status, PhoneAuthStatus.error);
      expect(state.error, mapAuthError('invalid-phone-number'));
    });

    test('codeAutoRetrievalTimeout is not treated as a failure', () async {
      // This was the bug: the callback fires on the happy path when Android's
      // auto-retrieval window closes, and the old code wrote an error into
      // state while the user was verifying normally.
      stubVerifyPhoneNumber(auth, (c) {
        c.codeSent('vid-1', 42);
        c.timeout('vid-1');
      });

      final container = makeContainer();
      await container
          .read(phoneAuthProvider.notifier)
          .sendCode('+919876543210');

      final state = container.read(phoneAuthProvider);
      expect(state.error, isNull);
      expect(state.status, PhoneAuthStatus.codeSent);
      expect(state.verificationId, 'vid-1');
    });

    test('a fresh send clears the previous verification data', () async {
      var call = 0;
      stubVerifyPhoneNumber(auth, (c) {
        call++;
        if (call == 1) {
          c.codeSent('vid-1', 1);
        } else {
          c.failed(FirebaseAuthException(code: 'network-request-failed'));
        }
      });

      final container = makeContainer();
      final notifier = container.read(phoneAuthProvider.notifier);

      await notifier.sendCode('+919876543210');
      await notifier.sendCode('+919999999999');

      final state = container.read(phoneAuthProvider);
      expect(state.verificationId, isNull);
      expect(state.phoneNumber, '+919999999999');
    });

    test('Android instant verification signs in without an OTP', () async {
      when(() => auth.signInWithCredential(any()))
          .thenAnswer((_) async => MockUserCredential());

      stubVerifyPhoneNumber(auth, (c) {
        c.completed(
          PhoneAuthProvider.credential(verificationId: 'v', smsCode: '000000'),
        );
      });

      final container = makeContainer();
      await container
          .read(phoneAuthProvider.notifier)
          .sendCode('+919876543210');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(phoneAuthProvider).status,
          PhoneAuthStatus.verified);
    });
  });

  group('verifyOtp', () {
    test('signs in with the stored verification id', () async {
      when(() => auth.signInWithCredential(any()))
          .thenAnswer((_) async => MockUserCredential());
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer();
      final notifier = container.read(phoneAuthProvider.notifier);
      await notifier.sendCode('+919876543210');
      await notifier.verifyOtp('123456');

      expect(container.read(phoneAuthProvider).status,
          PhoneAuthStatus.verified);
      verify(() => auth.signInWithCredential(any())).called(1);
    });

    test('refuses when no code is pending', () async {
      final container = makeContainer();
      await container.read(phoneAuthProvider.notifier).verifyOtp('123456');

      expect(container.read(phoneAuthProvider).status, PhoneAuthStatus.error);
      verifyNever(() => auth.signInWithCredential(any()));
    });

    test('maps a wrong code to a message the user can act on', () async {
      when(() => auth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'invalid-verification-code'),
      );
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer();
      final notifier = container.read(phoneAuthProvider.notifier);
      await notifier.sendCode('+919876543210');
      await notifier.verifyOtp('000000');

      final state = container.read(phoneAuthProvider);
      expect(state.status, PhoneAuthStatus.error);
      expect(state.error, mapAuthError('invalid-verification-code'));
      // The verification id survives so the user can just retype.
      expect(state.verificationId, 'vid-1');
    });

    test('a retry after a failure clears the old error', () async {
      var attempts = 0;
      when(() => auth.signInWithCredential(any())).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw FirebaseAuthException(code: 'invalid-verification-code');
        }
        return MockUserCredential();
      });
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer();
      final notifier = container.read(phoneAuthProvider.notifier);
      await notifier.sendCode('+919876543210');
      await notifier.verifyOtp('000000');
      expect(container.read(phoneAuthProvider).error, isNotNull);

      await notifier.verifyOtp('123456');
      final state = container.read(phoneAuthProvider);
      expect(state.error, isNull);
      expect(state.status, PhoneAuthStatus.verified);
    });
  });

  group('resend cooldown', () {
    test('starts after the code is sent and blocks an early resend', () async {
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer(
        config: const DotAuthConfig(resendCooldown: Duration(seconds: 30)),
      );
      final notifier = container.read(phoneAuthProvider.notifier);
      await notifier.sendCode('+919876543210');

      expect(container.read(phoneAuthProvider).resendSeconds, 30);
      expect(container.read(phoneAuthProvider).canResend, isFalse);

      await notifier.resendCode();
      // One call for the original send, none for the blocked resend.
      verify(() => auth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          )).called(1);
    });

    test('passes the resend token through once the cooldown is zero', () async {
      int? seenToken;
      stubVerifyPhoneNumber(auth, (c) {
        seenToken = c.resendToken;
        c.codeSent('vid-2', 99);
      });

      final container = makeContainer(
        config: const DotAuthConfig(resendCooldown: Duration.zero),
      );
      final notifier = container.read(phoneAuthProvider.notifier);

      await notifier.sendCode('+919876543210');
      expect(container.read(phoneAuthProvider).canResend, isTrue);

      await notifier.resendCode();
      expect(seenToken, 99);
      expect(container.read(phoneAuthProvider).verificationId, 'vid-2');
    });

    test('does nothing when there is no number yet', () async {
      final container = makeContainer();
      await container.read(phoneAuthProvider.notifier).resendCode();
      expect(container.read(phoneAuthProvider).status, PhoneAuthStatus.idle);
    });
  });

  group('clearError and reset', () {
    test('clearError returns to codeSent when a code is pending', () async {
      when(() => auth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'invalid-verification-code'),
      );
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer();
      final notifier = container.read(phoneAuthProvider.notifier);
      await notifier.sendCode('+919876543210');
      await notifier.verifyOtp('000000');

      notifier.clearError();
      final state = container.read(phoneAuthProvider);
      expect(state.error, isNull);
      expect(state.status, PhoneAuthStatus.codeSent);
    });

    test('reset wipes the flow', () async {
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer();
      final notifier = container.read(phoneAuthProvider.notifier);
      await notifier.sendCode('+919876543210');
      notifier.reset();

      expect(container.read(phoneAuthProvider), PhoneAuthModel.initial());
    });
  });
}
