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

  group('signIn', () {
    test('returns true and leaves no error behind', () async {
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => MockUserCredential());

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .signIn(' a@b.com ', 'hunter2');

      expect(ok, isTrue);
      final state = container.read(emailAuthProvider);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
      expect(state.email, 'a@b.com');

      // The email is trimmed before it reaches Firebase.
      verify(() => auth.signInWithEmailAndPassword(
            email: 'a@b.com',
            password: 'hunter2',
          )).called(1);
    });

    test('returns false and maps the failure', () async {
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .signIn('a@b.com', 'nope');

      expect(ok, isFalse);
      expect(container.read(emailAuthProvider).error,
          mapAuthError('wrong-password'));
    });

    test('a successful retry clears the error from the failed attempt',
        () async {
      // The original bug: copyWith(error: null) kept the old error, so the
      // screen's `error == null` success check stayed false forever and a
      // signed-in user was stranded on the login form.
      var attempts = 0;
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw FirebaseAuthException(code: 'wrong-password');
        }
        return MockUserCredential();
      });

      final container = makeContainer();
      final notifier = container.read(emailAuthProvider.notifier);

      expect(await notifier.signIn('a@b.com', 'wrong'), isFalse);
      expect(container.read(emailAuthProvider).error, isNotNull);

      expect(await notifier.signIn('a@b.com', 'right'), isTrue);
      expect(container.read(emailAuthProvider).error, isNull);
    });
  });

  group('signUp', () {
    test('sends a verification email when configured to', () async {
      final user = buildMockUser(uid: 'u1', email: 'a@b.com');
      when(() => user.sendEmailVerification()).thenAnswer((_) async {});
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credential);

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .signUp('a@b.com', 'hunter2');

      expect(ok, isTrue);
      expect(container.read(emailAuthProvider).isVerificationEmailSent, isTrue);
      verify(() => user.sendEmailVerification()).called(1);
    });

    test('skips the verification email when disabled', () async {
      final user = buildMockUser(uid: 'u1', email: 'a@b.com');
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credential);

      final container = makeContainer(
        config: const DotAuthConfig(sendVerificationEmailOnSignUp: false),
      );
      await container
          .read(emailAuthProvider.notifier)
          .signUp('a@b.com', 'hunter2');

      verifyNever(() => user.sendEmailVerification());
    });

    test('a failed verification email does not fail the sign-up', () async {
      // The account exists either way — reporting failure would be a lie.
      final user = buildMockUser(uid: 'u1', email: 'a@b.com');
      when(() => user.sendEmailVerification())
          .thenThrow(FirebaseAuthException(code: 'too-many-requests'));
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credential);

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .signUp('a@b.com', 'hunter2');

      expect(ok, isTrue);
      expect(container.read(emailAuthProvider).isVerificationEmailSent,
          isFalse);
      expect(container.read(emailAuthProvider).error, isNull);
    });

    test('maps a duplicate address', () async {
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .signUp('a@b.com', 'hunter2');

      expect(ok, isFalse);
      expect(container.read(emailAuthProvider).error,
          mapAuthError('email-already-in-use'));
    });
  });

  group('sendPasswordReset', () {
    test('reports success on a real send', () async {
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .sendPasswordReset('a@b.com');

      expect(ok, isTrue);
      expect(container.read(emailAuthProvider).isPasswordResetSent, isTrue);
    });

    test('reports success for an unknown address too', () async {
      // Otherwise the reset form becomes an account-existence oracle.
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .sendPasswordReset('nobody@example.com');

      expect(ok, isTrue);
      expect(container.read(emailAuthProvider).isPasswordResetSent, isTrue);
      expect(container.read(emailAuthProvider).error, isNull);
    });

    test('still reports real failures', () async {
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final container = makeContainer();
      final ok = await container
          .read(emailAuthProvider.notifier)
          .sendPasswordReset('a@b.com');

      expect(ok, isFalse);
      expect(container.read(emailAuthProvider).error,
          mapAuthError('network-request-failed'));
    });
  });

  group('setMode', () {
    test('clears everything left over from the previous mode', () async {
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final container = makeContainer();
      final notifier = container.read(emailAuthProvider.notifier);
      await notifier.signIn('a@b.com', 'nope');
      expect(container.read(emailAuthProvider).error, isNotNull);

      notifier.setMode(EmailAuthMode.signUp);
      final state = container.read(emailAuthProvider);
      expect(state.mode, EmailAuthMode.signUp);
      expect(state.error, isNull);
      expect(state.isPasswordResetSent, isFalse);
    });
  });
}
