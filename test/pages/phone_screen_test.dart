import 'package:dot_auth/dot_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../support/firebase_mocks.dart';

void main() {
  setUpAll(() {
    registerFirebaseFallbacks();
    // Keep google_fonts off the network during tests.
    DotAuthTypography.fontFamily = 'Roboto';
  });

  tearDownAll(() => DotAuthTypography.fontFamily = null);

  late MockFirebaseAuth auth;

  setUp(() {
    resetMocktailState();
    auth = MockFirebaseAuth();
  });

  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/phone',
      routes: [
        GoRoute(
          path: '/phone',
          builder: (_, __) => const AuthPhone(emailEnabled: true),
        ),
        GoRoute(
          path: '/otp',
          builder: (_, __) => const Scaffold(body: Text('OTP SCREEN')),
        ),
        GoRoute(
          path: '/email',
          builder: (_, __) => const Scaffold(body: Text('EMAIL SCREEN')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp.router(
          theme: authTheme(),
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgets('an empty number never reaches Firebase', (tester) async {
    // The old screen checked `international.isEmpty`, which is "+91" for an
    // empty Indian number and therefore never empty — so Firebase got called
    // with a bare country code.
    stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    verifyNever(() => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeSent: any(named: 'codeSent'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
        ));
  });

  testWidgets('a partial number never reaches Firebase', (tester) async {
    stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '98765');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    verifyNever(() => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          timeout: any(named: 'timeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeSent: any(named: 'codeSent'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
        ));
  });

  testWidgets('a valid number sends the code and moves to the OTP screen',
      (tester) async {
    stubVerifyPhoneNumber(auth, (c) => c.codeSent('vid-1', 42));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('OTP SCREEN'), findsOneWidget);
  });

  testWidgets('a failure is shown inline and the user stays put',
      (tester) async {
    stubVerifyPhoneNumber(
      auth,
      (c) => c.failed(FirebaseAuthException(code: 'too-many-requests')),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text(mapAuthError('too-many-requests')), findsOneWidget);
    expect(find.text('OTP SCREEN'), findsNothing);
  });

  testWidgets('the email link is only shown when enabled', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Use email instead'), findsOneWidget);
  });
}
