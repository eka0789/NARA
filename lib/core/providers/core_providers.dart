import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/gemini_service.dart';
import '../bootstrap/app_bootstrap.dart';
import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../repositories/disabled_repositories.dart';
import '../storage/local_keys.dart';
import '../storage/local_store.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/chat/chat_repository.dart';
import '../../features/habits/habit_repository.dart';
import '../../features/notes/note_repository.dart';
import '../../features/tasks/task_repository.dart';

/// Overridden with the real instance in `main`.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

/// Overridden with the real instance in `main`.
final appBootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw UnimplementedError('appBootstrapProvider must be overridden'),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(appBootstrapProvider).auth,
);

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final profileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(authRepositoryProvider).watchProfile(),
);

TaskRepository _tasks(Ref ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  if (!bootstrap.firebaseEnabled) {
    return LocalTaskRepository(ref.watch(localStoreProvider));
  }
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const DisabledTaskRepository();
  return FirebaseTaskRepository(user.uid);
}

NoteRepository _notes(Ref ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  if (!bootstrap.firebaseEnabled) {
    return LocalNoteRepository(ref.watch(localStoreProvider));
  }
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const DisabledNoteRepository();
  return FirebaseNoteRepository(user.uid);
}

HabitRepository _habits(Ref ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  if (!bootstrap.firebaseEnabled) {
    return LocalHabitRepository(ref.watch(localStoreProvider));
  }
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const DisabledHabitRepository();
  return FirebaseHabitRepository(user.uid);
}

ChatRepository _chat(Ref ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  if (!bootstrap.firebaseEnabled) {
    return LocalChatRepository(ref.watch(localStoreProvider));
  }
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const DisabledChatRepository();
  return FirebaseChatRepository(user.uid);
}

final taskRepositoryProvider = Provider<TaskRepository>(_tasks);
final noteRepositoryProvider = Provider<NoteRepository>(_notes);
final habitRepositoryProvider = Provider<HabitRepository>(_habits);
final chatRepositoryProvider = Provider<ChatRepository>(_chat);

/// User-entered Gemini key (device-local) merged with the build-time key.
class AiKeyController extends Notifier<String> {
  @override
  String build() =>
      ref.watch(localStoreProvider).readString(LocalKeys.aiKey) ??
      AppConstants.geminiApiKey;

  void set(String? value) {
    ref.read(localStoreProvider).writeString(LocalKeys.aiKey, value);
    state = value ?? AppConstants.geminiApiKey;
  }

  void clear() => set(null);
}

final aiKeyProvider =
    NotifierProvider<AiKeyController, String>(AiKeyController.new);

/// User-set models base URL (device-local) merged with the build-time default.
class AiBaseUrlController extends Notifier<String> {
  @override
  String build() =>
      ref.watch(localStoreProvider).readString(LocalKeys.aiBaseUrl) ??
      AppConstants.geminiBaseUrl;

  void set(String? value) {
    final clean = value?.trim() ?? '';
    ref.read(localStoreProvider).writeString(
          LocalKeys.aiBaseUrl,
          clean.isEmpty ? null : clean,
        );
    state = clean.isEmpty ? AppConstants.geminiBaseUrl : clean;
  }
}

final aiBaseUrlProvider =
    NotifierProvider<AiBaseUrlController, String>(AiBaseUrlController.new);

/// User-set cloud model name (device-local) merged with the build-time default.
class AiModelController extends Notifier<String> {
  @override
  String build() =>
      ref.watch(localStoreProvider).readString(LocalKeys.aiModel) ??
      AppConstants.geminiModel;

  void set(String? value) {
    final clean = value?.trim() ?? '';
    ref.read(localStoreProvider).writeString(
          LocalKeys.aiModel,
          clean.isEmpty ? null : clean,
        );
    state = clean.isEmpty ? AppConstants.geminiModel : clean;
  }
}

final aiModelProvider =
    NotifierProvider<AiModelController, String>(AiModelController.new);

/// Wire format for cloud AI calls: Gemini REST (default) or OpenAI-compatible.
class AiApiStyleController extends Notifier<AiApiStyle> {
  @override
  AiApiStyle build() => AiApiStyle.fromName(
        ref.watch(localStoreProvider).readString(LocalKeys.aiApiStyle),
      );

  void set(AiApiStyle value) {
    ref.read(localStoreProvider).writeString(LocalKeys.aiApiStyle, value.name);
    state = value;
  }
}

final aiApiStyleProvider =
    NotifierProvider<AiApiStyleController, AiApiStyle>(AiApiStyleController.new);

/// True when cloud AI has a key available (build-time or user-provided).
final cloudAiEnabledProvider = Provider<bool>(
  (ref) => ref.watch(aiKeyProvider).trim().isNotEmpty,
);

/// A GeminiService bound to the current key/endpoint/model/format config.
final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(
    apiKey: ref.watch(aiKeyProvider),
    baseUrl: ref.watch(aiBaseUrlProvider),
    model: ref.watch(aiModelProvider),
    apiStyle: ref.watch(aiApiStyleProvider),
  ),
);
