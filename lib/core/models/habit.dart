import 'package:cloud_firestore/cloud_firestore.dart';

/// A recurring habit the user wants to build.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.emoji = '✨',
    this.colorIndex = 0,
    this.targetPerWeek = 7,
    this.archived = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String emoji;
  final int colorIndex;
  final int targetPerWeek;
  final bool archived;
  final DateTime createdAt;

  Habit copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorIndex,
    int? targetPerWeek,
    bool? archived,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorIndex: colorIndex ?? this.colorIndex,
      targetPerWeek: targetPerWeek ?? this.targetPerWeek,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorIndex': colorIndex,
        'targetPerWeek': targetPerWeek,
        'archived': archived,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Habit.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    // Clamp out-of-range values: a corrupt targetPerWeek would crash the
    // edit form's Slider (value must stay within 1..7).
    final colorIndex = (map['colorIndex'] as num?)?.toInt() ?? 0;
    final targetPerWeek = ((map['targetPerWeek'] as num?)?.toInt() ?? 7)
        .clamp(1, 7);
    return Habit(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      emoji: (map['emoji'] as String?) ?? '✨',
      colorIndex: colorIndex < 0 ? 0 : colorIndex,
      targetPerWeek: targetPerWeek,
      archived: (map['archived'] as bool?) ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
