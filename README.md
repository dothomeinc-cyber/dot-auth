Yes, please! Here's the corrected README with all missing providers and fixed router examples:

```markdown
# dot_auth

A Flutter package for phone and email-based Firebase authentication with Riverpod state management and GoRouter navigation — batteries included.

[![pub version](https://img.shields.io/badge/pub-v1.0.0-blue)](https://pub.dev)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)

---

## Table of Contents

- [Dependencies](#dependencies)
- [Quick Start](#quick-start)
  - [1. Setup Firebase](#1-setup-firebase)
  - [2. Initialize in main()](#2-initialize-in-main)
  - [3. Configure Router](#3-configure-router)
- [Providers](#providers)
  - [authStateProvider](#authstateprovider)
  - [currentUserProvider](#currentuserprovider)
  - [Convenience Providers](#convenience-providers)
  - [phoneAuthProvider](#phoneauthprovider)
  - [emailAuthProvider](#emailauthprovider)
- [Methods (Notifiers)](#methods-notifiers)
  - [Auth State Notifier](#auth-state-notifier)
  - [Phone Auth Notifier](#phone-auth-notifier)
  - [Email Auth Notifier](#email-auth-notifier)
- [AuthStatus Enum](#authstatus-enum)
- [Usage Examples](#usage-examples)
- [Custom Router (Manual Setup)](#custom-router-manual-setup)
- [Quick Reference Card](#quick-reference-card)

---

## Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  dot_auth: ^1.0.0
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  flutter_riverpod: ^3.3.1
  go_router: ^17.3.0
  flutter_screenutil: ^5.9.0
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

### 1. Setup Firebase

Follow the [Firebase setup guide](https://firebase.google.com/docs/flutter/setup) for your platform. This generates `firebase_options.dart`.

### 2. Initialize in main()

```dart
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
```

### 3. Configure Router

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AuthRouter.createRouter(
      ref: ref,
      homeRoute: '/home',
      homeBuilder: (context, state) => const HomePage(),
      email: true, // Enable email authentication
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
        child: Text('Welcome ${user?.phoneNumber ?? user?.email ?? "User"}'),
      ),
    );
  }
}
```

---

## Providers

### authStateProvider

The main provider for authentication state. Watch this to get all auth-related information.

```dart
final authState = ref.watch(authStateProvider);
```

#### Auth State Properties

| Property | Type | Description |
|---|---|---|
| `status` | `AuthStatus` | Current auth status (`initial`, `loading`, `authenticated`, `unauthenticated`, `error`) |
| `isAuthenticated` | `bool` | `true` if user is logged in |
| `isLoading` | `bool` | `true` if authentication is in progress |
| `isUnauthenticated` | `bool` | `true` if user is not logged in |
| `user` | `UserModel?` | Current user data or `null` |
| `errorMessage` | `String?` | Error message if authentication failed |

#### User Properties (`authState.user`)

| Property | Type | Description |
|---|---|---|
| `uid` | `String` | Unique user ID |
| `phoneNumber` | `String?` | User's phone number |
| `email` | `String?` | User's email address |
| `displayName` | `String?` | User's display name |
| `photoURL` | `String?` | User's photo URL |
| `creationTime` | `DateTime?` | Account creation time |
| `lastSignInTime` | `DateTime?` | Last login time |
| `isEmailVerified` | `bool` | Email verification status |
| `isPhoneVerified` | `bool` | Phone verification status |

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);

  if (authState.isAuthenticated) {
    return Text('Welcome ${authState.user?.phoneNumber ?? authState.user?.email}');
  }

  if (authState.isLoading) {
    return const CircularProgressIndicator();
  }

  if (authState.errorMessage != null) {
    return Text('Error: ${authState.errorMessage}');
  }

  return const Text('Please login');
}
```

---

### currentUserProvider

A simplified provider that returns only the current user.

```dart
final user = ref.watch(currentUserProvider);
```

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) return const Text('Not logged in');

  return Column(
    children: [
      Text('Phone: ${user.phoneNumber ?? "N/A"}'),
      Text('Email: ${user.email ?? "N/A"}'),
      Text('UID: ${user.uid}'),
      Text('Verified: ${user.isPhoneVerified}'),
      Text('Name: ${user.displayName ?? "No name"}'),
    ],
  );
}
```

