import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state_model.dart';

/// A [ChangeNotifier] that bridges [authStateProvider] to go_router's
/// [refreshListenable] mechanism.
///
/// Whenever Firebase auth state changes, [RouterNotifier] calls
/// [notifyListeners], which causes go_router to re-evaluate [redirect].
///
/// Usage — pass a [Ref] from inside a `Provider`:
/// ```dart
/// final routerProvider = Provider<GoRouter>((ref) {
///   final routerNotifier = RouterNotifier(ref);
///
///   return GoRouter(
///     refreshListenable: routerNotifier,
///     redirect: routerNotifier.redirect, // or supply your own
///     routes: [...],
///   );
/// });
/// ```
class RouterNotifier extends ChangeNotifier {
  final Ref ref;
  late final ProviderSubscription<AuthStateModel> _authSubscription;

  /// Creates a [RouterNotifier] and begins listening to [authStateProvider].
  RouterNotifier(this.ref) {
    _authSubscription = ref.listen<AuthStateModel>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  /// Default redirect logic.
  ///
  /// - Authenticated users on auth pages → `/home`
  /// - Unauthenticated users on `/home` → `/phone`
  ///
  /// Override by passing your own redirect callback to [GoRouter] instead.
  String? redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = ref.read(authStateProvider).isAuthenticated;

    final isAuthPage = state.matchedLocation == '/phone' ||
        state.matchedLocation == '/otp' ||
        state.matchedLocation == '/email';

    if (isAuthenticated && isAuthPage) return '/home';
    if (!isAuthenticated && state.matchedLocation == '/home') return '/phone';

    return null;
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }
}
