import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/widgets/ui.dart';
import 'auth_error.dart';
import 'auth_repository.dart';
import 'google_auth_button.dart';

/// Account creation. Firebase mode is Google-only — the first Google sign-in
/// creates the account, so this screen shares the same one-tap CTA as the
/// login screen. Local mode keeps the "start with a profile" name form.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _isLocal => ref.read(authRepositoryProvider).isLocal;

  Future<void> _submitLocal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .createLocalProfile(name: _name.text.trim());
    } on AuthException catch (e) {
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isLocal = _isLocal;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Entrance(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLocal ? l10n.authLocalRegister : l10n.registerTitle,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isLocal
                              ? l10n.authLocalRegisterHint
                              : l10n.registerSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (isLocal) ...[
                    Entrance(
                      delayMs: 60,
                      child: Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: InputDecoration(
                            labelText: l10n.authNameLabel,
                            prefixIcon:
                                const Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.authErrorNameEmpty
                                  : null,
                          autovalidateMode:
                              AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Entrance(
                      delayMs: 120,
                      child: GradientButton(
                        label: l10n.commonContinue,
                        loading: _loading,
                        onPressed: _submitLocal,
                      ),
                    ),
                  ] else ...[
                    Entrance(
                      delayMs: 60,
                      child: GoogleAuthButton(
                        label: l10n.authContinueWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.authHasAccount,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(l10n.authSignIn),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