---

### Convenience Providers

These providers give you quick access to specific user properties without watching the full auth state.

```dart
// User information
final uid = ref.watch(currentUidProvider);          // String? - Firebase UID
final phone = ref.watch(currentPhoneProvider);      // String? - Phone number
final email = ref.watch(currentEmailProvider);      // String? - Email address

// Status flags
final isEmailVerified = ref.watch(isEmailVerifiedProvider);    // bool
final isPhoneVerified = ref.watch(isPhoneVerifiedProvider);    // bool

// Auth state
final isLoading = ref.watch(isAuthLoadingProvider);            // bool
final status = ref.watch(authStatusProvider);                  // AuthStatus
final error = ref.watch(authErrorProvider);                    // String?
```

**Common usage:**

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final email = ref.watch(currentEmailProvider);
  final phone = ref.watch(currentPhoneProvider);
  final isVerified = ref.watch(isEmailVerifiedProvider);

  return Column(
    children: [
      Text('Email: ${email ?? "Not set"}'),
      Text('Phone: ${phone ?? "Not set"}'),
      if (isVerified) 
        const Icon(Icons.verified, color: Colors.green),
    ],
  );
}
```

---

### phoneAuthProvider

Manages phone authentication state during the OTP process.

```dart
final phoneAuth = ref.watch(phoneAuthProvider);
```

#### OTP / Verification State Properties

| Property | Type | Description |
|---|---|---|
| `phoneNumber` | `String?` | Entered phone number |
| `verificationId` | `String?` | Firebase verification ID |
| `otpCode` | `String?` | Entered OTP code |
| `isCodeSent` | `bool` | Whether the verification code was sent |
| `isLoading` | `bool` | Whether loading is in progress |
| `error` | `String?` | Error message if any |
| `resendToken` | `int?` | Resend token for Firebase |

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final phoneAuth = ref.watch(phoneAuthProvider);

  return Column(
    children: [
      if (phoneAuth.isLoading) const CircularProgressIndicator(),
      if (phoneAuth.error != null)
        Text('Error: ${phoneAuth.error}', style: TextStyle(color: Colors.red)),
      if (phoneAuth.isCodeSent)
        Text('Code sent to ${phoneAuth.phoneNumber}'),
      Text('Phone: ${phoneAuth.phoneNumber ?? "Not set"}'),
      Text('Code Sent: ${phoneAuth.isCodeSent}'),
    ],
  );
}
```

---

### emailAuthProvider

Manages email/password authentication state.

```dart
final emailAuth = ref.watch(emailAuthProvider);
```

#### Email Auth State Properties

| Property | Type | Description |
|---|---|---|
| `email` | `String?` | Entered email address |
| `mode` | `EmailAuthMode` | Current mode: `.signIn`, `.signUp`, `.forgotPassword` |
| `isLoading` | `bool` | Whether loading is in progress |
| `error` | `String?` | Error message if any |
| `isPasswordResetSent` | `bool` | Whether password reset email was sent |

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final emailAuth = ref.watch(emailAuthProvider);

  return Column(
    children: [
      if (emailAuth.isLoading) const CircularProgressIndicator(),
      if (emailAuth.error != null)
        Text('Error: ${emailAuth.error}', style: TextStyle(color: Colors.red)),
      if (emailAuth.isPasswordResetSent)
        const Text('Password reset email sent!'),
      Text('Email: ${emailAuth.email ?? "Not set"}'),
      Text('Mode: ${emailAuth.mode}'),
    ],
  );
}
```

---

## Methods (Notifiers)

### Auth State Notifier

```dart
final authNotifier = ref.read(authStateProvider.notifier);
```

| Method | Returns | Description |
|---|---|---|
| `signOut()` | `Future<void>` | Signs out the current user |

```dart
// Sign out user
await ref.read(authStateProvider.notifier).signOut();

