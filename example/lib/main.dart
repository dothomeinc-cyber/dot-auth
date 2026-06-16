import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:dot_auth/dot_auth.dart';

// ─── Config ────────────────────────────────────────────────────────────────

/// Flip to false for phone-only mode.
/// When false, /email is not registered and the phone toggle is hidden.
const bool kEmailEnabled = true;

// ─── Router ────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/phone',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authStateProvider).isAuthenticated;

      final isAuthPage = state.matchedLocation == '/phone' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/email';

      if (isAuthenticated && isAuthPage) return '/home';
      if (!isAuthenticated && state.matchedLocation == '/home') return '/phone';
      return null;
    },
    routes: [
      GoRoute(
        path: '/phone',
        name: 'phone',
        pageBuilder: (context, state) => _slide(
          state,
          const AuthPhone(
            emailEnabled: kEmailEnabled,
            termsRoute: '/terms',
            privacyRoute: '/privacy',
          ),
        ),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        pageBuilder: (context, state) => _slide(state, const OtpScreen()),
      ),
      if (kEmailEnabled)
        GoRoute(
          path: '/email',
          name: 'email',
          pageBuilder: (context, state) => _slide(
            state,
            const AuthEmail(
              phoneEnabled: true,
              termsRoute: '/terms',
              privacyRoute: '/privacy',
            ),
          ),
        ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) =>
            _slide(state, const _HomeScreen()),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (_, __) => const _StaticScreen(title: 'Terms & Conditions'),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (_, __) => const _StaticScreen(title: 'Privacy Policy'),
      ),
    ],
  );
});

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      );
    },
  );
}

// ─── App ───────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: _App()));
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp.router(
        title: 'dot_auth example',
        theme: authTheme(),
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}

// ─── Home screen ───────────────────────────────────────────────────────────

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: Text('Home', style: AuthTextStyles.headlineS),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Signed in ✓', style: AuthTextStyles.titleM),
            SizedBox(height: 8.h),
            if (user?.phoneNumber != null)
              Text(user!.phoneNumber!, style: AuthTextStyles.bodyM),
            if (user?.email != null)
              Text(user!.email!, style: AuthTextStyles.bodyM),
          ],
        ),
      ),
    );
  }
}

// ─── Static placeholder screen for T&C / Privacy ───────────────────────────

class _StaticScreen extends StatelessWidget {
  final String title;
  const _StaticScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.white,
      appBar: AppBar(
        title: Text(title, style: AuthTextStyles.headlineS),
      ),
      body: Center(
        child: Text(
          'Add your $title content here.',
          style: AuthTextStyles.bodyM,
        ),
      ),
    );
  }
}
