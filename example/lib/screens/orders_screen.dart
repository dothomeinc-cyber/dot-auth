import 'package:dot_auth/dot_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A route registered through `additionalRoutes`.
///
/// It carries no auth check of its own — the redirect denies by default, so a
/// signed-out user opening `/orders` is sent to the phone screen.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Center(
        child: Text('Orders for ${user?.uid ?? 'nobody'}'),
      ),
    );
  }
}
