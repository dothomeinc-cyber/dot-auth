import 'package:dot_auth/dot_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Bundle the font rather than fetching it on first launch — a lot of this
  // app gets opened on a weak connection.
  DotAuthTypography.fontFamily = 'Urbanist';

  runApp(
    ProviderScope(
      overrides: [
        dotAuthConfigProvider.overrideWithValue(
          const DotAuthConfig(
            // dot_auth navigates to these paths. Nothing is hardcoded.
            routes: DotAuthRoutes(
              home: '/dashboard',
              terms: '/legal/terms',
              privacy: '/legal/privacy',
            ),
            resendCooldown: Duration(seconds: 45),
            sendVerificationEmailOnSignUp: true,
          ),
        ),
      ],
      child: const ExampleApp(),
    ),
  );
}

class ExampleApp extends ConsumerWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'dot_auth example',
          debugShowCheckedModeBanner: false,
          theme: authTheme(),
          routerConfig: ref.watch(routerProvider),
        );
      },
    );
  }
}
