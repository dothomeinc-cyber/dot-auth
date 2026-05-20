Dot Auth 🔐
https://img.shields.io/pub/v/dot_auth.svg
https://img.shields.io/badge/License-MIT-green.svg

A powerful and reusable Flutter authentication package with phone number OTP verification using Firebase. Built with Riverpod for state management and GoRouter for navigation.

Table of Contents
Features

Installation

Quick Start

API Reference

Authentication State Provider

Current User Provider

Authentication Status Provider

Phone Authentication Provider

Methods (Notifiers)

Auth State Notifier Methods

Phone Auth Notifier Methods

Complete Usage Examples

AuthStatus Enum

Quick Reference Card

Features
✅ Phone Authentication - OTP verification with Firebase

✅ Riverpod Integration - Clean and testable state management

✅ GoRouter Support - Declarative routing with auth guards

✅ Responsive Design - ScreenUtil for adaptive UI

✅ Customizable Theme - Easy to match your brand

✅ Type Safety - Full type-safe models and providers

✅ Ready-to-use UI - Beautiful pre-built screens

Installation
Add to your pubspec.yaml:

yaml
dependencies:
  dot_auth: ^1.0.0
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  flutter_screenutil: ^5.9.0
Then run:

bash
flutter pub get
Quick Start
1. Setup Firebase
Follow the Firebase setup guide for your platform.

2. Initialize in your app
dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dot_auth/dot_auth.dart';
import 'firebase_options.dart';

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
3. Configure Router
dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          title: 'My App',
          theme: authTheme(),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) {
                context.pushReplacement('/phone');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome ${user?.phoneNumber ?? "User"}'),
      ),
    );
  }
}
API Reference
Authentication State Provider (authStateProvider)
The main provider for authentication state. Watch this to get all auth-related information.

dart
final authState = ref.watch(authStateProvider);
Properties
Property	Type	Description
status	AuthStatus	Current authentication status (initial, loading, authenticated, unauthenticated, error)
isAuthenticated	bool	true if user is logged in
isLoading	bool	true if authentication is in progress
isUnauthenticated	bool	true if user is not logged in
user	UserModel?	Current user data or null
errorMessage	String?	Error message if authentication failed
User Details (from authState.user)
Property	Type	Description
uid	String	Unique user ID
phoneNumber	String?	User's phone number
email	String?	User's email address
displayName	String?	User's display name
photoURL	String?	User's photo URL
creationTime	DateTime?	Account creation time
lastSignInTime	DateTime?	Last login time
isEmailVerified	bool	Email verification status
isPhoneVerified	bool	Phone verification status
Usage Examples
dart
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  
  // Check if user is logged in
  if (authState.isAuthenticated) {
    return Text('Welcome ${authState.user?.phoneNumber}');
  }
  
  // Show loading indicator
  if (authState.isLoading) {
    return const CircularProgressIndicator();
  }
  
  // Show error
  if (authState.errorMessage != null) {
    return Text('Error: ${authState.errorMessage}');
  }
  
  return const Text('Please login');
}
Current User Provider (currentUserProvider)
A simplified provider that only returns the current user.

dart
final user = ref.watch(currentUserProvider);
User Properties
Property	Type	Description
uid	String	Unique user ID
phoneNumber	String?	User's phone number
email	String?	User's email address
displayName	String?	User's display name
photoURL	String?	User's photo URL
creationTime	DateTime?	Account creation time
lastSignInTime	DateTime?	Last login time
isEmailVerified	bool	Email verification status
isPhoneVerified	bool	Phone verification status
Usage Examples
dart
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return const Text('Not logged in');
  }
  
  return Column(
    children: [
      Text('Phone: ${user.phoneNumber}'),
      Text('UID: ${user.uid}'),
      Text('Verified: ${user.isPhoneVerified}'),
      Text('Email: ${user.email ?? "No email"}'),
      Text('Name: ${user.displayName ?? "No name"}'),
    ],
  );
}
Authentication Status Provider (isAuthenticatedProvider)
A simple boolean provider for authentication status.

dart
final isAuthenticated = ref.watch(isAuthenticatedProvider);
// Returns: true if user is logged in, false otherwise
Usage Examples
dart
Widget build(BuildContext context, WidgetRef ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return isAuthenticated 
      ? const Text('Welcome back!')
      : const Text('Please login');
}
Phone Authentication Provider (phoneAuthProvider)
Manages phone authentication state during the OTP process.

