import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/widgets/ui.dart';
import '../settings/settings_providers.dart';

/// Three-step introduction: value proposition, scope, and hybrid AI.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(onboardingSeenProvider.notifier).complete();
    final user = ref.read(authStateProvider).value;
    context.go(user != null ? '/home' : '/register');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final pages = [
      _PageData(
        emoji: '👋',
        icon: Icons.auto_awesome,
        title: l10n.ob1Title,
        body: l10n.ob1Body,
      ),
      _PageData(
        emoji: '🗂️',
        icon: Icons.dashboard_rounded,
        title: l10n.ob2Title,
        body: l10n.ob2Body,
      ),
      _PageData(
        emoji: '🤖',
        icon: Icons.smart_toy_rounded,
        title: l10n.ob3Title,
        body: l10n.ob3Body,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Entrance(
                          delayMs: 60,
                          child: _Illustration(page: page),
                        ),
                        const SizedBox(height: 40),
                        Entrance(
                          delayMs: 140,
                          child: Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Entrance(
                          delayMs: 200,
                          child: Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: const EdgeInsets.only(right: 6),
                          width: _page == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == i
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  GradientButton(
                    label: _page == 2
                        ? l10n.onboardingStart
                        : l10n.onboardingNext,
                    onPressed: _next,
                    expanded: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.emoji,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String emoji;
  final IconData icon;
  final String title;
  final String body;
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.page});

  final _PageData page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: NaraGradients.softBlob(theme),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              page.icon,
              size: 72,
              color: theme.colorScheme.primary,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _Badge(text: page.emoji, theme: theme),
          ),
          Positioned(
            bottom: 24,
            left: 6,
            child: _Badge(text: '✨', theme: theme, small: true),
          ),
          Positioned(
            bottom: 8,
            right: 34,
            child: _Badge(text: '💙', theme: theme, small: true),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.theme, this.small = false});

  final String text;
  final ThemeData theme;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 44 : 56,
      height: small ? 44 : 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontSize: small ? 20 : 26)),
    );
  }
}
