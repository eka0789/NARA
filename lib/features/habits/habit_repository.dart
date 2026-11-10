import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/habit.dart';
import '../../core/storage/local_keys.dart';
import '../../core/storage/local_store.dart';

/// Habit persistence contract with Firebase and local implementations.
///
/// Check-in logs are stored as day keys (`yyyy-MM-dd`): one document/map
/// entry per habit, one key per completed day. This makes streak math and
/// weekly rollups cheap and unambiguous across timezones.
abstract interface class HabitRepository {
  Stream<List<Habit>> watchAll();

  Future<List<Habit>> getAll();

  Future<void> add(Habit habit);

  Future<void> update(Habit habit);

  Future<void> delete(String id);

  Future<void> deleteAll();

  /// habitId -> set of completed day keys.
  Stream<Map<String, Set<String>>> watchLogs();

  /// Toggles the check-in for [habitId] on [dateKey].
  Future<void> toggleLog(String habitId, String dateKey);
}

/// Firestore-backed implementation (production).
class FirebaseHabitRepository implements HabitRepository {
  FirebaseHabitRepository(this._uid, {FirebaseFirestore? store})
      : _store = store ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _store;

  CollectionReference<Map<String, dynamic>> get _col =>
      _store.collection('users').doc(_uid).collection('habits');

  CollectionReference<Map<String, dynamic>> _logs(String habitId) =>
      _col.doc(habitId).collection('logs');

  @override
  Stream<List<Habit>> watchAll() => _col
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Habit.fromMap({...doc.data(), 'id': doc.id}))
          .toList());

  @override
  Future<List<Habit>> getAll() async {
    final snap = await _col.orderBy('createdAt', descending: false).get();
    return snap.docs
        .map((doc) => Habit.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> add(Habit habit) => _col.doc(habit.id).set(habit.toMap());

  @override
  Future<void> update(Habit habit) => _col.doc(habit.id).set(habit.toMap());

  @override
  Future<void> delete(String id) async {
    // Logs are a subcollection; delete each entry first (small per habit).
    final logs = await _logs(id).get();
    final batch = _store.batch();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_col.doc(id));
    await batch.commit();
  }

  @override
  Future<void> deleteAll() async {
    final habits = await _col.get();
    for (final doc in habits.docs) {
      await delete(doc.id);
    }
  }

  @override
  Stream<Map<String, Set<String>>> watchLogs() {
    // Log documents are keyed by day (`yyyy-MM-dd`), so listening per habit
    // is bounded and gives instant updates. Streams are attached lazily as
    // habits appear and evicted when a habit is deleted.
    final controller = StreamController<Map<String, Set<String>>>.broadcast();
    final habitSubs = <String, StreamSubscription<dynamic>>{};
    final cache = <String, Set<String>>{};

    void emit() => controller.add({
          for (final entry in cache.entries) entry.key: Set.of(entry.value),
        });

    final habitsSub = watchAll().listen((habits) {
      final active = {for (final habit in habits) habit.id};
      // Evict listeners + cache entries for habits that no longer exist.
      for (final id in habitSubs.keys.toList()) {
        if (!active.contains(id)) {
          habitSubs.remove(id)?.cancel();
          cache.remove(id);
        }
      }
      for (final habit in habits) {
        if (habitSubs.containsKey(habit.id)) continue;
        cache[habit.id] = <String>{};
        habitSubs[habit.id] = _logs(habit.id).snapshots().listen((snap) {
          cache[habit.id] = {
            for (final doc in snap.docs)
              if (doc.data()['done'] == true) doc.id,
          };
          emit();
        });
      }
      emit();
    });

    controller.onCancel = () async {
      await habitsSub.cancel();
      for (final sub in habitSubs.values) {
        await sub.cancel();
      }
      habitSubs.clear();
    };
    return controller.stream;
  }

  @override
  Future<void> toggleLog(String habitId, String dateKey) async {
    final doc = await _logs(habitId).doc(dateKey).get();
    if (doc.exists && doc.data()?['done'] == true) {
      await doc.reference.delete();
    } else {
      await doc.reference
          .set({'done': true, 'at': FieldValue.serverTimestamp()});
    }
  }
}

/// SharedPreferences-backed implementation (local/demo mode).
class LocalHabitRepository implements HabitRepository {
  LocalHabitRepository(this._store);

  final LocalStore _store;

  List<Habit> _read() =>
      _store.readList(LocalKeys.habits).map(Habit.fromMap).toList();

  void _write(List<Habit> habits) => _store.writeList(
        LocalKeys.habits,
        habits.map((h) => h.toMap()).toList(),
      );

  Map<String, List<String>> _readLogs() =>
      _store.readMapOfSets(LocalKeys.habitLogs);

  void _writeLogs(Map<String, List<String>> logs) =>
      _store.writeMapOfSets(LocalKeys.habitLogs, logs);

  @override
  Stream<List<Habit>> watchAll() => _store.watch(LocalKeys.habits, _read);

  @override
  Future<List<Habit>> getAll() async => _read();

  @override
  Future<void> add(Habit habit) async => _write([..._read(), habit]);

  @override
  Future<void> update(Habit habit) async {
    _write([
      for (final h in _read())
        if (h.id == habit.id) habit else h,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    _write([for (final h in _read()) if (h.id != id) h]);
    final logs = _readLogs()..remove(id);
    _writeLogs(logs);
  }

  @override
  Future<void> deleteAll() async {
    _write(const []);
    _writeLogs(const {});
  }

  @override
  Stream<Map<String, Set<String>>> watchLogs() => _store
      .watch<Map<String, List<String>>>(LocalKeys.habitLogs, _readLogs)
      .map((logs) => {for (final e in logs.entries) e.key: Set.of(e.value)});

  @override
  Future<void> toggleLog(String habitId, String dateKey) async {
    final logs = Map.of(_readLogs());
    final days = List.of(logs[habitId] ?? const <String>[]);
    if (days.contains(dateKey)) {
      days.remove(dateKey);
    } else {
      days.add(dateKey);
    }
    logs[habitId] = days;
    _writeLogs(logs);
  }
}
