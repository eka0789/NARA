import '../../core/models/user_profile.dart';
import '../../core/storage/local_keys.dart';
import '../../core/storage/local_store.dart';
import 'auth_repository.dart';

/// Device-only auth used when Firebase is not configured (demo mode).
///
/// There are no real credentials here by design: the "account" is a local
/// profile so the whole app stays usable offline. Production deployments
/// should always run with Firebase configured.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);

  final LocalStore _store;

  UserProfile? _read() {
    final map = _store.readMap(LocalKeys.profile);
    return map == null ? null : UserProfile.fromMap(map);
  }

  void _write(UserProfile profile) => _store.writeMap(
        LocalKeys.profile,
        profile.toMap(),
      );

  @override
  bool get isLocal => true;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _store.watch<UserProfile?>(LocalKeys.profile, _read).map(
            (profile) => profile == null
                ? null
                : AuthUser(uid: profile.uid, email: profile.email, name: profile.name),
          );

  @override
  Stream<UserProfile?> watchProfile() =>
      _store.watch<UserProfile?>(LocalKeys.profile, _read);

  @override
  Future<void> signInWithGoogle() => throw AuthException('unsupported');

  @override
  Future<void> createLocalProfile({required String name}) => _create(name);

  Future<void> _create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw AuthException('name-empty');
    final existing = _read();
    _write(
      UserProfile(
        uid: existing?.uid ?? 'local',
        name: trimmed,
        email: existing?.email ?? '',
        avatarEmoji: existing?.avatarEmoji ?? '🙂',
        createdAt: existing?.createdAt ?? DateTime.now(),
        prefs: existing?.prefs ?? const UserPrefs(),
      ),
    );
  }

  @override
  Future<void> signOut() async {
    // In local mode "sign out" keeps the profile (re-open returns home).
    // Deleting the profile is done via deleteAllData.
  }

  @override
  Future<void> updateProfile({String? name, String? avatarEmoji}) async {
    final profile = _read();
    if (profile == null) return;
    _write(
      profile.copyWith(
        name: name?.trim().isNotEmpty == true ? name!.trim() : null,
        avatarEmoji: avatarEmoji,
      ),
    );
  }

  @override
  Future<void> savePrefs(UserPrefs prefs) async {
    final profile = _read();
    if (profile == null) return;
    _write(profile.copyWith(prefs: prefs));
  }

  @override
  Future<void> deleteAllData() async {
    _store.wipeAll(LocalKeys.userData);
  }
}
