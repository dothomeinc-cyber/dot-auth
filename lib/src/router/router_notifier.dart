import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state_model.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;
  late final ProviderSubscription<AuthStateModel> _authSubscription;

  RouterNotifier(this.ref) {
    _authSubscription = ref.listen<AuthStateModel>(
      authStateProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isAuthPage =
        state.matchedLocation == '/phone' || state.matchedLocation == '/otp';

    if (isAuthenticated && isAuthPage) {
      return '/home';
    }

    if (!isAuthenticated && state.matchedLocation == '/home') {
      return '/phone';
    }

    return null;
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }
}
