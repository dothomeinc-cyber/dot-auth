import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The [FirebaseAuth] instance every notifier in this package talks to.
///
/// Override it in tests with a mock so the auth flows can be driven without a
/// live Firebase project:
///
/// ```dart
/// ProviderContainer(
///   overrides: [firebaseAuthProvider.overrideWithValue(MockFirebaseAuth())],
/// );
/// ```
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
