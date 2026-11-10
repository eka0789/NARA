import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/ai/gemini_service.dart';
import 'package:nara/core/bootstrap/app_bootstrap.dart';
import 'package:nara/core/models/user_profile.dart';
import 'package:nara/core/providers/core_providers.dart';
import 'package:nara/core/storage/local_store.dart';
import 'package:nara/core/theme/nara_theme.dart';
import 'package:nara/core/widgets/ui.dart';
import 'package:nara/features/auth/auth_repository.dart';
import 'package:nara/features/auth/local_auth_repository.dart';
import 'package:nara/features/auth/login_screen.dart';
import 'package:nara/features/auth/register_screen.dart';
import 'package:nara/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google-only auth contract: Firebase-mode screens expose exactly one
/// action (Continue with Google), local mode keeps the profile flow.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
  });

  Future<void> pumpAuthScreen(
    WidgetTester tester, {
    required AuthRepository auth,
    required Widget home,
  }) async {
    final bootstrap = AppBootstrap(
      firebaseEnabled: !auth.isLocal,
      auth: auth,
      ai: GeminiService(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          appBootstrapProvider.overrideWithValue(bootstrap),
        ],
        child: MaterialApp(
          theme: NaraTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Firebase login: Google CTA only, no credential fields', (
    tester,
  ) async {
    final auth = _FakeCloudAuth();
    await pumpAuthScreen(tester, auth: auth, home: const LoginScreen());

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(auth.googleCalled, isTrue);
  });

  testWidgets('Firebase register: Google CTA only, no name/email form', (
    tester,
  ) async {
    final auth = _FakeCloudAuth();
    await pumpAuthScreen(tester, auth: auth, home: const RegisterScreen());

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Canceled Google sign-in surfaces a visible hint (never silent)', (
    tester,
  ) async {
    final auth = _FakeCloudAuth()..googleError = AuthException('canceled');
    await pumpAuthScreen(tester, auth: auth, home: const LoginScreen());

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // On Android, CredentialManager throws "canceled" for configuration/SDK
    // problems too (google_sign_in troubleshooting docs), so swallowing it
    // hides real failures — it must produce visible feedback.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('Sign-in was cancelled or blocked by Google'),
      findsOneWidget,
    );
  });

  testWidgets('Google sign-in failure surfaces an error snack', (
    tester,
  ) async {
    final auth = _FakeCloudAuth()..googleError = AuthException('network');
    await pumpAuthScreen(tester, auth: auth, home: const LoginScreen());

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Local register keeps the name-profile flow', (tester) async {
    final auth = LocalAuthRepository(store);
    await pumpAuthScreen(tester, auth: auth, home: const RegisterScreen());

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('Local login shows profile creation route, no Google CTA', (
    tester,
  ) async {
    final auth = LocalAuthRepository(store);
    await pumpAuthScreen(tester, auth: auth, home: const LoginScreen());

    // Banner + shortcut to profile creation; no credential fields and no
    // Google CTA (there is no Google identity in local mode).
    expect(find.text('Local mode — data is stored only on this device. Connect Firebase for cloud sync.'), findsOneWidget);
    expect(find.text('Start with a profile'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('Second tap while Google flow runs is ignored (single call)', (
    tester,
  ) async {
    final auth = _FakeCloudAuth()..gate = Completer<void>();
    await pumpAuthScreen(tester, auth: auth, home: const LoginScreen());

    // Locate the button itself: while the flow runs the label is replaced
    // by a spinner, but the (disabled) button remains tappable.
    final button = find.byType(GoogleSignInButton);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(auth.googleCalls, 1);

    auth.gate!.complete();
    await tester.pumpAndSettle();
    expect(auth.googleCalls, 1);
  });
}

/// Cloud-mode stand-in: records the Google call, optionally blocks it and
/// throws.
class _FakeCloudAuth implements AuthRepository {
  bool googleCalled = false;
  int googleCalls = 0;
  Completer<void>? gate;
  Object? googleError;

  @override
  bool get isLocal => false;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);

  @override
  Stream<UserProfile?> watchProfile() => Stream<UserProfile?>.value(null);

  @override
  Future<void> signInWithGoogle() async {
    googleCalled = true;
    googleCalls += 1;
    final pending = gate;
    if (pending != null) await pending.future;
    final error = googleError;
    if (error != null) throw error;
  }

  @override
  Future<void> createLocalProfile({required String name}) =>
      throw UnsupportedError('cloud mode');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile({String? name, String? avatarEmoji}) async {}

  @override
  Future<void> savePrefs(UserPrefs prefs) async {}

  @override
  Future<void> deleteAllData() async {}
}
