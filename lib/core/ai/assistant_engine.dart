import 'dart:math';

import '../utils/date_time_ext.dart';
import '../../features/habits/habit_streak.dart';
import 'assistant_context.dart';

/// NARA's on-device assistant: a deterministic, bilingual intent engine.
///
/// This is tier 1 of the hybrid AI strategy — it runs instantly, offline,
/// and can act on the user's data (create tasks/notes, check in habits).
/// Tier 2 (cloud) enriches open-ended questions when a Gemini key exists.
class AssistantEngine {
  AssistantEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  // ────────────────────────────────────────────────────────────────────────
  // Entry point
  // ────────────────────────────────────────────────────────────────────────

  AssistantReply respond(String input, AssistantContext ctx) {
    final text = input.trim();
    if (text.isEmpty) return AssistantReply(text: _s(ctx).emptyInput);

    final lower = text.toLowerCase();

    final reply = _tryCreateTask(text, lower, ctx) ??
        _tryCreateNote(text, lower, ctx) ??
        _tryCheckInHabit(lower, ctx) ??
        _tryListTasks(lower, ctx) ??
        _tryHabitStatus(lower, ctx) ??
        _tryHelp(lower, ctx) ??
        _tryPersona(lower, ctx) ??
        _tryDateTime(lower, ctx) ??
        _tryMotivation(lower, ctx) ??
        _tryThanks(lower, ctx) ??
        _tryGreeting(lower, ctx) ??
        _fallback(ctx);
    return reply;
  }

  /// A short proactive suggestion for the dashboard card.
  String dailySuggestion(AssistantContext ctx) {
    final s = _s(ctx);
    final today = dateKey(ctx.now);
    final openToday = ctx.tasks
        .where((t) => !t.done && t.dueDate != null && t.dueDate!.isSameDay(ctx.now))
        .length;
    final overdue = ctx.tasks.where((t) => t.isOverdue(ctx.now)).length;
    final habitsPending = ctx.habits
        .where((h) => !(ctx.habitLogs[h.id] ?? const {}).contains(today))
        .length;

    if (overdue > 0) {
      return s.suggestionOverdue(overdue);
    }
    if (openToday > 0) {
      return s.suggestionTasksToday(openToday);
    }
    if (habitsPending > 0 && ctx.habits.isNotEmpty) {
      return s.suggestionHabits(habitsPending);
    }
    if (ctx.habits.isNotEmpty) {
      final best = [
        for (final h in ctx.habits) bestStreak(ctx.habitLogs[h.id] ?? {}, ctx.now),
      ].fold<int>(0, max);
      if (best >= 3) return s.suggestionStreak(best);
    }
    return s.suggestionDefault;
  }

  // ────────────────────────────────────────────────────────────────────────
  // Intents
  // ────────────────────────────────────────────────────────────────────────

  AssistantReply? _tryCreateTask(String raw, String lower, AssistantContext ctx) {
    final s = _s(ctx);
    final hasTrigger = _matchesAny(lower, s.taskTriggers);
    if (!hasTrigger) return null;

    final hasVerb = _matchesAny(lower, s.taskVerbs);
    final isReminder = _matchesAny(lower, s.remindTriggers);
    final explicit = hasVerb || isReminder;
    // Dates inside quotes belong to the title, so the due date is parsed
    // from the text outside quotes. Bare quick-capture ("tugas rapat
    // besok") only counts when a date/time phrase is present — otherwise
    // chatter like "tugas itu berat" would wrongly become a task.
    final outsideQuotes = raw.replaceAll(_quotedText, ' ').toLowerCase();
    final due = _extractDueDate(raw, outsideQuotes, ctx);
    if (!explicit && due == null) return null;

    final title = _extractTaskTitle(raw, lower, ctx);
    if (title == null || title.trim().isEmpty) return null;

    return AssistantReply(
      text: due == null ? s.taskCreatedNoDate(title) : s.taskCreated(title, due),
      actions: [CreateTaskAction(title: title, dueDate: due)],
    );
  }

