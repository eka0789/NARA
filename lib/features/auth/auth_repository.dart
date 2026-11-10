import '../../../core/models/user_profile.dart';

/// Authentication + profile contract.
///
/// Two implementations exist:
/// - [FirebaseAuthRepository] — production, backed by Firebase Auth/Firestore.
/// - [LocalAuthRepository] — demo/offline fallback storing a device profile.
abstract interface class AuthRepository {
  /// Whether this repository runs without a Firebase project.
  bool get isLocal;

  /// Emits the current identity (null when signed out / no profile).
  Stream<AuthUser?> authStateChanges();

  /// Emits the profile of the current identity (null when signed out).
  Stream<UserProfile?> watchProfile();

  /// Signs in or registers with Google — the only credential flow in
  /// Firebase mode. Local mode throws [AuthException] ('unsupported'):
  /// a device-local profile has no Google-backed identity.
  Future<void> signInWithGoogle();

  /// Local-mode helper: create a profile without credentials. Firebase
  /// mode throws [UnsupportedError] (Google-only accounts).
  Future<void> createLocalProfile({required String name});

  Future<void> signOut();

  Future<void> updateProfile({String? name, String? avatarEmoji});

  Future<void> savePrefs(UserPrefs prefs);

  /// Permanently deletes all user data (tasks, notes, habits, chat) and the
  /// profile. In Firebase mode also attempts to delete the auth account.
  Future<void> deleteAllData();
}

/// Signals which auth problem occurred, already mapped for presentation.
class AuthException implements Exception {
  AuthException(this.code);

  /// Stable code, see [authErrorL10nKey].
  final String code;

  String get authErrorL10nKey => switch (code) {
        'wrong-password' => 'authErrorWrongPassword',
        'network' => 'authErrorNetwork',
        'too-many-requests' => 'authErrorTooManyRequests',
        'name-empty' => 'authErrorNameEmpty',
        'canceled' => 'authGoogleCancelled',
        _ => 'commonErrorGeneric',
      };

  @override
  String toString() => 'AuthException($code)';
}
