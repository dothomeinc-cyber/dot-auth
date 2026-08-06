import 'package:dot_auth/dot_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Everything a host app typically needs from dot_auth after sign-in:
/// reading the session, nudging email verification, linking a second sign-in
/// method, signing out, and deleting the account.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final emailVerified = ref.watch(isEmailVerifiedProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Row(label: 'UID', value: user?.uid ?? '—'),
          _Row(label: 'Mobile', value: user?.phoneNumber ?? 'Not connected'),
          _Row(label: 'Email', value: user?.email ?? 'Not connected'),
          _Row(
            label: 'Sign-in methods',
            value: user?.providerIds.join(', ') ?? '—',
          ),

          // deleteAccount() attaches its failure here without dropping the
          // session, so the user can re-authenticate and retry.
          if (authState.errorMessage != null) ...[
            const SizedBox(height: 16),
            AuthErrorLine(message: authState.errorMessage!),
          ],

          if (!emailVerified) ...[
            const SizedBox(height: 24),
            _VerifyEmailCard(
              onResend: () async {
                final notifier = ref.read(authStateProvider.notifier);
                await notifier.sendEmailVerification();
                await notifier.reloadUser();
              },
              onRefresh: ref.read(authStateProvider.notifier).reloadUser,
            ),
          ],

          const SizedBox(height: 24),

          // A phone-only account can add an email login without ending up as
          // two separate users.
          if (user != null && !user.hasPasswordProvider)
            OutlinedButton(
              onPressed: () => _linkEmail(context, ref),
              child: const Text('Add an email login'),
            ),

          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push('/orders'),
            child: const Text('View orders'),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: ref.read(authStateProvider.notifier).signOut,
            child: const Text('Sign out'),
          ),

          const SizedBox(height: 8),
          // Both app stores require an in-app path to account deletion.
          TextButton(
            onPressed: () => _confirmDelete(context, ref),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkEmail(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add an email login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (submitted != true) return;

    final linked = await ref.read(authStateProvider.notifier).linkEmailPassword(
          emailController.text,
          passwordController.text,
        );

    emailController.dispose();
    passwordController.dispose();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          linked
              ? 'Email login connected.'
              : ref.read(authStateProvider).errorMessage ??
                  'Could not connect that email.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this account?'),
        content: const Text(
          'Your orders, addresses, and history go with it. This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await ref.read(authStateProvider.notifier).deleteAccount();
    if (deleted) return; // The redirect takes it from here.
    if (!context.mounted) return;

    // Most often Firebase wants a fresh sign-in first.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(authStateProvider).errorMessage ??
              'Could not delete the account.',
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AuthTextStyles.labelM),
          ),
          Expanded(child: Text(value, style: AuthTextStyles.bodyM)),
        ],
      ),
    );
  }
}

class _VerifyEmailCard extends StatelessWidget {
  final Future<void> Function() onResend;
  final Future<void> Function() onRefresh;

  const _VerifyEmailCard({required this.onResend, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify your email', style: AuthTextStyles.titleM),
          const SizedBox(height: 4),
          Text(
            'Open the link we sent you. Come back here and refresh once you '
            'have.',
            style: AuthTextStyles.bodyM,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onResend,
                child: const Text('Resend link'),
              ),
              const SizedBox(width: 8),
              // emailVerified is cached client-side and stays stale until a
              // reload, so this button is not optional.
              TextButton(
                onPressed: onRefresh,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
