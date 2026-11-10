import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/task.dart';
import '../../core/storage/local_keys.dart';
import '../../core/storage/local_store.dart';

/// Task persistence contract with Firebase and local implementations.
abstract interface class TaskRepository {
  Stream<List<Task>> watchAll();

  Future<List<Task>> getAll();

  Future<void> add(Task task);

  Future<void> update(Task task);

  Future<void> delete(String id);

  Future<void> deleteAll();
}

/// Firestore-backed implementation (production).
class FirebaseTaskRepository implements TaskRepository {
  FirebaseTaskRepository(this._uid, {FirebaseFirestore? store})
      : _store = store ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _store;

  CollectionReference<Map<String, dynamic>> get _col =>
      _store.collection('users').doc(_uid).collection('tasks');

  @override
  Stream<List<Task>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Task.fromMap({...doc.data(), 'id': doc.id}))
          .toList());

  @override
  Future<List<Task>> getAll() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => Task.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> add(Task task) => _col.doc(task.id).set(task.toMap());

  @override
  Future<void> update(Task task) => _col.doc(task.id).set(task.toMap());

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  @override
  Future<void> deleteAll() async {
    const batchSize = 300;
    while (true) {
      final snap = await _col.limit(batchSize).get();
      if (snap.docs.isEmpty) return;
      final batch = _store.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < batchSize) return;
    }
  }
}

/// SharedPreferences-backed implementation (local/demo mode).
class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(this._store);

  final LocalStore _store;

  List<Task> _read() =>
      _store.readList(LocalKeys.tasks).map(Task.fromMap).toList();

  void _write(List<Task> tasks) => _store.writeList(
        LocalKeys.tasks,
        tasks.map((t) => t.toMap()).toList(),
      );

  @override
  Stream<List<Task>> watchAll() => _store.watch(LocalKeys.tasks, _read);

  @override
  Future<List<Task>> getAll() async => _read();

  @override
  Future<void> add(Task task) async => _write([..._read(), task]);

  @override
  Future<void> update(Task task) async {
    _write([
      for (final t in _read())
        if (t.id == task.id) task else t,
    ]);
  }

  @override
  Future<void> delete(String id) async =>
      _write([for (final t in _read()) if (t.id != id) t]);

  @override
  Future<void> deleteAll() async => _write(const []);
}
