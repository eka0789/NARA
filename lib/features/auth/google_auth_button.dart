import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/widgets/ui.dart';
import 'auth_error.dart';
import 'auth_repository.dart';

/// "Continue with Google" with its auth wiring: loading state, silent
/// cancel, and error snack. Shared by the login and register screens so
/// the flow behaves identically from both entries.
class GoogleAuthButton extends ConsumerStatefulWidget {
  const GoogleAuthButton({super.key, required this.label});

  final String label;

  @override
  ConsumerState<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends ConsumerState<GoogleAuthButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthException catch (e) {
      // Every outcome is surfaced — including 'canceled'. On Android,
      // CredentialManager reports configuration/SDK failures as "canceled"
      // (google_sign_in troubleshooting docs), so silence here hides real
      // sign-in breakage behind a "user cancelled" label.
      if (mounted) {
        showNaraSnack(
          context,
          authErrorMessage(context.l10n, e.authErrorL10nKey),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Router redirects to /home when the auth state flips.
  }

  @override
  Widget build(BuildContext context) =>
      GoogleSignInButton(label: widget.label, loading: _loading, onPressed: _signIn);
}
