import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/chat_message.dart';
import '../../core/storage/local_keys.dart';
import '../../core/storage/local_store.dart';

/// Chat history persistence with Firebase and local implementations.
///
/// v1 uses a single conversation per user (`chats/main`).
abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages();

  Future<void> addMessage(ChatMessage message);

  Future<void> clear();
}

/// Firestore-backed implementation (production).
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository(this._uid, {FirebaseFirestore? store})
      : _store = store ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _store;

  CollectionReference<Map<String, dynamic>> get _messages => _store
      .collection('users')
      .doc(_uid)
      .collection('chats')
      .doc('main')
      .collection('messages');

  @override
  Stream<List<ChatMessage>> watchMessages() => _messages
      .orderBy('createdAt', descending: false)
      .limit(200)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ChatMessage.fromMap({...doc.data(), 'id': doc.id}))
          .toList());

  @override
  Future<void> addMessage(ChatMessage message) async {
    await _messages.doc(message.id).set(message.toMap());
    await _store
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .doc('main')
        .set({'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  @override
  Future<void> clear() async {
    final snap = await _messages.get();
    // Firestore batches cap at 500 operations — chunk so a long history
    // cannot fail the wipe.
    const batchSize = 400;
    for (var start = 0; start < snap.docs.length; start += batchSize) {
      final batch = _store.batch();
      for (final doc in snap.docs.skip(start).take(batchSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _store
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .doc('main')
        .delete();
  }
}

/// SharedPreferences-backed implementation (local/demo mode).
class LocalChatRepository implements ChatRepository {
  LocalChatRepository(this._store);

  final LocalStore _store;

  static const _keep = 200;

  List<ChatMessage> _read() =>
      _store.readList(LocalKeys.chat).map(ChatMessage.fromMap).toList();

  void _write(List<ChatMessage> messages) {
    final bounded = messages.length > _keep
        ? messages.sublist(messages.length - _keep)
        : messages;
    _store.writeList(
      LocalKeys.chat,
      bounded.map((m) => m.toMap()).toList(),
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages() =>
      _store.watch(LocalKeys.chat, _read);

  @override
  Future<void> addMessage(ChatMessage message) async =>
      _write([..._read(), message]);

  @override
  Future<void> clear() async => _write(const []);
}
