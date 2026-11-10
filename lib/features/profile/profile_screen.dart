import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/gemini_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/core_providers.dart';
import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';
import '../settings/settings_providers.dart';

/// Profile + settings hub.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).value;
    final prefs = ref.watch(prefsProvider);
    final isLocal = ref.watch(authRepositoryProvider).isLocal;
    final cloudAi = ref.watch(cloudAiEnabledProvider);

    final tasks = ref.watch(tasksProvider).value ?? const [];
    final notes = ref.watch(notesProvider).value ?? const [];
    final habits = ref.watch(habitsProvider).value ?? const [];
    final tasksDone = tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          // Header
          Entrance(
            child: NaraCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: NaraGradients.softBlob(theme),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile?.avatarEmoji ?? '🙂',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name.isNotEmpty == true
                              ? profile!.name
                              : 'NARA',
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isLocal && (profile?.email.isNotEmpty ?? false))
                          Text(
                            profile!.email,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isLocal
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF14B8A6))
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            isLocal ? l10n.badgeLocalMode : l10n.badgeCloudMode,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isLocal
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF0F766E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditProfileSheet(context, ref, profile),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Entrance(
            delayMs: 60,
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.task_alt_rounded,
                    value: '$tasksDone',
                    label: l10n.statTasks,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.sticky_note_2_rounded,
                    value: '${notes.length}',
                    label: l10n.statNotes,
                    color: const Color(0xFF14B8A6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.local_fire_department_rounded,
                    value: '${habits.length}',
                    label: l10n.statHabits,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Entrance(
            delayMs: 100,
            child: Text(l10n.settingsSection, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 10),

          _SettingTile(
            icon: Icons.palette_outlined,
            label: l10n.settingsTheme,
            value: switch (prefs.themeMode) {
              'light' => l10n.themeLight,
              'dark' => l10n.themeDark,
              _ => l10n.themeSystem,
            },
            onTap: () => _showThemeSheet(context, ref),
          ),
          _SettingTile(
            icon: Icons.language_rounded,
            label: l10n.settingsLanguage,
            value: switch (prefs.language) {
              'id' => l10n.langIndonesian,
              'en' => l10n.langEnglish,
              _ => l10n.langSystem,
            },
            onTap: () => _showLanguageSheet(context, ref),
          ),
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(l10n.settingsReminder),
            subtitle: Text(l10n.settingsReminderSub),
            value: prefs.dailyReminder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onChanged: (value) async {
              final notifier = ref.read(prefsProvider.notifier);
              final ok = await notifier.setDailyReminder(value);
              if (!context.mounted) return;
              showNaraSnack(
                context,
                ok
                    ? (value
                        ? l10n.reminderSaved(_formatTime(prefs.reminderHour, prefs.reminderMinute))
                        : l10n.reminderDisabled)
                    : l10n.notificationPermissionDenied,
                error: !ok,
              );
            },
          ),
          if (prefs.dailyReminder)
            _SettingTile(
              icon: Icons.schedule_rounded,
              label: l10n.reminderTimeLabel,
              value: _formatTime(prefs.reminderHour, prefs.reminderMinute),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: prefs.reminderHour,
                    minute: prefs.reminderMinute,
                  ),
                  helpText: l10n.timePickerTitle,
                );
                if (picked != null) {
                  final notifier = ref.read(prefsProvider.notifier);
                  final ok = await notifier.setReminderTime(picked);
                  if (context.mounted) {
                    showNaraSnack(
                      context,
                      ok
                          ? l10n.reminderSaved(_formatTime(picked.hour, picked.minute))
                          : l10n.notificationPermissionDenied,
                      error: !ok,
                    );
                  }
                }
              },
            ),
          _SettingTile(
            icon: Icons.bolt_rounded,
            label: l10n.settingsAiKey,
            value: cloudAi ? l10n.chatCloudBadge : l10n.badgeLocalMode,
            onTap: () => _showAiConfigSheet(context, ref),
          ),
          _SettingTile(
            icon: Icons.info_outline_rounded,
            label: l10n.settingsAbout,
            value: '',
            onTap: () => _showAboutSheet(context),
          ),
          if (!isLocal) ...[
            const SizedBox(height: 12),
            _SettingTile(
              icon: Icons.logout_rounded,
              label: l10n.signOut,
              value: '',
              destructive: true,
              onTap: () => _confirmSignOut(context, ref),
            ),
          ],
          _SettingTile(
            icon: Icons.delete_forever_rounded,
            label: l10n.deleteData,
            value: '',
            destructive: true,
            onTap: () => _confirmDeleteData(context, ref),
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: profile?.name ?? '');
    const emojis = ['🙂', '😎', '🦊', '🐼', '🌟', '🚀', '🌸', '🔥', '🧋', '🎧', '📚', '🦁'];
    var selected = profile?.avatarEmoji ?? '🙂';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.profileEdit, style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(hintText: l10n.profileNameLabel),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.profileEmojiLabel, style: Theme.of(sheetContext).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emoji in emojis)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setSheetState(() => selected = emoji),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: selected == emoji
                                  ? Theme.of(sheetContext).colorScheme.primary
                                      .withValues(alpha: 0.14)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected == emoji
                                    ? Theme.of(sheetContext).colorScheme.primary
                                    : Theme.of(sheetContext).colorScheme.outlineVariant,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: l10n.commonSave,
                    onPressed: () async {
                      await ref
                          .read(authRepositoryProvider)
                          .updateProfile(
                            name: nameController.text.trim(),
                            avatarEmoji: selected,
                          );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        showNaraSnack(sheetContext, l10n.profileSaved);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.read(prefsProvider).themeMode;
    final options = {
      'system': l10n.themeSystem,
      'light': l10n.themeLight,
      'dark': l10n.themeDark,
    };
    _showOptionSheet(
      context,
      title: l10n.settingsTheme,
      options: options,
      selected: current,
      onSelect: (value) => ref.read(prefsProvider.notifier).setThemeMode(value),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.read(prefsProvider).language;
    final options = {
      'system': l10n.langSystem,
      'id': l10n.langIndonesian,
      'en': l10n.langEnglish,
    };
    _showOptionSheet(
      context,
      title: l10n.settingsLanguage,
      options: options,
      selected: current,
      onSelect: (value) => ref.read(prefsProvider.notifier).setLanguage(value),
    );
  }

  void _showOptionSheet(
    BuildContext context, {
    required String title,
    required Map<String, String> options,
    required String selected,
    required Future<void> Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: selected,
          onChanged: (value) async {
            if (value == null) return;
            Navigator.pop(sheetContext);
            await onSelect(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              for (final entry in options.entries)
                RadioListTile<String>(
                  value: entry.key,
                  title: Text(entry.value),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiConfigSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keyController = TextEditingController(text: ref.read(aiKeyProvider));
    final baseUrlController =
        TextEditingController(text: ref.read(aiBaseUrlProvider));
    final modelController =
        TextEditingController(text: ref.read(aiModelProvider));
    var apiStyle = ref.read(aiApiStyleProvider);
    final hasBuildKey = AppConstants.geminiApiKey.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.aiKeyTitle,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.aiKeyBody,
                      style: Theme.of(sheetContext).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: keyController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration:
                          InputDecoration(hintText: l10n.aiKeyFieldLabel),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.aiApiStyleLabel,
                      style: Theme.of(sheetContext).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<AiApiStyle>(
                      segments: const [
                        ButtonSegment(
                          value: AiApiStyle.gemini,
                          label: Text('Gemini'),
                          icon: Icon(Icons.auto_awesome_rounded),
                        ),
                        ButtonSegment(
                          value: AiApiStyle.openai,
                          label: Text('OpenAI'),
                          icon: Icon(Icons.bolt_rounded),
                        ),
                      ],
                      selected: {apiStyle},
                      onSelectionChanged: (selection) =>
                          setSheetState(() => apiStyle = selection.first),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: baseUrlController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: l10n.aiBaseUrlLabel,
                        hintText: ref.read(aiBaseUrlProvider),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: modelController,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: l10n.aiModelLabel,
                        hintText: ref.read(aiModelProvider),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: l10n.commonSave,
                      icon: Icons.key_rounded,
                      onPressed: () async {
                        final key = keyController.text.trim();
                        final baseUrl = baseUrlController.text.trim();
                        final model = modelController.text.trim();

                        // Endpoint must be an absolute http(s) address.
                        final parsed = Uri.tryParse(baseUrl);
                        final validUrl = parsed != null &&
                            (parsed.scheme == 'http' ||
                                parsed.scheme == 'https') &&
                            parsed.host.isNotEmpty;
                        if (!validUrl) {
                          showNaraSnack(
                            sheetContext,
                            l10n.aiBaseUrlInvalid,
                            error: true,
                          );
                          return;
                        }

                        // Verify the config with a tiny request before saving.
                        // Unreachable/network errors do not block saving — only
                        // an explicit rejection does.
                        if (key.isNotEmpty) {
                          final test = GeminiService(
                            apiKey: key,
                            baseUrl: baseUrl,
                            model:
                                model.isEmpty ? AppConstants.geminiModel : model,
                            apiStyle: apiStyle,
                          );
                          try {
                            await test.generateReply(
                              systemPrompt: 'ping',
                              userMessage: 'ping',
                              history: const [],
                            );
                          } on AiException catch (e) {
                            if (e.code == 'invalid-key') {
                              if (sheetContext.mounted) {
                                showNaraSnack(
                                  sheetContext,
                                  l10n.aiKeyInvalid,
                                  error: true,
                                );
                              }
                              return;
                            }
                            if (e.code == 'invalid-endpoint') {
                              if (sheetContext.mounted) {
                                showNaraSnack(
                                  sheetContext,
                                  l10n.aiBaseUrlInvalid,
                                  error: true,
                                );
                              }
                              return;
                            }
                            // quota / network / empty: config itself may be fine.
                          }
                        }
                        ref.read(aiKeyProvider.notifier).set(
                              key.isEmpty ? null : key,
                            );
                        ref.read(aiBaseUrlProvider.notifier).set(baseUrl);
                        ref.read(aiModelProvider.notifier).set(model);
                        ref.read(aiApiStyleProvider.notifier).set(apiStyle);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                          showNaraSnack(
                            sheetContext,
                            key.isEmpty ? l10n.aiKeyRemoved : l10n.aiKeySaved,
                          );
                        }
                      },
                    ),
                    if (ref.read(aiKeyProvider).trim().isNotEmpty &&
                        !hasBuildKey) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(aiKeyProvider.notifier).clear();
                          Navigator.pop(sheetContext);
                          showNaraSnack(sheetContext, l10n.aiKeyRemoved);
                        },
                        child: Text(l10n.commonRemove),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      keyController.dispose();
      baseUrlController.dispose();
      modelController.dispose();
    });
  }

  void _showAboutSheet(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: NaraGradients.brand,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'N',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NARA', style: Theme.of(sheetContext).textTheme.titleLarge),
                      Text(
                        l10n.aboutVersion('1.0.0'),
                        style: Theme.of(sheetContext).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.aboutBody, style: Theme.of(sheetContext).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  Future<void> _confirmDeleteData(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteDataConfirmTitle),
        content: Text(l10n.deleteDataConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(authRepositoryProvider).deleteAllData();
        // Data is gone — stop the daily reminder so the user is not
        // notified about habits/tasks that no longer exist.
        await ref.read(prefsProvider.notifier).onDataDeleted();
        if (context.mounted) {
          showNaraSnack(context, l10n.deleteDataDone);
        }
      } on Exception catch (_) {
        if (context.mounted) {
          showNaraSnack(context, l10n.commonErrorGeneric, error: true);
        }
      }
    }
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NaraCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: destructive ? theme.colorScheme.error : null,
            ),
          ),
          subtitle: value.isEmpty ? null : Text(value, style: theme.textTheme.bodySmall),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
