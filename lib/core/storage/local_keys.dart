/// Namespaced keys for [LocalStore].
library;

abstract final class LocalKeys {
  static const profile = 'nara.profile';
  static const onboardingSeen = 'nara.onboarding_seen';
  static const aiKey = 'nara.ai_key';
  static const aiBaseUrl = 'nara.ai_base_url';
  static const aiModel = 'nara.ai_model';
  static const aiApiStyle = 'nara.ai_api_style';
  static const prefsShadow = 'nara.prefs';
  static const tasks = 'nara.tasks';
  static const notes = 'nara.notes';
  static const habits = 'nara.habits';
  static const habitLogs = 'nara.habit_logs';
  static const chat = 'nara.chat';

  /// Everything that belongs to user data (used by "delete all data").
  static const List<String> userData = [
    profile,
    tasks,
    notes,
    habits,
    habitLogs,
    chat,
  ];
}
