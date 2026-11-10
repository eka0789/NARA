import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/widgets/ui.dart';
import 'google_auth_button.dart';

/// Sign-in screen. Firebase mode is Google-only (one tap both signs in and
/// registers); local mode routes straight to profile creation because a
/// device profile auto-auths as soon as it exists.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isLocal = ref.read(authRepositoryProvider).isLocal;

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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: NaraGradients.brand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'N',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(l10n.loginTitle,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          l10n.loginSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isLocal) ...[
                    NaraCard(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderColor:
                          theme.colorScheme.primary.withValues(alpha: 0.25),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.offline_bolt_rounded,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.authLocalBanner,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Entrance(
                      delayMs: 80,
                      child: GradientButton(
                        label: l10n.authLocalRegister,
                        onPressed: () => context.go('/register'),
                      ),
                    ),
                  ] else
                    Entrance(
                      delayMs: 80,
                      child: GoogleAuthButton(
                        label: l10n.authContinueWithGoogle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