dart
final phoneAuth = ref.watch(phoneAuthProvider);
Properties
Property	Type	Description
phoneNumber	String?	Entered phone number
verificationId	String?	Firebase verification ID
otpCode	String?	Entered OTP code
isCodeSent	bool	Whether verification code was sent
isLoading	bool	Whether loading is in progress
error	String?	Error message if any
resendToken	int?	Resend token for Firebase
Usage Examples
dart
Widget build(BuildContext context, WidgetRef ref) {
  final phoneAuth = ref.watch(phoneAuthProvider);
  
  return Column(
    children: [
      if (phoneAuth.isLoading) 
        const CircularProgressIndicator(),
      if (phoneAuth.error != null)
        Text('Error: ${phoneAuth.error}', style: TextStyle(color: Colors.red)),
      if (phoneAuth.isCodeSent)
        Text('Code sent to ${phoneAuth.phoneNumber}'),
      Text('Phone: ${phoneAuth.phoneNumber ?? "Not set"}'),
      Text('Code Sent: ${phoneAuth.isCodeSent}'),
    ],
  );
}
Methods (Notifiers)
Auth State Notifier Methods
Get the notifier:

dart
final authNotifier = ref.read(authStateProvider.notifier);
Method	Description	Returns
signOut()	Signs out the current user	Future<void>
setLoading()	Sets loading state	void
setError(String msg)	Sets error message	void
Usage Examples
dart
// Sign out user
await ref.read(authStateProvider.notifier).signOut();

// Set custom loading state
ref.read(authStateProvider.notifier).setLoading();

// Set error message
ref.read(authStateProvider.notifier).setError('Authentication failed');

// After sign out, navigate to login
if (context.mounted) {
  context.go('/login');
}
Phone Auth Notifier Methods
Get the notifier:

dart
final phoneNotifier = ref.read(phoneAuthProvider.notifier);
Method	Description	Returns
setPhoneNumber(String number)	Sets phone number	void
setVerificationId(String id)	Sets verification ID	void
setLoading(bool loading)	Sets loading state	void
setError(String error)	Sets error message	void
clearError()	Clears error message	void
reset()	Resets all phone auth state	void
setOtp(String otp)	Sets OTP code	void
Usage Examples
dart
// Set phone number
ref.read(phoneAuthProvider.notifier).setPhoneNumber('+1234567890');

// Set verification ID from Firebase
ref.read(phoneAuthProvider.notifier).setVerificationId('verification_id_here');

// Set loading state
ref.read(phoneAuthProvider.notifier).setLoading(true);

// Set error message
ref.read(phoneAuthProvider.notifier).setError('Invalid phone number');

// Clear error
ref.read(phoneAuthProvider.notifier).clearError();

// Reset all state (use after OTP verification)
ref.read(phoneAuthProvider.notifier).reset();