// After sign out, navigate to login
if (context.mounted) {
  context.go('/login');
}
```

**Note:** `AuthStateNotifier` automatically manages `loading` and `error` states via the Firebase auth stream. You don't need to manually set these.

---

### Phone Auth Notifier

```dart
final phoneNotifier = ref.read(phoneAuthProvider.notifier);
```

| Method | Returns | Description |
|---|---|---|
| `setPhoneNumber(String number)` | `void` | Sets the phone number |
| `setVerificationData(String verificationId, int? resendToken)` | `void` | Sets the verification ID and optional resend token |
| `setLoading(bool loading)` | `void` | Sets the loading state |
| `setError(String error)` | `void` | Sets an error message |
| `clearError()` | `void` | Clears the current error |
| `reset()` | `void` | Resets all phone auth state |
| `setOtp(String otp)` | `void` | Sets the OTP code |

```dart
ref.read(phoneAuthProvider.notifier).setPhoneNumber('+1234567890');
ref.read(phoneAuthProvider.notifier).setVerificationData('verification_id_here', 123);
ref.read(phoneAuthProvider.notifier).setLoading(true);
ref.read(phoneAuthProvider.notifier).setError('Invalid phone number');
ref.read(phoneAuthProvider.notifier).clearError();
ref.read(phoneAuthProvider.notifier).reset(); // use after OTP verification
ref.read(phoneAuthProvider.notifier).setOtp('123456');
```

---

### Email Auth Notifier

```dart
final emailNotifier = ref.read(emailAuthProvider.notifier);
```

| Method | Returns | Description |
|---|---|---|
| `signIn(String email, String password)` | `Future<void>` | Signs in with email and password |
| `signUp(String email, String password)` | `Future<void>` | Creates a new account |
| `sendPasswordReset(String email)` | `Future<void>` | Sends password reset email |
| `setEmail(String email)` | `void` | Sets the email address |
| `setMode(EmailAuthMode mode)` | `void` | Switches between sign in, sign up, forgot password |
| `setLoading(bool loading)` | `void` | Sets loading state |
| `setError(String error)` | `void` | Sets error message |
| `clearError()` | `void` | Clears error |
| `reset()` | `void` | Resets all email auth state |

#### Email Auth Method Usage

```dart
// 1. Sign In with Email and Password
await ref.read(emailAuthProvider.notifier).signIn(
  'user@example.com',
  'password123',
);
// On success, authStateProvider updates automatically
if (context.mounted) context.go('/home');

// 2. Sign Up / Create Account
await ref.read(emailAuthProvider.notifier).signUp(
  'user@example.com',
  'password123',
);
// On success, authStateProvider updates automatically
if (context.mounted) context.go('/home');

// 3. Send Password Reset Email
await ref.read(emailAuthProvider.notifier).sendPasswordReset(
  'user@example.com',
);
// On success, isPasswordResetSent becomes true

// 4. Switch Mode
ref.read(emailAuthProvider.notifier).setMode(EmailAuthMode.signIn);
ref.read(emailAuthProvider.notifier).setMode(EmailAuthMode.signUp);
ref.read(emailAuthProvider.notifier).setMode(EmailAuthMode.forgotPassword);

// 5. Set Email
ref.read(emailAuthProvider.notifier).setEmail('user@example.com');

// 6. Set Loading
ref.read(emailAuthProvider.notifier).setLoading(true);

// 7. Set Error
ref.read(emailAuthProvider.notifier).setError('Invalid email or password');

// 8. Clear Error
ref.read(emailAuthProvider.notifier).clearError();

// 9. Reset State
ref.read(emailAuthProvider.notifier).reset();
```

**Note:** All error handling is internal. Methods set `state.error` instead of throwing exceptions.

#### EmailAuthMode Enum

```dart
enum EmailAuthMode {
  signIn,          // Sign in with email and password
  signUp,          // Create new account
  forgotPassword,  // Send password reset link
}
```

---

## AuthStatus Enum

| Value | Description |
|---|---|
| `AuthStatus.initial` | Initial state, not yet checked |
| `AuthStatus.loading` | Loading — verifying or signing in |
| `AuthStatus.authenticated` | User is authenticated |
| `AuthStatus.unauthenticated` | User is not authenticated |
| `AuthStatus.error` | An error occurred |

```dart
final authState = ref.watch(authStateProvider);

