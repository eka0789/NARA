import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/ai/gemini_service.dart';
import 'package:nara/core/bootstrap/app_bootstrap.dart';
import 'package:nara/core/providers/core_providers.dart';
import 'package:nara/core/models/task.dart';
import 'package:nara/core/storage/local_store.dart';
import 'package:nara/core/theme/nara_theme.dart';
import 'package:nara/features/auth/local_auth_repository.dart';
import 'package:nara/features/tasks/tasks_screen.dart';
import 'package:nara/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke test: the tasks screen builds with local-mode repositories and
/// renders the empty state correctly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('TasksScreen renders empty state in local mode', (tester) async {
    final store = LocalStore(await SharedPreferences.getInstance());
    final bootstrap = AppBootstrap(
      firebaseEnabled: false,
      auth: LocalAuthRepository(store),
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
          home: const TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    // Empty state headline from l10n.
    expect(find.text('A clear day starts here'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(4));
  });

  testWidgets('TasksScreen adds a task via repository and shows it', (
    tester,
  ) async {
    final store = LocalStore(await SharedPreferences.getInstance());
    final bootstrap = AppBootstrap(
      firebaseEnabled: false,
      auth: LocalAuthRepository(store),
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
          home: const TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Write a task through the repository the screen watches.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(TasksScreen)));
    final repo = container.read(taskRepositoryProvider);
    await repo.add(
      Task(
        id: 'smoke-1',
        title: 'Buy milk',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
  });
}
