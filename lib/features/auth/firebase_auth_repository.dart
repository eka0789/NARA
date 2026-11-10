import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/models/user_profile.dart';
import 'auth_repository.dart';

/// Production auth backed by Firebase Auth + Firestore user documents.
///
/// Google Sign-In is the only credential flow: `signInWithGoogle` both
/// registers and signs in (Firebase creates the account on first login).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? store})
      : _auth = auth ?? FirebaseAuth.instance,
        _store = store ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _store;
  bool _googleInitialized = false;

  @override
  bool get isLocal => false;

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(
        (user) => user == null
            ? null
            : AuthUser(uid: user.uid, email: user.email ?? '', name: user.displayName ?? ''),
      );

  @override
  Stream<UserProfile?> watchProfile() =>
      _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream<UserProfile?>.value(null);
        return _store.collection('users').doc(user.uid).snapshots().map((doc) {
          final data = doc.data();
          if (data == null) {
            return UserProfile(
              uid: user.uid,
              name: (user.displayName?.isNotEmpty ?? false)
                  ? user.displayName!
                  : 'Friend',
              email: user.email ?? '',
            );
          }
          final profile = UserProfile.fromMap({'uid': user.uid, ...data});
          // Prefer a real display name when the document lacks one.
          if (profile.name.isEmpty || profile.name == 'Friend') {
            final fallback = (user.displayName?.isNotEmpty ?? false)
                ? user.displayName!
                : profile.name;
            return profile.copyWith(name: fallback, email: user.email ?? '');
          }
          return profile;
        });
      });

  CollectionReference<Map<String, dynamic>> get _users =>
      _store.collection('users');

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        // Reads the Android OAuth clients (incl. web client id) from
        // google-services.json — no Dart-side ids required.
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }
      debugPrint('GSI[1] initialize ok');
      final account = await GoogleSignIn.instance.authenticate();
      debugPrint('GSI[2] authenticate ok uid=${account.id}');
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('GSI[!] idToken NULL/empty');
        throw AuthException('unknown');
      }
      debugPrint('GSI[3] idToken ok (${idToken.length} chars)');
      final credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final user = credential.user;
      if (user == null) {
        debugPrint('GSI[!] firebase user NULL');
        throw AuthException('unknown');
      }
      debugPrint('GSI[4] firebase ok uid=${user.uid}');
      // First Google sign-in doubles as registration: ensure the Firestore
      // user document exists (also covers reinstalls).
      final doc = await _users.doc(user.uid).get();
      if (!doc.exists) {
        await _users.doc(user.uid).set({
          'name': user.displayName ?? 'Friend',
          'email': user.email ?? '',
          'avatarEmoji': '🙂',
          'createdAt': FieldValue.serverTimestamp(),
          'prefs': const UserPrefs().toMap(),
        }, SetOptions(merge: true));
      }
      debugPrint('GSI[5] firestore ok (created=${!doc.exists}) — DONE');
    } on GoogleSignInException catch (e) {
      debugPrint('GSI[!] plugin FAIL code=${e.code} desc=${e.description} details=${e.details}');
      // The user backing out is not an error — surfaced as a silent no-op.
      throw AuthException(
        e.code == GoogleSignInExceptionCode.canceled ? 'canceled' : 'unknown',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('GSI[!] firebase FAIL code=${e.code} msg=${e.message}');
      throw AuthException(_mapCode(e));
    } on Exception catch (e) {
      debugPrint('GSI[!] other FAIL ${e.runtimeType}: $e');
      // Contract: this method only ever throws AuthException — anything the
      // plugin layer raises (e.g. platform errors) degrades to generic text.
      throw AuthException('unknown');
    }
  }

  @override
  Future<void> createLocalProfile({required String name}) async {
    throw UnsupportedError('createLocalProfile is local-mode only');
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } on Exception catch (_) {
      // Best effort: Firebase sign-out below must still run.
    }
    await _auth.signOut();
  }

  @override
  Future<void> updateProfile({String? name, String? avatarEmoji}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (name != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
    }
    await _users.doc(user.uid).set(
      {
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> savePrefs(UserPrefs prefs) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users
        .doc(user.uid)
        .set({'prefs': prefs.toMap()}, SetOptions(merge: true));
  }

  @override
  Future<void> deleteAllData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final userDoc = _users.doc(uid);

    Future<void> wipeCollection(CollectionReference<Map<String, dynamic>> col) async {
      const batchSize = 300;
      while (true) {
        final snap = await col.limit(batchSize).get();
        if (snap.docs.isEmpty) return;
        final batch = _store.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (snap.docs.length < batchSize) return;
      }
    }

    await wipeCollection(userDoc.collection('tasks'));
    await wipeCollection(userDoc.collection('notes'));
    await wipeCollection(userDoc.collection('habits'));

    final chats = await userDoc.collection('chats').get();
    for (final chat in chats.docs) {
      await wipeCollection(chat.reference.collection('messages'));
      await chat.reference.delete();
    }
    await userDoc.delete();

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      // requires-recent-login: the account data is already gone; the auth
      // record can be removed after re-authentication. Not a blocker.
      if (e.code != 'requires-recent-login') rethrow;
    }
  }

  /// Maps Firebase Auth failures that the Google flow can produce; anything
  /// else surfaces as a generic error (no account details leaked).
  String _mapCode(FirebaseAuthException e) => switch (e.code) {
        'network-request-failed' => 'network',
        'too-many-requests' => 'too-many-requests',
        'user-disabled' => 'wrong-password',
        _ => 'unknown',
      };
}
