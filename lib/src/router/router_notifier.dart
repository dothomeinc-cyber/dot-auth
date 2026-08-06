import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/dot_auth_config.dart';
import '../models/auth_state_model.dart';
import '../providers/auth_provider.dart';
import '../providers/phone_auth_provider.dart';

/// Bridges the Firebase session to go_router's `refreshListenable`.
///
/// Whenever the session changes this calls `notifyListeners`, prompting
/// go_router to re-run [redirect].
///
/// ```dart
/// final routerProvider = Provider<GoRouter>((ref) {
///   final notifier = RouterNotifier(ref);
///   ref.onDispose(notifier.dispose); // required — see below
///
///   return GoRouter(
///     refreshListenable: notifier,
///     redirect: notifier.redirect,
///     routes: [...],
///   );
/// });
/// ```
///
/// The `ref.onDispose` line is not optional: without it the notifier keeps its
/// listener on `authStateProvider` alive for the life of the process.
class RouterNotifier extends ChangeNotifier {
  /// The [Ref] this notifier reads providers through.
  final Ref ref;

  late final ProviderSubscription<AuthStateModel> _subscription;

  /// Starts listening to the Firebase session.
  RouterNotifier(this.ref) {
    _subscription = ref.listen<AuthStateModel>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  /// Default redirect.
  ///
  /// - While the session is still resolving, stay put.
  /// - Signed in and sitting on a sign-in screen → home.
  /// - Signed out and anywhere that isn't public → the phone screen. This is a
  ///   deny-by-default guard, so routes you add later are protected without
  ///   you having to remember to list them.
  /// - On the OTP screen with no code pending → back to the phone screen.
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final routes = ref.read(dotAuthRoutesProvider);
    final location = state.matchedLocation;

    if (authState.isResolving) return null;

    if (authState.isAuthenticated) {
      if (routes.signInPaths.contains(location)) return routes.home;
      return null;
    }

    if (!routes.publicPaths.contains(location)) return routes.phone;

    if (location == routes.otp && !ref.read(phoneAuthProvider).isCodeSent) {
      return routes.phone;
    }

    return null;
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
