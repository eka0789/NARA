import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/storage/local_store.dart';
import '../../core/providers/core_providers.dart';
import '../../core/storage/local_keys.dart';

/// User preferences with a device-local shadow for instant boot.
///
/// Writes go to local storage first (UI responds immediately), then sync to
/// the backend profile best-effort. The daily reminder is (re)scheduled
/// whenever its settings change.
class PrefsController extends Notifier<UserPrefs> {
  @override
  UserPrefs build() {
    final map = ref.watch(localStoreProvider).readMap(LocalKeys.prefsShadow);
    return map == null ? const UserPrefs() : UserPrefs.fromMap(map);
  }

  LocalStore get _store => ref.read(localStoreProvider);

  /// Language for notifications: 'system' must resolve to the device locale,
  /// otherwise an Indonesian user gets English reminders.
  String get _notificationLang {
    final language = state.language;
    if (language != 'system') return language;
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  }

  Future<void> _persist(UserPrefs prefs) async {
    _store.writeMap(LocalKeys.prefsShadow, prefs.toMap());
    state = prefs;
    try {
      await ref.read(authRepositoryProvider).savePrefs(prefs);
    } on Exception {
      // Backend sync is best-effort; local state is authoritative.
    }
  }

  Future<bool> setLanguage(String language) async {
    await _persist(state.copyWith(language: language));
    return true;
  }

  Future<bool> setThemeMode(String themeMode) async {
    await _persist(state.copyWith(themeMode: themeMode));
    return true;
  }

  /// Toggles the daily reminder. Returns false when notification permission
  /// was denied so the UI can inform the user.
  Future<bool> setDailyReminder(bool enabled) async {
    final service = ReminderService.instance;
    if (enabled) {
      final ok = await service.scheduleDaily(
        hour: state.reminderHour,
        minute: state.reminderMinute,
        langCode: _notificationLang,
      );
      if (!ok) return false;
    } else {
      await service.cancelDaily();
    }
    await _persist(state.copyWith(dailyReminder: enabled));
    return true;
  }

  /// Sets the reminder time; keeps enabled state as-is. Returns false when
  /// scheduling failed (permission denied).
  Future<bool> setReminderTime(TimeOfDay time) async {
    final next = state.copyWith(
      reminderHour: time.hour,
      reminderMinute: time.minute,
    );
    if (next.dailyReminder) {
      final ok = await ReminderService.instance.scheduleDaily(
        hour: time.hour,
        minute: time.minute,
        langCode: _notificationLang,
      );
      if (!ok) return false;
    }
    await _persist(next);
    return true;
  }

  /// Called after "delete all data": stop the daily reminder and clear its
  /// flag. Writes the shadow directly (no backend sync — the profile
  /// document was just deleted and savePrefs would recreate it).
  Future<void> onDataDeleted() async {
    await ReminderService.instance.cancelDaily();
    final next = state.copyWith(dailyReminder: false);
    _store.writeMap(LocalKeys.prefsShadow, next.toMap());
    state = next;
  }
}

final prefsProvider =
    NotifierProvider<PrefsController, UserPrefs>(PrefsController.new);

/// Resolved [ThemeMode] for MaterialApp.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(prefsProvider).themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// Resolved [Locale] for MaterialApp (null = follow the system).
final localeProvider = Provider<Locale?>((ref) {
  return switch (ref.watch(prefsProvider).language) {
    'id' => const Locale('id'),
    'en' => const Locale('en'),
    _ => null,
  };
});

/// Whether onboarding has been completed (device-local).
class OnboardingController extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(localStoreProvider).readBool(LocalKeys.onboardingSeen);

  void complete() {
    ref.read(localStoreProvider).writeBool(LocalKeys.onboardingSeen, true);
    state = true;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
