import 'dart:async';

import 'package:dot_auth/dot_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/firebase_mocks.dart';

void main() {
  setUpAll(registerFirebaseFallbacks);

  late MockFirebaseAuth auth;
  late StreamController<User?> authChanges;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    // Without this, a test that dies mid-stub leaves mocktail's global
    // "stubbing in progress" flag set and every later test in the file fails
    // with the same misleading error.
    resetMocktailState();

    auth = MockFirebaseAuth();
    authChanges = StreamController<User?>.broadcast();
    when(() => auth.authStateChanges()).thenAnswer((_) => authChanges.stream);
    when(() => auth.currentUser).thenReturn(null);
    addTearDown(authChanges.close);
  });

  group('session seeding', () {
    test('a returning user is authenticated on the first read', () async {
      // Seeded synchronously so a warm start never flashes the login screen.
      // Build the mock first. Calling when() inside thenReturn() while the
      // outer stub is still open throws "Cannot call `when` within a stub
      // response" — and buildMockUser() stubs its own getters.
      final user = buildMockUser(
        uid: 'u1',
        phoneNumber: '+919876543210',
        providerIds: ['phone'],
      );
      when(() => auth.currentUser).thenReturn(user);

      final container = makeContainer();
      final state = container.read(authStateProvider);

      expect(state.isAuthenticated, isTrue);
      expect(state.user?.uid, 'u1');
      expect(state.user?.hasPhoneProvider, isTrue);
      expect(state.isResolving, isFalse);
    });

    test('no cached user means unauthenticated, not loading', () {
      final container = makeContainer();
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);
    });
  });

  group('auth stream', () {
    test('signing in flips the session', () async {
      final container = makeContainer();
      container.read(authStateProvider);

      authChanges.add(buildMockUser(uid: 'u2', email: 'a@b.com'));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, 'a@b.com');
    });

    test('signing out flips it back', () async {
      final user = buildMockUser(uid: 'u1');
      when(() => auth.currentUser).thenReturn(user);
      final container = makeContainer();
      expect(container.read(authStateProvider).isAuthenticated, isTrue);

      authChanges.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authStateProvider).isUnauthenticated, isTrue);
    });

    test('an identical emission produces an equal state', () async {
      // Equality on the models is what stops consumers rebuilding on every
      // duplicate emission from the stream.
      final container = makeContainer();
      container.read(authStateProvider);

      authChanges.add(buildMockUser(uid: 'u1', email: 'a@b.com'));
      await Future<void>.delayed(Duration.zero);
      final first = container.read(authStateProvider);

      authChanges.add(buildMockUser(uid: 'u1', email: 'a@b.com'));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authStateProvider), first);
    });
  });

  group('signOut', () {
    test('clears both auth flows', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

      final container = makeContainer();
      await container
          .read(phoneAuthProvider.notifier)
          .sendCode('+919876543210');
      expect(container.read(phoneAuthProvider).isCodeSent, isTrue);

      await container.read(authStateProvider.notifier).signOut();

      expect(container.read(phoneAuthProvider), PhoneAuthModel.initial());
      expect(container.read(emailAuthProvider), EmailAuthModel.initial());
    });

    test('reports a failure instead of pretending it worked', () async {
      when(() => auth.signOut())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final container = makeContainer();
      await container.read(authStateProvider.notifier).signOut();

      expect(container.read(authStateProvider).hasError, isTrue);
    });
  });

  group('deleteAccount', () {
    test('returns true when Firebase accepts the deletion', () async {
      final user = buildMockUser(uid: 'u1');
      when(() => user.delete()).thenAnswer((_) async {});
      when(() => auth.currentUser).thenReturn(user);

      final container = makeContainer();
      final deleted =
          await container.read(authStateProvider.notifier).deleteAccount();

      expect(deleted, isTrue);
      verify(() => user.delete()).called(1);
    });

    test('keeps the session when Firebase wants a fresh sign-in', () async {
      // Losing the session here would strand the user with no way to
      // re-authenticate and retry.
      final user = buildMockUser(uid: 'u1');
      when(() => user.delete())
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));
      when(() => auth.currentUser).thenReturn(user);

      final container = makeContainer();
      final deleted =
          await container.read(authStateProvider.notifier).deleteAccount();

      final state = container.read(authStateProvider);
      expect(deleted, isFalse);
      expect(state.isAuthenticated, isTrue);
      expect(state.errorMessage, mapAuthError('requires-recent-login'));
    });

    test('does nothing when nobody is signed in', () async {
      final container = makeContainer();
      expect(
        await container.read(authStateProvider.notifier).deleteAccount(),
        isFalse,
      );
    });
  });

  group('email verification', () {
    test('isEmailVerifiedProvider is false for an unverified address', () {
      final user =
          buildMockUser(uid: 'u1', email: 'a@b.com', emailVerified: false);
      when(() => auth.currentUser).thenReturn(user);
      final container = makeContainer();
      expect(container.read(isEmailVerifiedProvider), isFalse);
    });

    test('a phone-only account counts as verified', () {
      // There is no email to verify, so gating on this must not lock them out.
      final user = buildMockUser(uid: 'u1', phoneNumber: '+919876543210');
      when(() => auth.currentUser).thenReturn(user);
      final container = makeContainer();
      expect(container.read(isEmailVerifiedProvider), isTrue);
    });

    test('sendEmailVerification short-circuits when already verified',
        () async {
      final user =
          buildMockUser(uid: 'u1', email: 'a@b.com', emailVerified: true);
      when(() => auth.currentUser).thenReturn(user);

      final container = makeContainer();
      final sent = await container
          .read(authStateProvider.notifier)
          .sendEmailVerification();

      expect(sent, isTrue);
      verifyNever(() => user.sendEmailVerification());
    });
  });
}
