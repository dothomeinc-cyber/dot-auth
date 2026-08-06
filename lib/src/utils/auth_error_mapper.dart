/// Maps a [FirebaseAuthException.code] to a message safe to show a user.
///
/// Messages explain what went wrong and what to do next. They never leak
/// whether an account exists — `user-not-found` and `wrong-password` collapse
/// to the same string so the sign-in form can't be used to enumerate emails.
String mapAuthError(String code) {
  switch (code) {
    // ── Email / password ────────────────────────────────────────────────
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'user-disabled':
      return 'This account is disabled. Contact support to reopen it.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return 'Email or password is incorrect.';
    case 'email-already-in-use':
      return 'An account already uses this email. Sign in instead.';
    case 'weak-password':
      return 'Use at least 6 characters for your password.';
    case 'operation-not-allowed':
      return 'This sign-in method is turned off for this app.';
    case 'requires-recent-login':
      return 'Sign in again to confirm it is you, then retry.';

    // ── Phone / OTP ─────────────────────────────────────────────────────
    case 'invalid-phone-number':
      return 'Enter a valid mobile number.';
    case 'missing-phone-number':
      return 'Enter your mobile number.';
    case 'invalid-verification-code':
      return 'That code is incorrect. Check the SMS and retype it.';
    case 'invalid-verification-id':
    case 'session-expired':
      return 'This code expired. Request a new one.';
    case 'quota-exceeded':
      return 'SMS limit reached. Try again in a while.';
    case 'missing-verification-code':
      return 'Enter the code from the SMS.';

    // ── Linking ─────────────────────────────────────────────────────────
    case 'credential-already-in-use':
    case 'account-exists-with-different-credential':
      return 'This is already connected to another account.';
    case 'provider-already-linked':
      return 'This sign-in method is already connected.';
    case 'no-such-provider':
      return 'This sign-in method is not connected to your account.';

    // ── Shared ──────────────────────────────────────────────────────────
    case 'too-many-requests':
      return 'Too many attempts. Wait a few minutes and try again.';
    case 'network-request-failed':
      return 'No connection. Check your internet and try again.';
    case 'app-not-authorized':
    case 'captcha-check-failed':
      return 'Device verification failed. Restart the app and try again.';
    case 'user-token-expired':
      return 'Your session expired. Sign in again.';

    default:
      return 'Something went wrong. Try again.';
  }
}
