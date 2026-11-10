import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ai/gemini_service.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/models/user_profile.dart';
import 'core/notifications/reminder_service.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/local_keys.dart';
import 'core/storage/local_store.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/firebase_auth_repository.dart';
import 'features/auth/local_auth_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final store = LocalStore(await SharedPreferences.getInstance());

  var firebaseEnabled = false;
  AuthRepository auth;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    // Placeholder template (before `flutterfire configure`) must not
    // enable Firebase mode — fall back to local mode instead.
    if (!options.apiKey.startsWith('AIza')) {
      throw Exception(
        'firebase_options.dart still contains placeholders — '
        'run `flutterfire configure` (see README).',
      );
    }
    await Firebase.initializeApp(options: options);
    auth = FirebaseAuthRepository();
    firebaseEnabled = true;
  } on Exception catch (e) {
    // Firebase not configured for this build — run in local mode so the
    // app remains fully usable. See README (Firebase setup section).
    // The failure itself must never be silent: a misconfigured release
    // build otherwise looks exactly like a working local-mode build.
    debugPrint('Firebase init failed — falling back to local mode: $e');
    auth = LocalAuthRepository(store);
  }
  final ai = GeminiService();

  await ReminderService.instance.init();

  // Restore the daily reminder after reboot/app start when enabled.
  final shadowPrefs = store.readMap(LocalKeys.prefsShadow);
  if (shadowPrefs != null) {
    final prefs = UserPrefs.fromMap(shadowPrefs);
    if (prefs.dailyReminder) {
      // Resolve 'system' to the device locale — scheduling with the raw
      // 'system' string would show English reminders to Indonesian users.
      final lang = prefs.language == 'system'
          ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
          : prefs.language;
      unawaited(
        ReminderService.instance.scheduleDaily(
          hour: prefs.reminderHour,
          minute: prefs.reminderMinute,
          langCode: lang,
        ),
      );
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        appBootstrapProvider.overrideWithValue(
          AppBootstrap(firebaseEnabled: firebaseEnabled, auth: auth, ai: ai),
        ),
      ],
      child: const NaraApp(),
    ),
  );
}