switch (authState.status) {
  case AuthStatus.initial:
    return const Text('Initializing...');
  case AuthStatus.loading:
    return const CircularProgressIndicator();
  case AuthStatus.authenticated:
    return Text('Welcome ${authState.user?.phoneNumber ?? authState.user?.email}');
  case AuthStatus.unauthenticated:
    return const Text('Please login');
  case AuthStatus.error:
    return Text('Error: ${authState.errorMessage}');
}
```

---

## Usage Examples

### 1. Check Authentication Status

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (isAuthenticated) {
    return Center(
      child: Text('Welcome ${authState.user?.phoneNumber ?? authState.user?.email}'),
    );
  }

  return const Center(child: Text('Please login'));
}
```

### 2. Get User Information

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider);

  return Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UID: ${user?.uid ?? "N/A"}'),
          Text('Phone: ${user?.phoneNumber ?? "N/A"}'),
          Text('Email: ${user?.email ?? "N/A"}'),
          Text('Name: ${user?.displayName ?? "N/A"}'),
          Text('Phone Verified: ${user?.isPhoneVerified}'),
          Text('Email Verified: ${user?.isEmailVerified}'),
        ],
      ),
    ),
  );
}
```

### 3. Using Convenience Providers

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final uid = ref.watch(currentUidProvider);
  final email = ref.watch(currentEmailProvider);
  final phone = ref.watch(currentPhoneProvider);
  final isVerified = ref.watch(isEmailVerifiedProvider);
  final isLoading = ref.watch(isAuthLoadingProvider);
  final status = ref.watch(authStatusProvider);

  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (uid == null) {
    return const Center(child: Text('Please login'));
  }

  return Column(
    children: [
      Text('UID: $uid'),
      Text('Email: ${email ?? "Not set"}'),
      Text('Phone: ${phone ?? "Not set"}'),
      Text('Status: $status'),
      if (isVerified) 
        const Icon(Icons.verified, color: Colors.green),
    ],
  );
}
```

### 4. Handle Loading and Error States

```dart
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
            Text('Welcome ${authState.user?.phoneNumber ?? authState.user?.email}'),
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
              onPressed: () { /* retry logic */ },
              child: const Text('Retry'),
            ),
          ],
        ),
      );

    default:
      return const Center(child: Text('Please login'));
  }
}
```

### 5. Listen to Authentication Changes

```dart
class MyWidget extends ConsumerStatefulWidget {
  const MyWidget({super.key});

  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  void initState() {
    super.initState();

    ref.listen(authStateProvider, (previous, next) {
      if (next.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
        );
      } else if (next.isUnauthenticated) {
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      body: Center(child: Text('Status: ${authState.status}')),
    );
  }
}
```

### 6. Sign Out with Confirmation

```dart
Widget build(BuildContext context, WidgetRef ref) {
  return ElevatedButton(
    onPressed: () async {
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
        if (context.mounted) context.go('/login');
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    child: const Text('Sign Out'),
  );
}
```

