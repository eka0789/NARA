import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/note.dart';
import '../../core/storage/local_keys.dart';
import '../../core/storage/local_store.dart';

/// Note persistence contract with Firebase and local implementations.
abstract interface class NoteRepository {
  Stream<List<Note>> watchAll();

  Future<List<Note>> getAll();

  Future<void> add(Note note);

  Future<void> update(Note note);

  Future<void> delete(String id);

  Future<void> deleteAll();
}

/// Firestore-backed implementation (production).
class FirebaseNoteRepository implements NoteRepository {
  FirebaseNoteRepository(this._uid, {FirebaseFirestore? store})
      : _store = store ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _store;

  CollectionReference<Map<String, dynamic>> get _col =>
      _store.collection('users').doc(_uid).collection('notes');

  @override
  Stream<List<Note>> watchAll() => _col
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Note.fromMap({...doc.data(), 'id': doc.id}))
          .toList());

  @override
  Future<List<Note>> getAll() async {
    final snap = await _col.orderBy('updatedAt', descending: true).get();
    return snap.docs
        .map((doc) => Note.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> add(Note note) => _col.doc(note.id).set(note.toMap());

  @override
  Future<void> update(Note note) => _col.doc(note.id).set(note.toMap());

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
class LocalNoteRepository implements NoteRepository {
  LocalNoteRepository(this._store);

  final LocalStore _store;

  List<Note> _read() =>
      _store.readList(LocalKeys.notes).map(Note.fromMap).toList();

  void _write(List<Note> notes) => _store.writeList(
        LocalKeys.notes,
        notes.map((n) => n.toMap()).toList(),
      );

  @override
  Stream<List<Note>> watchAll() => _store.watch(LocalKeys.notes, _read);

  @override
  Future<List<Note>> getAll() async => _read();

  @override
  Future<void> add(Note note) async => _write([..._read(), note]);

  @override
  Future<void> update(Note note) async {
    _write([
      for (final n in _read())
        if (n.id == note.id) note else n,
    ]);
  }

  @override
  Future<void> delete(String id) async =>
      _write([for (final n in _read()) if (n.id != id) n]);

  @override
  Future<void> deleteAll() async => _write(const []);
}
