/// Global constants for the NARA app.
library;

class AppConstants {
  AppConstants._();

  /// Gemini model used for cloud AI replies.
  static const String geminiModel = String.fromEnvironment(
    'NARA_GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  /// Gemini API key injected at build time via --dart-define.
  /// Users can also add their own key from the Profile screen at runtime.
  static const String geminiApiKey = String.fromEnvironment('NARA_GEMINI_API_KEY');

  /// Models base URL for cloud AI (Gemini-style path: `<base>/<model>:generateContent`).
  /// Override at build time via `--dart-define=NARA_GEMINI_BASE_URL=...`
  /// or at runtime from Profile → AI Cloud (custom base URL + model + format).
  static const String geminiBaseUrl = String.fromEnvironment(
    'NARA_GEMINI_BASE_URL',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta/models',
  );

  /// Cloud AI request timeout.
  static const Duration aiTimeout = Duration(seconds: 25);

  /// Max chat history turns sent as cloud AI context.
  static const int aiHistoryTurns = 10;
}

/// Local notification channel + ids.
class ReminderConstants {
  ReminderConstants._();

  static const String dailyChannelId = 'nara_daily_reminder';
  static const String dailyChannelName = 'Daily reminder';
  static const int dailyNotificationId = 1001;
}
