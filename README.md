# Dot Auth 🔐

![Pub Version](https://img.shields.io/pub/v/dot_auth.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A powerful and reusable Flutter authentication package with phone number OTP verification using Firebase. Built with Riverpod for state management and GoRouter for navigation.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Authentication State Provider](#authentication-state-provider-authstateprovider)
- [Current User Provider](#current-user-provider-currentuserprovider)
- [Authentication Status Provider](#authentication-status-provider-isauthenticatedprovider)
- [Phone Authentication Provider](#phone-authentication-provider-phoneauthprovider)
- [Methods (Notifiers)](#methods-notifiers)
- [Complete Usage Examples](#complete-usage-examples)
- [AuthStatus Enum](#authstatus-enum)
- [Quick Reference Card](#quick-reference-card)
- [Firestore Security Rules](#firestore-security-rules)
- [User Service to Manage User Type](#user-service-to-manage-user-type)
- [Need Help?](#need-help)
- [License](#license)

## Features

✅ **Phone Authentication** - OTP verification with Firebase
✅ **Riverpod Integration** - Clean and testable state management
✅ **GoRouter Support** - Declarative routing with auth guards
✅ **Responsive Design** - ScreenUtil for adaptive UI
✅ **Customizable Theme** - Easy to match your brand
✅ **Type Safety** - Full type-safe models and providers
✅ **Ready-to-use UI** - Beautiful pre-built screens

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dot_auth: ^1.0.0
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  flutter_screenutil: ^5.9.0

Then run :
   flutter pub get


Quick Start

1. Setup Firebase 
Follow the Firebase setup guide for your platform.

2. Initialize in your app

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

final authState = ref.watch(authStateProvider);


## Authentication State Properties

## Authentication State Properties

### Auth State

| Property | Type | Description |
|----------|------|-------------|
| `status` | AuthStatus | Current authentication status (initial, loading, authenticated, unauthenticated, error) |
| `isAuthenticated` | bool | true if user is logged in |
| `isLoading` | bool | true if authentication is in progress |
| `isUnauthenticated` | bool | true if user is not logged in |
| `user` | UserModel? | Current user data or null |
| `errorMessage` | String? | Error message if authentication failed |

### User Details (from `authState.user`)

| Property | Type | Description |
|----------|------|-------------|
| `uid` | String | Unique user ID |
| `phoneNumber` | String? | User's phone number |
| `email` | String? | User's email address |
| `displayName` | String? | User's display name |
| `photoURL` | String? | User's photo URL |
| `creationTime` | DateTime? | Account creation time |
| `lastSignInTime` | DateTime? | Last login time |
| `isEmailVerified` | bool | Email verification status |
| `isPhoneVerified` | bool | Phone verification status |


Usage Example

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

final user = ref.watch(currentUserProvider);

Usage Examples:

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


final isAuthenticated = ref.watch(isAuthenticatedProvider);
// Returns: true if user is logged in, false otherwise

Usage Examples:

Widget build(BuildContext context, WidgetRef ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return isAuthenticated 
      ? const Text('Welcome back!')
      : const Text('Please login');
}

Phone Authentication Provider (phoneAuthProvider)

Manages phone authentication state during the OTP process.

final phoneAuth = ref.watch(phoneAuthProvider);

## OTP / Verification State Properties

| Property | Type | Description |
|----------|------|-------------|
| `phoneNumber` | String? | Entered phone number |
| `verificationId` | String? | Firebase verification ID |
| `otpCode` | String? | Entered OTP code |
| `isCodeSent` | bool | Whether verification code was sent |
| `isLoading` | bool | Whether loading is in progress |
| `error` | String? | Error message if any |
| `resendToken` | int? | Resend token for Firebase |


Usage Examples:

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

final authNotifier = ref.read(authStateProvider.notifier);

## Authentication Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `signOut()` | Signs out the current user | `Future<void>` |
| `setLoading()` | Sets loading state | `void` |
| `setError(String msg)` | Sets error message | `void` |

Usage Examples:

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

final phoneNotifier = ref.read(phoneAuthProvider.notifier);

## Phone Auth Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `setPhoneNumber(String number)` | Sets phone number | `void` |
| `setVerificationId(String id)` | Sets verification ID | `void` |
| `setLoading(bool loading)` | Sets loading state | `void` |
| `setError(String error)` | Sets error message | `void` |
| `clearError()` | Clears error message | `void` |
| `reset()` | Resets all phone auth state | `void` |
| `setOtp(String otp)` | Sets OTP code | `void` |

Usage Examples:

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

## AuthStatus Enum

| Value | Description |
|-------|-------------|
| `AuthStatus.initial` | Initial state, not authenticated |
| `AuthStatus.loading` | Loading (verifying or signing in) |
| `AuthStatus.authenticated` | User is authenticated |
| `AuthStatus.unauthenticated` | User is not authenticated |
| `AuthStatus.error` | Error occurred |

Usage:

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



Firestore Security Rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function: Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function: Get user's role from users collection
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType;
    }
    
    // Helper function: Check if user is vendor
    function isVendor() {
      return getUserRole() == 'vendor';
    }
    
    // Helper function: Check if user is admin
    function isAdmin() {
      return getUserRole() == 'admin';
    }
    
    // Helper function: Check if user is customer
    function isCustomer() {
      return getUserRole() == 'customer';
    }
    
    // Helper function: Check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // ============================================
    // USERS COLLECTION - Anyone can read, only owner can write
    // ============================================
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isOwner(userId);
    }
    
    // ============================================
    // VENDORS COLLECTION - Vendor specific data
    // ============================================
    match /vendors/{vendorId} {
      // Read: Anyone authenticated can read vendor details
      allow read: if isAuthenticated();
      
      // Create: Any authenticated user can register as vendor
      allow create: if isAuthenticated();
      
      // Update: Only the vendor themselves OR admin
      allow update: if isAuthenticated() && (isOwner(vendorId) || isAdmin());
      
      // Delete: Only admin
      allow delete: if isAuthenticated() && isAdmin();
    }
    
    // ============================================
    // PRODUCTS COLLECTION - Vendor products
    // ============================================
    match /products/{productId} {
      // Read: Anyone authenticated can view products
      allow read: if isAuthenticated();
      
      // Create: Only vendors can create products
      allow create: if isAuthenticated() && isVendor();
      
      // Update: Only the vendor who owns this product
      allow update: if isAuthenticated() && 
        (isVendor() && resource.data.vendorId == request.auth.uid) || isAdmin();
      
      // Delete: Only vendor who owns it or admin
      allow delete: if isAuthenticated() && 
        (isVendor() && resource.data.vendorId == request.auth.uid) || isAdmin();
    }
    
    // ============================================
    // ORDERS COLLECTION - Customer orders
    // ============================================
    match /orders/{orderId} {
      // Read: Customer can read their own orders, Vendors can read orders for their products
      allow read: if isAuthenticated() && (
        resource.data.customerId == request.auth.uid ||  // Customer's own orders
        isVendor() && resource.data.vendorId == request.auth.uid ||  // Vendor's orders
        isAdmin()
      );
      
      // Create: Only customers can create orders
      allow create: if isAuthenticated() && isCustomer();
      
      // Update: Customer can update their own orders (before shipping), Vendor can update status
      allow update: if isAuthenticated() && (
        (isCustomer() && resource.data.customerId == request.auth.uid) ||
        (isVendor() && resource.data.vendorId == request.auth.uid) ||
        isAdmin()
      );
    }
    
    // ============================================
    // REVIEWS COLLECTION - Product reviews
    // ============================================
    match /reviews/{reviewId} {
      // Read: Anyone authenticated can read reviews
      allow read: if isAuthenticated();
      
      // Create: Only customers who purchased can review
      allow create: if isAuthenticated() && isCustomer();
      
      // Update/Delete: Only review owner or admin
      allow update, delete: if isAuthenticated() && 
        (isOwner(resource.data.userId) || isAdmin());
    }
    
    // ============================================
    // CATEGORIES COLLECTION - Public read, admin write
    // ============================================
    match /categories/{categoryId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isAdmin();
    }
  }
}

User Service to Manage User Type

// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create/Update user document after login
  Future<void> setUserType(String userId, String userType) async {
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'phoneNumber': _auth.currentUser?.phoneNumber,
      'userType': userType, // 'customer', 'vendor', 'admin'
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Check if current user is vendor
  Future<bool> isVendor() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['userType'] == 'vendor';
  }

  // Get user type
  Future<String> getUserType() async {
    final user = _auth.currentUser;
    if (user == null) return 'none';
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['userType'] ?? 'customer';
  }
}

After Login - Set User Type

// In your phone_screen.dart or main.dart after successful login

import 'package:cloud_firestore/cloud_firestore.dart';

// After FirebaseAuth sign in
Future<void> handleSuccessfulLogin(UserCredential credential) async {
  final user = credential.user;
  if (user != null) {
    // Check if user document exists
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!userDoc.exists) {
      // First time login - create as customer
      await UserService().setUserType(user.uid, 'customer');
    }
  }
}

Vendor Registration - Create Vendor Document

// lib/screens/register_vendor.dart

Future<void> registerAsVendor() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  // Update user type to vendor
  await UserService().setUserType(user.uid, 'vendor');
  
  // Create vendor document
  await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
    'vendorId': user.uid,
    'businessName': businessName,
    'phoneNumber': user.phoneNumber,
    'status': 'approved', // or 'pending'
    'createdAt': FieldValue.serverTimestamp(),
    'totalProducts': 0,
    'rating': 0,
  });
}


Vendor-Only Actions

// lib/screens/add_product.dart - Only vendors can add products

class AddProductScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: UserService().isVendor(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64),
                  const SizedBox(height: 16),
                  const Text('Only vendors can add products'),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register-vendor'),
                    child: const Text('Register as Vendor'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return _AddProductForm();
      },
    );
  }
}

