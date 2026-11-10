import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_providers.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../providers/core_providers.dart';
import '../storage/local_keys.dart';

/// Rebuilds [GoRouter] redirects when auth state or onboarding changes.
class RouterRefresh extends ChangeNotifier {
  RouterRefresh(List<Stream<dynamic>> streams) {
    for (final stream in streams) {
      stream.listen((_) => notifyListeners());
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final store = ref.watch(localStoreProvider);
  final refresh = RouterRefresh([
    ref.watch(authRepositoryProvider).authStateChanges(),
    store.changes(LocalKeys.onboardingSeen),
  ]);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == '/splash') return null;

      final seen = ref.read(onboardingSeenProvider);
      if (!seen && location != '/onboarding') return '/onboarding';

      final user = ref.read(authStateProvider).value;
      debugPrint('ROUTER redirect loc=$location user=${user?.uid ?? 'null'} seen=$seen');
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/onboarding';
      if (user == null && !isAuthRoute) return '/login';
      if (user != null && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                builder: (context, state) => const HabitsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/notes', builder: (context, state) => const NotesScreen()),
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) =>
            NoteEditorScreen(noteId: state.pathParameters['id']),
      ),
    ],
  );
});
