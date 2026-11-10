import 'package:cloud_firestore/cloud_firestore.dart';

/// Who produced a chat message.
enum ChatRole { user, assistant }

/// Which engine produced an assistant message.
enum AiSource { local, cloud }

/// One message in the NARA AI conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.source = AiSource.local,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String text;
  final AiSource source;
  final DateTime createdAt;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? text}) => ChatMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        source: source,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.name,
        'text': text,
        'source': source.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatMessage(
      id: (map['id'] as String?) ?? '',
      role: (map['role'] as String?) == 'user' ? ChatRole.user : ChatRole.assistant,
      text: (map['text'] as String?) ?? '',
      source: (map['source'] as String?) == 'cloud' ? AiSource.cloud : AiSource.local,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
