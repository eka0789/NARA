import 'package:cloud_firestore/cloud_firestore.dart';

/// User preferences, stored locally for instant boot and mirrored to
/// Firestore for cross-device consistency.
class UserPrefs {
  const UserPrefs({
    this.language = 'system', // 'system' | 'id' | 'en'
    this.themeMode = 'system', // 'system' | 'light' | 'dark'
    this.dailyReminder = false,
    this.reminderHour = 8,
    this.reminderMinute = 0,
  });

  final String language;
  final String themeMode;
  final bool dailyReminder;
  final int reminderHour;
  final int reminderMinute;

  UserPrefs copyWith({
    String? language,
    String? themeMode,
    bool? dailyReminder,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return UserPrefs(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toMap() => {
        'language': language,
        'themeMode': themeMode,
        'dailyReminder': dailyReminder,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory UserPrefs.fromMap(Map<String, dynamic> map) => UserPrefs(
        language: (map['language'] as String?) ?? 'system',
        themeMode: (map['themeMode'] as String?) ?? 'system',
        dailyReminder: (map['dailyReminder'] as bool?) ?? false,
        reminderHour: ((map['reminderHour'] as num?)?.toInt() ?? 8).clamp(0, 23),
        reminderMinute:
            ((map['reminderMinute'] as num?)?.toInt() ?? 0).clamp(0, 59),
      );
}

/// The signed-in user's profile.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    this.email = '',
    this.avatarEmoji = '🙂',
    this.createdAt,
    this.prefs = const UserPrefs(),
  });

  final String uid;
  final String name;
  final String email;
  final String avatarEmoji;
  final DateTime? createdAt;
  final UserPrefs prefs;

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarEmoji,
    DateTime? createdAt,
    UserPrefs? prefs,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt ?? this.createdAt,
      prefs: prefs ?? this.prefs,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'avatarEmoji': avatarEmoji,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'prefs': prefs.toMap(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // A prefs map from an older/corrupt payload must not kill the profile
    // stream (cast to Map first, then normalize keys).
    final rawPrefs = map['prefs'];
    return UserProfile(
      uid: (map['uid'] as String?) ?? '',
      name: (map['name'] as String?) ?? 'Friend',
      email: (map['email'] as String?) ?? '',
      avatarEmoji: (map['avatarEmoji'] as String?) ?? '🙂',
      createdAt: parseDate(map['createdAt']),
      prefs: UserPrefs.fromMap(
        rawPrefs is Map
            ? Map<String, dynamic>.from(rawPrefs)
            : const <String, dynamic>{},
      ),
    );
  }
}

/// Minimal auth identity exposed by [AuthRepository.authStateChanges].
class AuthUser {
  const AuthUser({required this.uid, this.email = '', this.name = ''});

  final String uid;
  final String email;
  final String name;
}
