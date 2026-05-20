import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_auth/dot_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ScreenUtil
  await ScreenUtil.ensureScreenSize();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create router with authentication
    final router = AuthRouter.createRouter(
      ref: ref,
      homeRoute: '/home',
      homeBuilder: (context, state) => const HomePage(),
    );

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp.router(
          title: 'Dot Auth Example',
          theme: authTheme(), // Use package theme
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// Home Page - Only visible when authenticated
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);
    final isAuthenticated =
        ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // Sign out button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref
                  .read(authStateProvider.notifier)
                  .signOut();
              if (context.mounted) {
                context.pushReplacement('/phone');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Dot Auth Example!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // User information
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(
                  horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'User Information',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Phone: ${user?.phoneNumber ?? "N/A"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'UID: ${user?.uid ?? "N/A"}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Email: ${user?.email ?? "N/A"}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Phone Verified: ${user?.isPhoneVerified ?? false}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Auth state information
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(
                  horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Authentication State',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Status: ${authState.status}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Is Authenticated: $isAuthenticated',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Is Loading: ${authState.isLoading}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Navigation buttons
            ElevatedButton(
              onPressed: () {
                context.push('/profile');
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Page - Example of protected route
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              user?.phoneNumber ?? 'No phone number',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              user?.email ?? 'No email',
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Example of protected route wrapper
class ProtectedRoute extends ConsumerWidget {
  final Widget child;

  const ProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated =
        ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/phone');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return child;
  }
}

// Example of custom widget accessing auth state
class AnyWidget extends ConsumerWidget {
  const AnyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user
    final user = ref.watch(currentUserProvider);

    // Check if authenticated
    final isAuthenticated =
        ref.watch(isAuthenticatedProvider);

    // Get full auth state
    final authState = ref.watch(authStateProvider);

    return Column(
      children: [
        Text('Logged in: $isAuthenticated'),
        if (user != null)
          Text('Phone: ${user.phoneNumber}'),
        if (authState.isLoading)
          const CircularProgressIndicator(),
      ],
    );
  }
}

// Settings page with sign out
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ref
                .read(authStateProvider.notifier)
                .signOut();
            if (context.mounted) {
              context.pushReplacement('/phone');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sign Out'),
        ),
      ),
    );
  }
}