class _AddProductForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                
                // Security rules will verify this is a vendor
                await FirebaseFirestore.instance.collection('products').add({
                  'name': 'Product Name',
                  'price': 100,
                  'description': 'Description',
                  'vendorId': user!.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product added!')),
                );
              },
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}

Riverpod Provider for User Type

// lib/providers/user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';

final userTypeProvider = FutureProvider<String>((ref) async {
  return await UserService().getUserType();
});

final isVendorProvider = FutureProvider<bool>((ref) async {
  return await UserService().isVendor();
});

// Auto-refresh when auth state changes
final vendorStatusProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final isVendorAsync = ref.watch(isVendorProvider);
  
  return isVendorAsync.when(
    data: (isVendor) => isVendor,
    loading: () => false,
    error: (_, __) => false,
  );
});


Creating Custom Router Manually:

If you create your own router manually (not using AuthRouter.createRouter()), then you do need to add it:

// Only needed if you make your own router
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerNotifier = RouterNotifier(ref);  // Create it
    
    final router = GoRouter(
      initialLocation: '/phone',
      refreshListenable: routerNotifier,  // YOU MUST ADD THIS
      redirect: routerNotifier.redirect,   // YOU MUST ADD THIS
      routes: [
        // Your routes
      ],
    );
    
    return MaterialApp.router(routerConfig: router);
  }
}

Need Help?
📚 Full Documentation

💡 Report Issues

⭐ Star on GitHub

License
MIT License - see LICENSE file for details.

Made with ❤️ for the Flutter community