// Set OTP code
ref.read(phoneAuthProvider.notifier).setOtp('123456');
Complete Usage Examples
1. Check Authentication Status
dart
Widget build(BuildContext context, WidgetRef ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final authState = ref.watch(authStateProvider);
  
  if (authState.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  
  if (isAuthenticated) {
    return Center(child: Text('Welcome ${authState.user?.phoneNumber}'));
  }
  
  return const Center(child: Text('Please login'));
}
2. Get User Information
dart
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider);
  
  return Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UID: ${user?.uid ?? "N/A"}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Phone: ${user?.phoneNumber ?? "N/A"}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Email: ${user?.email ?? "N/A"}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Name: ${user?.displayName ?? "N/A"}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Phone Verified: ${user?.isPhoneVerified}', style: const TextStyle(fontSize: 14)),
          Text('Email Verified: ${user?.isEmailVerified}', style: const TextStyle(fontSize: 14)),
        ],
      ),
    ),
  );
}
3. Handle Loading and Error States
dart
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  
  switch (authState.status) {
    case AuthStatus.loading:
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
      
    case AuthStatus.authenticated:
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('Welcome ${authState.user?.phoneNumber}'),
          ],
        ),
      );
      
    case AuthStatus.error:
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${authState.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Retry logic
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      
    default:
      return const Center(child: Text('Please login'));
  }
}
4. Listen to Authentication Changes
dart
class MyWidget extends ConsumerStatefulWidget {
  const MyWidget({super.key});

  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  void initState() {
    super.initState();
    
    // Listen to auth changes
    ref.listen(authStateProvider, (previous, next) {
      if (next.isAuthenticated) {
        print('User logged in: ${next.user?.phoneNumber}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
        );
      } else if (next.isUnauthenticated) {
        print('User logged out');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out')),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.errorMessage}')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      body: Center(
        child: Text('Status: ${authState.status}'),
      ),
    );
  }
}
5. Sign Out with Confirmation
dart
Widget build(BuildContext context, WidgetRef ref) {
  return ElevatedButton(
    onPressed: () async {
      // Show confirmation dialog
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );
      
      if (shouldSignOut == true) {
        await ref.read(authStateProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    child: const Text('Sign Out'),
  );
}
6. Phone Authentication State
dart
Widget build(BuildContext context, WidgetRef ref) {
  final phoneAuth = ref.watch(phoneAuthProvider);
  
  return Column(
    children: [
      if (phoneAuth.isLoading)
        const LinearProgressIndicator(),
        
      if (phoneAuth.error != null)
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Text(
            phoneAuth.error!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        
      if (phoneAuth.isCodeSent)
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            children: [
              const Text('Verification code sent!'),
              Text('To: ${phoneAuth.phoneNumber}'),
            ],
          ),
        ),
        
      const SizedBox(height: 16),
      Text('Phone: ${phoneAuth.phoneNumber ?? "Not set"}'),
      Text('Code Sent: ${phoneAuth.isCodeSent}'),
      Text('Loading: ${phoneAuth.isLoading}'),
    ],
  );
}
7. Protected Route Example
dart
class ProtectedRoute extends ConsumerWidget {
  final Widget child;
  
  const ProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final authState = ref.watch(authStateProvider);
    
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!isAuthenticated) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return child;
  }
}

// Usage:
// In your router:
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProtectedRoute(
    child: ProfilePage(),
  ),
),
8. Complete App with Custom Router
dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_auth/dot_auth.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = authState.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';
        final isOtpRoute = state.matchedLocation == '/otp';
        
        if (isAuthenticated && (isLoginRoute || isOtpRoute)) {
          return '/home';
        }
        
        if (!isAuthenticated && state.matchedLocation == '/home') {
          return '/login';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const AuthPhone(),
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          builder: (context, state) => const OtpScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              path: 'profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'My App',
      theme: authTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
AuthStatus Enum
Value	Description
AuthStatus.initial	Initial state, not authenticated
AuthStatus.loading	Loading (verifying or signing in)
AuthStatus.authenticated	User is authenticated
AuthStatus.unauthenticated	User is not authenticated
AuthStatus.error	Error occurred
Usage:
dart
final authState = ref.watch(authStateProvider);

switch (authState.status) {
  case AuthStatus.initial:
    return const Text('Initializing...');
  case AuthStatus.loading:
    return const CircularProgressIndicator();
  case AuthStatus.authenticated:
    return Text('Welcome ${authState.user?.phoneNumber}');
  case AuthStatus.unauthenticated:
    return const Text('Please login');
  case AuthStatus.error:
    return Text('Error: ${authState.errorMessage}');
}
Quick Reference Card
dart
// Most commonly used - Copy these!

// 1. Check if user is logged in
final isAuth = ref.watch(isAuthenticatedProvider);

// 2. Get current user
final user = ref.watch(currentUserProvider);

// 3. Get full auth state
final authState = ref.watch(authStateProvider);

// 4. Auth state checks
authState.isAuthenticated     // bool
authState.isLoading          // bool
authState.status             // AuthStatus enum

// 5. User data (from authState.user or currentUserProvider)
user?.uid                    // String
user?.phoneNumber           // String?
user?.email                 // String?
user?.displayName           // String?
user?.photoURL              // String?
user?.creationTime          // DateTime?
user?.lastSignInTime        // DateTime?
user?.isEmailVerified       // bool
user?.isPhoneVerified       // bool

// 6. Phone auth state
final phoneAuth = ref.watch(phoneAuthProvider);
phoneAuth.phoneNumber        // String?
phoneAuth.verificationId     // String?
phoneAuth.isCodeSent         // bool
phoneAuth.isLoading          // bool
phoneAuth.error              // String?

// 7. Actions
await ref.read(authStateProvider.notifier).signOut();

// 8. Navigation after sign out
context.go('/login');
context.pushReplacement('/login');
Need Help?
📚 Full Documentation

💡 Report Issues

⭐ Star on GitHub

License
MIT License - see LICENSE file for details.

Made with ❤️ for the Flutter community


