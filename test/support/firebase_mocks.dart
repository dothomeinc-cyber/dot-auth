import 'package:firebase_auth/firebase_auth.dart';

import 'package:mocktail/mocktail.dart';

/// Mock [FirebaseAuth]. Inject it with
/// `firebaseAuthProvider.overrideWithValue(...)`.
class MockFirebaseAuth extends Mock
    implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserMetadata extends Mock
    implements UserMetadata {}

class MockUserCredential extends Mock
    implements UserCredential {}

class MockUserInfo extends Mock implements UserInfo {}

class _FakeAuthCredential extends Fake
    implements AuthCredential {}

void _noopCompleted(PhoneAuthCredential _) {}
void _noopFailed(FirebaseAuthException _) {}
void _noopCodeSent(String _, int? __) {}
void _noopTimeout(String _) {}

/// Registers every fallback mocktail needs for `any(named: ...)` on the
/// `verifyPhoneNumber` and `signInWithCredential` signatures.
///
/// Call once from `setUpAll`.
void registerFirebaseFallbacks() {
  registerFallbackValue(Duration.zero);
  registerFallbackValue(_FakeAuthCredential());
  registerFallbackValue(_noopCompleted);
  registerFallbackValue(_noopFailed);
  registerFallbackValue(_noopCodeSent);
  registerFallbackValue(_noopTimeout);
}

/// Builds a stubbed [User] with the fields [UserModel.fromFirebaseUser] reads.
///
/// This calls `when()` internally, so it must never be invoked inside an open
/// stub. Build the user first, then stub with it:
///
/// ```dart
/// final user = buildMockUser(uid: 'u1');          // correct
/// when(() => auth.currentUser).thenReturn(user);
///
/// when(() => auth.currentUser)                    // throws
///     .thenReturn(buildMockUser(uid: 'u1'));
/// ```
///
/// The second form fails with "Cannot call `when` within a stub response", and
/// because mocktail keeps that flag globally, every later test in the same file
/// fails with the same message.
MockUser buildMockUser({
  String uid = 'uid-1',
  String? email,
  String? phoneNumber,
  String? displayName,
  bool emailVerified = false,
  List<String> providerIds = const [],
}) {
  final metadata = MockUserMetadata();
  when(() => metadata.creationTime)
      .thenReturn(DateTime.utc(2026, 1, 1));
  when(() => metadata.lastSignInTime)
      .thenReturn(DateTime.utc(2026, 6, 1));

  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.email).thenReturn(email);
  when(() => user.phoneNumber).thenReturn(phoneNumber);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.photoURL).thenReturn(null);
  when(() => user.emailVerified).thenReturn(emailVerified);
  when(() => user.metadata).thenReturn(metadata);
  final providerData = providerIds.map((id) {
    final info = MockUserInfo();
    when(() => info.providerId).thenReturn(id);
    return info;
  }).toList();

  when(() => user.providerData).thenReturn(providerData);
  return user;
}

/// Stubs `verifyPhoneNumber` and hands the registered callbacks to [onCall] so
/// a test can drive `codeSent`, `verificationFailed`, and friends by hand.
void stubVerifyPhoneNumber(
  MockFirebaseAuth auth,
  void Function(PhoneCallbacks callbacks) onCall,
) {
  when(() => auth.verifyPhoneNumber(
        phoneNumber: any(named: 'phoneNumber'),
        timeout: any(named: 'timeout'),
        forceResendingToken:
            any(named: 'forceResendingToken'),
        verificationCompleted:
            any(named: 'verificationCompleted'),
        verificationFailed:
            any(named: 'verificationFailed'),
        codeSent: any(named: 'codeSent'),
        codeAutoRetrievalTimeout:
            any(named: 'codeAutoRetrievalTimeout'),
      )).thenAnswer((invocation) async {
    final named = invocation.namedArguments;
    onCall(
      PhoneCallbacks(
        phoneNumber: named[#phoneNumber] as String,
        resendToken: named[#forceResendingToken] as int?,
        completed: named[#verificationCompleted]
            as PhoneVerificationCompleted,
        failed: named[#verificationFailed]
            as PhoneVerificationFailed,
        codeSent: named[#codeSent] as PhoneCodeSent,
        timeout: named[#codeAutoRetrievalTimeout]
            as PhoneCodeAutoRetrievalTimeout,
      ),
    );
  });
}

/// The callbacks `verifyPhoneNumber` was invoked with.
class PhoneCallbacks {
  final String phoneNumber;
  final int? resendToken;
  final PhoneVerificationCompleted completed;
  final PhoneVerificationFailed failed;
  final PhoneCodeSent codeSent;
  final PhoneCodeAutoRetrievalTimeout timeout;

  const PhoneCallbacks({
    required this.phoneNumber,
    required this.resendToken,
    required this.completed,
    required this.failed,
    required this.codeSent,
    required this.timeout,
  });
}
