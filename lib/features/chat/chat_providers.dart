import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/ai/assistant_context.dart';
import '../../core/ai/assistant_engine.dart';
import '../../core/ai/gemini_service.dart';
import '../../core/models/chat_message.dart';
import '../../core/models/note.dart';
import '../../core/models/task.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_time_ext.dart';
import '../data/data_providers.dart';
import '../settings/settings_providers.dart';

final assistantEngineProvider =
    Provider<AssistantEngine>((ref) => AssistantEngine());

final _uuid = const Uuid();

/// UI state of the chat screen (messages themselves live in the repository
/// stream so they persist across restarts).
class ChatUiState {
  const ChatUiState({this.thinking = false, this.errorCode});

  final bool thinking;

  /// Last cloud-AI failure code (null when healthy).
  final String? errorCode;

  static const _unset = Object();

  ChatUiState copyWith({bool? thinking, Object? errorCode = _unset}) =>
      ChatUiState(
        thinking: thinking ?? this.thinking,
        errorCode:
            errorCode == _unset ? this.errorCode : errorCode as String?,
      );
}

/// Orchestrates a chat turn: persist → route to cloud or on-device engine →
/// persist reply → apply any actions the engine produced.
class ChatController extends Notifier<ChatUiState> {
  @override
  ChatUiState build() => const ChatUiState();

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.thinking) return;

    final repo = ref.read(chatRepositoryProvider);
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: text,
      createdAt: DateTime.now(),
    );
    await repo.addMessage(userMessage);
    state = state.copyWith(thinking: true, errorCode: null);

    try {
      final cloud = ref.read(cloudAiEnabledProvider);
      String answer;
      AiSource source;
      List<AssistantAction> actions = const [];

      if (cloud) {
        try {
          final history = await _history(excludeId: userMessage.id);
          answer = await ref.read(geminiServiceProvider).generateReply(
                systemPrompt: _systemPrompt(),
                userMessage: text,
                history: history,
              );
          source = AiSource.cloud;
        } on AiException catch (e) {
          // Cloud failed — answer on-device so the conversation never dies.
          final fallback = await _respondLocally(text);
          answer = fallback.$1;
          actions = fallback.$2;
          source = AiSource.local;
          state = state.copyWith(errorCode: e.code);
        }
      } else {
        final (answerText, localActions) = await _respondLocally(text);
        answer = answerText;
        actions = localActions;
        source = AiSource.local;
      }

      await repo.addMessage(ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.assistant,
        text: answer,
        source: source,
        createdAt: DateTime.now(),
      ));
      await _applyActions(actions);
    } on Exception catch (_) {
      state = state.copyWith(errorCode: 'unknown');
    } finally {
      state = state.copyWith(thinking: false);
    }
  }

  Future<void> clear() async {
    await ref.read(chatRepositoryProvider).clear();
    state = const ChatUiState();
  }

  Future<(String, List<AssistantAction>)> _respondLocally(String text) async {
    final ctx = await _context();
    final reply = ref.read(assistantEngineProvider).respond(text, ctx);
    return (reply.text, reply.actions);
  }

  Future<List<ChatMessage>> _history({String? excludeId}) async {
    // The repository stream is the source of truth; read once via getAll
    // equivalent by taking the current stream value.
    final messages = ref.read(chatMessagesProvider).value ?? const <ChatMessage>[];
    return [
      for (final m in messages)
        if (m.id != excludeId) m,
    ];
  }

  Future<AssistantContext> _context() async {
    final tasks = await ref.read(taskRepositoryProvider).getAll();
    final habits = await ref.read(habitRepositoryProvider).getAll();
    final logs = ref.read(habitLogsProvider).value ?? const <String, Set<String>>{};
    final profile = ref.read(profileProvider).value;
    final lang = ref.read(prefsLanguageProvider);
    return AssistantContext(
      langCode: lang,
      now: DateTime.now(),
      name: profile?.name ?? '',
      tasks: tasks,
      habits: habits,
      habitLogs: logs,
    );
  }

  String _systemPrompt() {
    final now = DateTime.now();
    final tasks = ref.read(tasksProvider).value ?? const <Task>[];
    final openTasks = [
      for (final task in tasks.where((t) => !t.done).take(5))
        '- ${task.title}${task.dueDate != null ? ' (due ${dateKey(task.dueDate!)})' : ''}',
    ].join('\n');
    final profile = ref.read(profileProvider).value;
    final name = profile?.name ?? '';

    return 'You are NARA, a warm, upbeat personal assistant inside the NARA '
        'mobile app (tasks, notes, habits). Reply in the SAME language the '
        'user writes in (Indonesian or English). Be concise — under 120 '
        'words — friendly and practical; at most one emoji. '
        'Current date: ${dateKey(now)}. '
        'User: $name. Open tasks:\n${openTasks.isEmpty ? '(none)' : openTasks}\n'
        'You cannot modify app data — if the user asks to create or change '
        'something, tell them to ask the on-device assistant (it handles '
        'commands like "create task ...") or use the app tabs.';
  }

  Future<void> _applyActions(List<AssistantAction> actions) async {
    final now = DateTime.now();
    for (final action in actions) {
      switch (action) {
        case CreateTaskAction(:final title, :final dueDate):
          await ref.read(taskRepositoryProvider).add(Task(
                id: _uuid.v4(),
                title: title,
                dueDate: dueDate,
                createdAt: now,
                updatedAt: now,
              ));
        case CreateNoteAction(:final title, :final body):
          await ref.read(noteRepositoryProvider).add(Note(
                id: _uuid.v4(),
                title: title,
                body: body,
                createdAt: now,
                updatedAt: now,
              ));
        case CheckInHabitAction(:final habitId):
          await ref
              .read(habitRepositoryProvider)
              .toggleLog(habitId, dateKey(now));
      }
    }
  }
}

final chatUiProvider =
    NotifierProvider<ChatController, ChatUiState>(ChatController.new);

final chatMessagesProvider = StreamProvider<List<ChatMessage>>(
  (ref) => ref.watch(chatRepositoryProvider).watchMessages(),
);

/// Language code used by the on-device engine ('id' or 'en').
final prefsLanguageProvider = Provider<String>((ref) {
  final prefs = ref.watch(prefsProvider);
  return prefs.language == 'system'
      ? PlatformDispatcher.instance.locale.languageCode
      : prefs.language;
});
