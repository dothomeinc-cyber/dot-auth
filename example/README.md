# dot_auth example

A working app that exercises every part of the package.

## Run it

1. Create a Firebase project and enable **Phone** and **Email/Password** under
   Authentication → Sign-in method.
2. Run `flutterfire configure` in this folder to generate the platform config.
3. Add real test numbers under Authentication → Settings → Phone numbers for
   testing, so you are not burning SMS credit on every run.
4. `flutter pub get && flutter run`

The Urbanist font block in `pubspec.yaml` expects `.ttf` files in
`assets/fonts/`. Either drop them in, or delete that block along with the
`DotAuthTypography.fontFamily` line in `main.dart` to fall back to
`google_fonts`.

## What each file shows

| File | Shows |
| --- | --- |
| `main.dart` | Overriding `DotAuthConfig` — routes, cooldown, verification |
| `router.dart` | `AuthRouter.createRouter`, plus the manual `RouterNotifier` setup |
| `screens/dashboard_screen.dart` | Reading the session, email verification, linking, sign-out, deletion |
| `screens/orders_screen.dart` | A protected route with no auth code of its own |
| `screens/legal_page.dart` | Where `TcFooter` lands |

## Things worth noticing

- **No screen navigates home.** Signing in updates `authStateProvider` through
  the Firebase auth stream and the redirect follows. Adding a manual
  `context.go(home)` is what stranded signed-in users on the login form in 1.x.
- **`/orders` has no auth check.** The redirect denies by default, so any route
  you add is protected unless you put it in `DotAuthRoutes.publicPaths`.
- **`deleteAccount()` keeps the session on failure.** Firebase usually wants a
  fresh sign-in first; dropping the session would leave the user unable to
  re-authenticate and retry.
- **`reloadUser()` after verification.** `emailVerified` is cached on the
  client and stays stale until you reload, which is why the card has a Refresh
  button.