  AssistantReply? _tryCreateNote(String raw, String lower, AssistantContext ctx) {
    final s = _s(ctx);
    final hasTrigger = _matchesAny(lower, s.noteTriggers);
    if (!hasTrigger) return null;

    String content = '';
    for (final marker in s.noteBodyMarkers) {
      final index = lower.indexOf(marker);
      if (index >= 0) {
        content = raw.substring(min(index + marker.length, raw.length)).trim();
        break;
      }
    }
    if (content.isEmpty) return null;
    content = _stripQuotes(content.replaceAll(_trailingPunctuation, ''));
    if (content.isEmpty) return null;

    return AssistantReply(
      text: s.noteCreated(content),
      actions: [CreateNoteAction(title: content, body: content)],
    );
  }

  AssistantReply? _tryCheckInHabit(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.checkInTriggers)) return null;
    for (final habit in ctx.habits) {
      final name = habit.name.toLowerCase().trim();
      if (name.isNotEmpty && lower.contains(name)) {
        return AssistantReply(
          text: s.habitCheckedIn(habit.name),
          actions: [CheckInHabitAction(habitId: habit.id, habitName: habit.name)],
        );
      }
    }
    return null;
  }

  AssistantReply? _tryListTasks(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.listTriggers)) return null;
    if (!_matchesAny(lower, s.taskTriggers)) return null;

    final open = ctx.tasks.where((t) => !t.done).toList()
      ..sort((a, b) {
        final byPriority = b.priority.index.compareTo(a.priority.index);
        if (byPriority != 0) return byPriority;
        final aDue = a.dueDate?.millisecondsSinceEpoch ??
            DateTime.now().add(const Duration(days: 3650)).millisecondsSinceEpoch;
        final bDue = b.dueDate?.millisecondsSinceEpoch ??
            DateTime.now().add(const Duration(days: 3650)).millisecondsSinceEpoch;
        return aDue.compareTo(bDue);
      });

    if (open.isEmpty) return AssistantReply(text: s.noOpenTasks);
    final top = open.take(3).map((t) => '• ${t.title}').join('\n');
    return AssistantReply(text: s.taskList(top, open.length));
  }

  AssistantReply? _tryHabitStatus(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.habitTriggers)) return null;

    if (ctx.habits.isEmpty) return AssistantReply(text: s.noHabits);

    final today = dateKey(ctx.now);
    final lines = <String>[];
    var doneCount = 0;
    for (final habit in ctx.habits) {
      final logs = ctx.habitLogs[habit.id] ?? const <String>{};
      final done = logs.contains(today);
      if (done) doneCount++;
      final streak = streakFor(logs, ctx.now);
      lines.add('${habit.emoji} ${habit.name} — ${s.streakLine(streak, done)}');
    }
    return AssistantReply(
      text: s.habitStatus(lines.join('\n'), doneCount, ctx.habits.length),
    );
  }

  AssistantReply? _tryHelp(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.helpTriggers)) return null;
    return AssistantReply(text: s.help);
  }

  AssistantReply? _tryPersona(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.personaTriggers)) return null;
    return AssistantReply(text: s.persona);
  }

  AssistantReply? _tryDateTime(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.dateTimeTriggers)) return null;
    return AssistantReply(text: s.dateTimeAnswer(ctx.now));
  }

  AssistantReply? _tryMotivation(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.motivationTriggers)) return null;
    final quotes = ctx.isIndonesian ? _motivationsId : _motivationsEn;
    final quote = quotes[_random.nextInt(quotes.length)];
    return AssistantReply(text: '${s.motivationLead}\n\n"$quote"');
  }

  AssistantReply? _tryThanks(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.thanksTriggers)) return null;
    return AssistantReply(text: s.thanksAnswer);
  }

  AssistantReply? _tryGreeting(String lower, AssistantContext ctx) {
    final s = _s(ctx);
    if (!_matchesAny(lower, s.greetingTriggers)) return null;
    return AssistantReply(text: s.greeting(ctx.name));
  }

  AssistantReply _fallback(AssistantContext ctx) {
    final s = _s(ctx);
    return AssistantReply(text: s.fallback);
  }

  // ────────────────────────────────────────────────────────────────────────
  // Parsing helpers
  // ────────────────────────────────────────────────────────────────────────

  static final RegExp _trailingPunctuation = RegExp(r'[.,!?]+$');
  static final RegExp _quotedText = RegExp('["\'](.+?)["\']');
  static final RegExp _quoteEdges = RegExp('^["\']+|["\']+\$');

  bool _matchesAny(String lower, List<String> patterns) =>
      patterns.any(lower.contains);

  /// Pulls the task title out of a phrase like
  /// "buat tugas 'belanja bulanan' besok" / "remind me to stretch tomorrow".
  String? _extractTaskTitle(String raw, String lower, AssistantContext ctx) {
    final s = _s(ctx);

    // Quoted text wins verbatim — the user delimited it on purpose, so
    // date words inside quotes are part of the title.
    final quoted = _quotedText.firstMatch(raw);
    final quotedTitle = quoted?.group(1)?.trim();
    if (quotedTitle != null && quotedTitle.isNotEmpty) {
      return quotedTitle;
    }

    var anchor = -1;
    var anchorLen = 0;
    for (final marker in s.taskAnchorMarkers) {
      final index = lower.indexOf(marker);
      if (index >= 0 && index + marker.length > anchor + anchorLen) {
        anchor = index + marker.length;
        anchorLen = marker.length;
      }
    }
    String? after;
    if (anchor >= 0 && anchor < raw.length) {
      after = raw.substring(anchor).trim();
    }
    final picked = _stripQuotes((after ?? '').trim());
    if (picked.isEmpty) return null;

    // Remove date/time phrases and filler from the candidate title.
    var cleaned = picked;
    for (final pattern in s.datePhrasePatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), ' ');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(_trailingPunctuation, '');
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  /// Detects "hari ini / besok / weekday / jam 5 / at 6pm" style dates.
  DateTime? _extractDueDate(String raw, String lower, AssistantContext ctx) {
    final s = _s(ctx);
    final now = ctx.now;

    for (final pattern in s.todayPatterns) {
      if (lower.contains(pattern)) return _withTime(now.dayStart, raw, lower, s);
    }
    for (final pattern in s.tomorrowPatterns) {
      if (lower.contains(pattern)) {
        return _withTime(now.dayStart.addDays(1), raw, lower, s);
      }
    }
    if (s.lusaPattern != null && lower.contains(s.lusaPattern!)) {
      return _withTime(now.dayStart.addDays(2), raw, lower, s);
    }
    if (_matchesAny(lower, s.nextWeekPatterns)) {
      return _withTime(now.dayStart.addDays(7), raw, lower, s);
    }
    final weekday = _matchWeekday(lower, s);
    if (weekday != null) {
      var delta = (weekday - now.weekday) % 7;
      if (delta <= 0) delta += 7;
      return _withTime(now.dayStart.addDays(delta), raw, lower, s);
    }
    final timeOnly = _matchTime(lower, s);
    if (timeOnly != null) {
      var due = now.dayStart.add(timeOnly);
      if (due.isBefore(now)) due = due.add(const Duration(days: 1));
      return due;
    }
    return null;
  }

  DateTime _withTime(DateTime day, String raw, String lower, _EngineStrings s) {
    final time = _matchTime(lower, s);
    return time == null ? day : day.add(time);
  }

  /// Returns a Duration-of-day like 17:30, or null.
  Duration? _matchTime(String lower, _EngineStrings s) {
    final match = RegExp(r'(?:jam|pukul|at\s|@)\s*(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm|pagi|siang|sore|malam)?')
        .firstMatch(lower);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    if (hour == null || hour > 24) return null;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final suffix = match.group(3);
    var adjusted = hour;
    if (suffix == 'pm' || suffix == 'sore' || suffix == 'malam') {
      if (adjusted < 12) adjusted += 12;
    } else if (suffix == 'am') {
      if (adjusted == 12) adjusted = 0;
    }
    return Duration(hours: adjusted % 24, minutes: minute);
  }

  int? _matchWeekday(String lower, _EngineStrings s) {
    for (final entry in s.weekdays.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String _stripQuotes(String value) =>
      value.replaceAll(_quoteEdges, '').trim();

  // ────────────────────────────────────────────────────────────────────────
  // Strings & vocabularies (bilingual)
  // ────────────────────────────────────────────────────────────────────────

  _EngineStrings _s(AssistantContext ctx) =>
      ctx.isIndonesian ? _EngineStrings.id() : _EngineStrings.en();

  static const List<String> _motivationsId = [
    'Disiplin adalah memilih antara apa yang kamu inginkan sekarang dan apa yang kamu inginkan paling banyak.',
    'Langkah kecil yang konsisten mengalahkan niat besar yang tidak pernah dimulai.',
    'Kamu tidak harus luar biasa untuk memulai, tapi kamu harus memulai untuk jadi luar biasa.',
    'Istirahat itu bagian dari proses, bukan tanda menyerah. Tarik napas, lalu lanjut.',
    'Fokus pada progres, bukan kesempurnaan. Satu persen lebih baik setiap hari.',
    'Hari yang berat hari ini adalah cerita kebanggaan kamu nanti.',
  ];

  static const List<String> _motivationsEn = [
    'Discipline is choosing between what you want now and what you want most.',
    'Small consistent steps beat big intentions that never start.',
    'You don\'t have to be great to start, but you have to start to be great.',
    'Rest is part of the process, not a sign of giving up. Breathe, then continue.',
    'Focus on progress, not perfection. One percent better every day.',
    'Today\'s hard day is tomorrow\'s proud story.',
  ];
}

/// Bilingual vocabularies and reply templates for [AssistantEngine].
///
/// Kept as a private class so the engine surface stays small and tests can
/// exercise behavior through [AssistantEngine.respond].
class _EngineStrings {
  _EngineStrings._({
    required this.isId,
    required this.emptyInput,
    required this.taskTriggers,
    required this.taskVerbs,
    required this.remindTriggers,
    required this.taskAnchorMarkers,
    required this.noteTriggers,
    required this.noteBodyMarkers,
    required this.checkInTriggers,
    required this.listTriggers,
    required this.habitTriggers,
    required this.helpTriggers,
    required this.personaTriggers,
    required this.dateTimeTriggers,
    required this.motivationTriggers,
    required this.thanksTriggers,
    required this.greetingTriggers,
    required this.todayPatterns,
    required this.tomorrowPatterns,
    required this.lusaPattern,
    required this.nextWeekPatterns,
    required this.weekdays,
    required this.datePhrasePatterns,
  });

  factory _EngineStrings.id() => _EngineStrings._(
        isId: true,
        emptyInput: 'Ada yang bisa NARA bantu? 😊',
        taskTriggers: ['tugas', 'todo', 'to-do', 'jadwal'],
        taskVerbs: ['buat', 'tambah', 'add', 'create', 'new', 'buatin', 'catat tugas'],
        remindTriggers: ['ingatkan', 'ingetin', 'remind'],
        taskAnchorMarkers: ['tugas ', 'ingatkan aku', 'ingatkan saya', 'ingetin aku', 'remind me', 'jadwal ', 'to-do ', 'todo ', 'tugas:'],
        noteTriggers: ['catat', 'catatan', 'note'],
        noteBodyMarkers: ['catat bahwa', 'catat:', 'catat ', 'note:', 'note that', 'note '],
        checkInTriggers: ['sudah', 'udah', 'selesai', 'kelar', 'habis', 'done', 'check in', 'check-in', 'isi kebiasaan'],
        listTriggers: ['lihat', 'list', 'tampilkan', 'show', 'apa saja', 'cek', 'sebutkan', 'daftar'],
        habitTriggers: ['kebiasaan', 'habit', 'streak', 'progress'],
        helpTriggers: ['bantuan', 'bisa apa', 'bantu apa', 'help', 'what can you do', 'fitur', 'kemampuan', 'cara pakai'],
        personaTriggers: ['siapa kamu', 'apa itu nara', 'tentang kamu', 'who are you', 'about you', 'kenalan'],
        dateTimeTriggers: ['jam berapa', 'tanggal berapa', 'hari apa', 'what time', 'what date', 'what day'],
        motivationTriggers: ['motivasi', 'semangat', 'quote', 'kutipan', 'lelah', 'capek', 'stres', 'sedih', 'menyerah', 'down', 'motivation', 'tired'],
        thanksTriggers: ['terima kasih', 'makasih', 'thanks', 'thank you', 'thx'],
        greetingTriggers: ['halo', 'hai nara', 'hello', 'hi nara', 'hei', 'selamat pagi', 'selamat siang', 'selamat sore', 'selamat malam', 'assalamualaikum', 'pagi', 'siang', 'sore', 'malam'],
        todayPatterns: ['hari ini', 'today'],
        tomorrowPatterns: ['besok', 'esok', 'tomorrow'],
        lusaPattern: 'lusa',
        nextWeekPatterns: ['minggu depan', 'next week', 'minggu nanti'],
        weekdays: const {
          'senin': 1, 'selasa': 2, 'rabu': 3, 'kamis': 4, 'jumat': 5,
          'sabtu': 6, 'minggu': 7, 'ahad': 7,
          'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
          'friday': 5, 'saturday': 6, 'sunday': 7,
        },
        datePhrasePatterns: [
          r'\bhari ini\b', r'\btoday\b', r'\bbesok\b', r'\besok\b', r'\btomorrow\b', r'\blusa\b',
          r'\bminggu depan\b', r'\bnext week\b', r'\bminggu nanti\b',
          r'\b(senin|selasa|rabu|kamis|jumat|sabtu|minggu|ahad|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
          r'(?:jam|pukul|at)\s*\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm|pagi|siang|sore|malam)?',
        ],
      );

  factory _EngineStrings.en() => _EngineStrings._(
        isId: false,
        emptyInput: 'How can NARA help? 😊',
        taskTriggers: ['task', 'todo', 'to-do', 'remind', 'schedule'],
        taskVerbs: ['create', 'add', 'make', 'new', 'put'],
        remindTriggers: ['remind', 'reminder'],
        taskAnchorMarkers: ['task ', 'remind me to', 'remind me', 'reminder to', 'to-do ', 'todo ', 'task:'],
        noteTriggers: ['note', 'jot down', 'write down'],
        noteBodyMarkers: ['note that', 'note:', 'note ', 'jot down ', 'write down '],
        checkInTriggers: ['done', 'did', 'finished', 'completed', 'check in', 'check-in'],
        listTriggers: ['show', 'list', 'what are', 'see', 'check', 'any'],
        habitTriggers: ['habit', 'streak', 'progress', 'routine'],
        helpTriggers: ['help', 'what can you do', 'abilities', 'features', 'how to use'],
        personaTriggers: ['who are you', 'what is nara', 'about you', 'introduce'],
        dateTimeTriggers: ['what time', 'what date', 'what day', 'today\'s date'],
        motivationTriggers: ['motivation', 'motivate', 'quote', 'tired', 'exhausted', 'stressed', 'sad', 'give up', 'down'],
        thanksTriggers: ['thank you', 'thanks', 'thx', 'appreciated'],
        greetingTriggers: ['hello', 'hi nara', 'hey', 'good morning', 'good afternoon', 'good evening', 'morning', 'afternoon', 'evening', 'hi'],
        todayPatterns: ['today', 'this evening', 'tonight'],
        tomorrowPatterns: ['tomorrow', 'tmrw'],
        lusaPattern: null,
        nextWeekPatterns: ['next week'],
        weekdays: const {
          'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
          'senin': 1, 'selasa': 2, 'rabu': 3, 'kamis': 4, 'jumat': 5, 'sabtu': 6, 'minggu': 7,
        },
        datePhrasePatterns: [
          r'\btoday\b', r'\btonight\b', r'\bthis evening\b', r'\btomorrow\b', r'\btmrw\b',
          r'\bnext week\b',
          r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|senin|selasa|rabu|kamis|jumat|sabtu|minggu)\b',
          r'(?:at|jam|pukul)\s*\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm|pagi|siang|sore|malam)?',
        ],
      );

  final bool isId;
  final String emptyInput;
  final List<String> taskTriggers;
  final List<String> taskVerbs;
  final List<String> remindTriggers;
  final List<String> taskAnchorMarkers;
  final List<String> noteTriggers;
  final List<String> noteBodyMarkers;
  final List<String> checkInTriggers;
  final List<String> listTriggers;
  final List<String> habitTriggers;
  final List<String> helpTriggers;
  final List<String> personaTriggers;
  final List<String> dateTimeTriggers;
  final List<String> motivationTriggers;
  final List<String> thanksTriggers;
  final List<String> greetingTriggers;
  final List<String> todayPatterns;
  final List<String> tomorrowPatterns;
  final String? lusaPattern;
  final List<String> nextWeekPatterns;
  final Map<String, int> weekdays;
  final List<String> datePhrasePatterns;

  // Template replies.

  String get help => isId
      ? 'Aku NARA, asisten pribadimu. Ini yang bisa kubantu:\n\n'
          '• 📝 Buat tugas — "buat tugas belanja besok jam 8"\n'
          '• 📌 Simpan catatan — "catat bahwa ide aplikasi baru"\n'
          '• ✅ Isi kebiasaan — "sudah olahraga hari ini"\n'
          '• 📋 Cek tugas — "lihat tugas saya"\n'
          '• 🔥 Cek kebiasaan — "bagaimana kebiasaanku?"\n'
          '• 💬 Ngobrol & motivasi — "aku butuh semangat"'
      : 'I\'m NARA, your personal assistant. Here\'s what I can do:\n\n'
          '• 📝 Create tasks — "create task buy groceries tomorrow at 8"\n'
          '• 📌 Save notes — "note that new app idea"\n'
          '• ✅ Check in habits — "done working out today"\n'
          '• 📋 Review tasks — "show my tasks"\n'
          '• 🔥 Habit status — "how are my habits?"\n'
          '• 💬 Chat & motivation — "I need some motivation"';

  String get persona => isId
      ? 'Aku NARA — pendamping pintarmu di smartphone. Kucatat tugasmu, kuingatkan jadwalmu, dan kudukung kebiasaan baikmu setiap hari. hybrid AI: aku jalan instan di perangkat, dan makin pintar saat terhubung AI Cloud. 🌟'
      : 'I\'m NARA — your smart companion on your phone. I keep your tasks, remember your schedule, and cheer on your habits every day. Hybrid AI: I run instantly on-device, and get smarter with AI Cloud. 🌟';

  String dateTimeAnswer(DateTime now) {
    if (isId) {
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return 'Sekarang $hour:$minute, ${days[now.weekday - 1]}, ${now.day} ${months[now.month]} ${now.year}.';
    }
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final marker = now.hour < 12 ? 'AM' : 'PM';
    final minute = now.minute.toString().padLeft(2, '0');
    return 'It\'s $hour12:$minute $marker, ${days[now.weekday - 1]}, ${months[now.month]} ${now.day}, ${now.year}.';
  }

  String get motivationLead =>
      isId ? 'Tarik napas dulu. Ini buatmu:' : 'Take a breath. This one\'s for you:';

  String get thanksAnswer =>
      isId ? 'Dengan senang hati! Aku selalu di sini. 💙' : 'Anytime! I\'m always here for you. 💙';

  String greeting(String name) {
    final who = name.isNotEmpty ? ', $name' : '';
    return isId
        ? 'Halo$who! 👋 Ada yang bisa kubantu hari ini? Coba bilang "buat tugas…" atau tanya apa saja.'
        : 'Hey$who! 👋 What can I do for you today? Try "create a task…" or ask me anything.';
  }

  String get fallback => isId
      ? 'Hmm, aku belum paham maksudmu. 🤔\n\nKamu bisa coba:\n• "buat tugas rapat besok jam 9"\n• "catat bahwa ide kue pandan"\n• "bagaimana kebiasaanku?"\n\nAtau aktifkan AI Cloud di Profil untuk jawaban lebih terbuka.'
      : 'Hmm, I didn\'t quite catch that. 🤔\n\nYou can try:\n• "create task meeting tomorrow at 9"\n• "note that pandan cake idea"\n• "how are my habits?"\n\nOr connect AI Cloud in Profile for more open-ended answers.';

  String taskCreated(String title, DateTime due) {
    final when = _formatWhen(due);
    return isId
        ? 'Oke, tugas "$title" kubuat untuk $when. ✅'
        : 'Done — task "$title" created for $when. ✅';
  }

  String taskCreatedNoDate(String title) => isId
      ? 'Oke, tugas "$title" kubuat tanpa tenggat. ✅'
      : 'Done — task "$title" created without a due date. ✅';

  String noteCreated(String content) => isId
      ? 'Tercatat: "$content". 📌'
      : 'Noted: "$content". 📌';

  String habitCheckedIn(String name) => isId
      ? '"$name" kuisi untuk hari ini. Pertahankan! 🔥'
      : '"$name" checked in for today. Keep it up! 🔥';

  String get noOpenTasks => isId
      ? 'Daftar tugasmu kosong. Waktu yang bagus untuk mulai sesuatu besar. 🌱'
      : 'Your task list is empty. Great time to start something big. 🌱';

  String taskList(String items, int total) => isId
      ? 'Kamu punya $total tugas aktif. Prioritas teratas:\n$items'
      : 'You have $total open tasks. Top priorities:\n$items';

  String get noHabits => isId
      ? 'Kamu belum punya kebiasaan. Buat satu di tab Kebiasaan — mulai dari yang kecil! 🌱'
      : 'You don\'t have habits yet. Create one in the Habits tab — start small! 🌱';

  String streakLine(int streak, bool doneToday) {
    if (isId) {
      if (doneToday && streak > 1) return 'selesai hari ini, streak $streak hari 🔥';
      if (doneToday) return 'selesai hari ini ✓';
      return 'belum diisi hari ini, streak $streak hari';
    }
    if (doneToday && streak > 1) return 'done today, $streak-day streak 🔥';
    if (doneToday) return 'done today ✓';
    return 'not checked in today, $streak-day streak';
  }

  String habitStatus(String lines, int done, int total) => isId
      ? 'Progress kebiasaanmu:\n$lines\n\n$done/$total selesai hari ini.'
      : 'Your habit progress:\n$lines\n\n$done/$total done today.';

  // Suggestions.

  String get suggestionDefault => isId
      ? 'Mulai harimu dengan menulis satu tugas terpenting. Aku bantu catat, bilang saja.'
      : 'Start your day by writing down your single most important task. Just tell me and I\'ll note it.';

  String suggestionTasksToday(int n) => isId
      ? 'Kamu punya $n tugas untuk hari ini. Mulai dari yang paling penting yuk — aku percaya kamu bisa. 💪'
      : 'You have $n tasks for today. Start with the most important one — you\'ve got this. 💪';

  String suggestionOverdue(int n) => isId
      ? 'Ada $n tugas terlewat. Reschedule atau selesaikan sekarang — aku bantu atur. 🙂'
      : '$n tasks are overdue. Reschedule or knock one out now — I\'ll help you sort it. 🙂';

  String suggestionHabits(int n) => isId
      ? '$n kebiasaan belum diisi hari ini. Lima menit sekarang lebih baik dari nol. 🔥'
      : '$n habits aren\'t checked in yet. Five minutes now beats zero. 🔥';

  String suggestionStreak(int streak) => isId
      ? 'Streak terbaikmu $streak hari! Jangan patahkan rantainya hari ini. 🔗'
      : 'Your best streak is $streak days! Don\'t break the chain today. 🔗';

  String _formatWhen(DateTime due) {
    final now = DateTime.now();
    final day = due.dayStart;
    String dayPart;
    if (day.isSameDay(now)) {
      dayPart = isId ? 'hari ini' : 'today';
    } else if (day.isSameDay(now.addDays(1))) {
      dayPart = isId ? 'besok' : 'tomorrow';
    } else {
      const monthsId = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      const monthsEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final months = isId ? monthsId : monthsEn;
      dayPart = '${due.day} ${months[due.month]}';
    }
    final hh = due.hour;
    if (hh == 0 && due.minute == 0) return dayPart;
    final mm = due.minute.toString().padLeft(2, '0');
    if (isId) return '$dayPart pukul $hh:$mm';
    final h12 = hh % 12 == 0 ? 12 : hh % 12;
    final marker = hh < 12 ? 'AM' : 'PM';
    return '$dayPart at $h12:$mm $marker';
  }
}
