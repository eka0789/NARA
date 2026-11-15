import 'package:cloud_firestore/cloud_firestore.dart';

/// A free-form note — a Notion-style page: optional color and pin, an
/// optional parent page (sub-pages make a tree), and free-form tags.
class Note {
  const Note({
    required this.id,
    this.title = '',
    this.body = '',
    this.colorIndex = 0,
    this.pinned = false,
    this.parentId,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final int colorIndex;
  final bool pinned;

  /// Parent page id; null for top-level pages.
  final String? parentId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const _sentinel = Object();

  Note copyWith({
    String? id,
    String? title,
    String? body,
    int? colorIndex,
    bool? pinned,
    Object? parentId = _sentinel,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      colorIndex: colorIndex ?? this.colorIndex,
      pinned: pinned ?? this.pinned,
      parentId: parentId == _sentinel ? this.parentId : parentId as String?,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'colorIndex': colorIndex,
        'pinned': pinned,
        'parentId': parentId,
        'tags': tags,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Note(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      colorIndex: (map['colorIndex'] as int?) ?? 0,
      pinned: (map['pinned'] as bool?) ?? false,
      parentId: (map['parentId'] as String?),
      tags: [
        for (final tag in (map['tags'] as List? ?? const []))
          if (tag is String && tag.trim().isNotEmpty) tag.trim(),
      ],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        body.toLowerCase().contains(q) ||
        tags.any((tag) => tag.toLowerCase().contains(q));
  }
}