### 7. Phone Authentication State

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final phoneAuth = ref.watch(phoneAuthProvider);

  return Column(
    children: [
      if (phoneAuth.isLoading) const LinearProgressIndicator(),

      if (phoneAuth.error != null)
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Text(phoneAuth.error!, style: const TextStyle(color: Colors.red)),
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
```

### 8. Protected Route

```dart
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

// Usage in router:
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProtectedRoute(child: ProfilePage()),
),
```

---

## Custom Router (Manual Setup)

If you build your own router instead of using `AuthRouter.createRouter()`, you **must** wire up `RouterNotifier` manually:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_auth/dot_auth.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Create RouterNotifier to listen to auth changes
  final routerNotifier = RouterNotifier(ref);
  
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: routerNotifier,  // REQUIRED - enables auto-redirect
    redirect: routerNotifier.redirect,  // REQUIRED - uses default redirect logic
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthPhone(emailEnabled: true),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/email',
        name: 'email',
        builder: (context, state) => const AuthEmail(phoneEnabled: true),
      ),
      
      // Protected routes
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
      
      // Terms & Privacy routes (required for TcFooter)
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
    ],
  );
});
```

> **Important:** Omitting `refreshListenable` and `redirect` means the router will not react to auth state changes automatically. Your users would stay on the login page even after signing in.

### Using in your app:

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'My App',
      theme: authTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## Quick Reference Card

```dart
// ─── AUTH STATE ──────────────────────────────────────────────────────────

// 1. Check if user is logged in
final isAuth = ref.watch(isAuthenticatedProvider);

// 2. Get current user
final user = ref.watch(currentUserProvider);

// 3. Get full auth state
final authState = ref.watch(authStateProvider);

// 4. Auth state checks
authState.isAuthenticated     // bool
authState.isLoading           // bool
authState.status              // AuthStatus enum

// 5. Convenience providers
final uid = ref.watch(currentUidProvider);              // String?
final email = ref.watch(currentEmailProvider);          // String?
final phone = ref.watch(currentPhoneProvider);          // String?
final isEmailVerified = ref.watch(isEmailVerifiedProvider);    // bool
final isPhoneVerified = ref.watch(isPhoneVerifiedProvider);    // bool
final isLoading = ref.watch(isAuthLoadingProvider);            // bool
final status = ref.watch(authStatusProvider);                  // AuthStatus
final error = ref.watch(authErrorProvider);                    // String?

// 6. User data
user?.uid                     // String
user?.phoneNumber             // String?
user?.email                   // String?
user?.displayName             // String?
user?.photoURL                // String?
user?.creationTime            // DateTime?
user?.lastSignInTime          // DateTime?
user?.isEmailVerified         // bool
user?.isPhoneVerified         // bool

// 7. Sign out
await ref.read(authStateProvider.notifier).signOut();


// ─── PHONE AUTH ──────────────────────────────────────────────────────────

// 1. Watch phone auth state
final phoneAuth = ref.watch(phoneAuthProvider);

// 2. Phone auth properties
phoneAuth.phoneNumber         // String?
phoneAuth.verificationId      // String?
phoneAuth.otpCode             // String?
phoneAuth.isCodeSent          // bool
phoneAuth.isLoading           // bool
phoneAuth.error               // String?
phoneAuth.resendToken         // int?

// 3. Phone auth methods
ref.read(phoneAuthProvider.notifier).setPhoneNumber('+1234567890');
ref.read(phoneAuthProvider.notifier).setVerificationData('verification_id', 123);
ref.read(phoneAuthProvider.notifier).setLoading(true);
ref.read(phoneAuthProvider.notifier).setError('Invalid number');
ref.read(phoneAuthProvider.notifier).clearError();
ref.read(phoneAuthProvider.notifier).reset();
ref.read(phoneAuthProvider.notifier).setOtp('123456');


// ─── EMAIL AUTH ──────────────────────────────────────────────────────────

// 1. Watch email auth state
final emailAuth = ref.watch(emailAuthProvider);

// 2. Email auth properties
emailAuth.email               // String?
emailAuth.mode                // EmailAuthMode
emailAuth.isLoading           // bool
emailAuth.error               // String?
emailAuth.isPasswordResetSent // bool

// 3. Email auth methods
await ref.read(emailAuthProvider.notifier).signIn('user@example.com', 'password');
await ref.read(emailAuthProvider.notifier).signUp('user@example.com', 'password');
await ref.read(emailAuthProvider.notifier).sendPasswordReset('user@example.com');
ref.read(emailAuthProvider.notifier).setEmail('user@example.com');
ref.read(emailAuthProvider.notifier).setMode(EmailAuthMode.signIn);
ref.read(emailAuthProvider.notifier).setLoading(true);
ref.read(emailAuthProvider.notifier).setError('Invalid email');
ref.read(emailAuthProvider.notifier).clearError();
ref.read(emailAuthProvider.notifier).reset();

// 4. EmailAuthMode values
EmailAuthMode.signIn
EmailAuthMode.signUp
EmailAuthMode.forgotPassword


// ─── NAVIGATION ──────────────────────────────────────────────────────────

// Navigate after sign in/out
context.go('/home');
context.pushReplacement('/login');
context.pop();
```

---

## Need Help?

- 📚 [Full Documentation](#)
- 💡 [Report Issues](#)
- ⭐ [Star on GitHub](#)

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Made with ❤️ for the Flutter community*
```