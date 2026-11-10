import 'package:cloud_firestore/cloud_firestore.dart';

/// Priority levels for a task.
enum TaskPriority { low, medium, high }

/// A single task on the user's list.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.note = '',
    this.done = false,
    this.priority = TaskPriority.medium,
    this.category = 'general',
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String note;
  final bool done;
  final TaskPriority priority;
  final String category;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task copyWith({
    String? id,
    String? title,
    String? note,
    bool? done,
    TaskPriority? priority,
    String? category,
    Object? dueDate = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _sentinel = Object();

  /// Map compatible with Firestore documents and local JSON storage.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'note': note,
        'done': done,
        'priority': priority.index,
        'category': category,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(Object? value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // Corrupt/foreign documents must not throw inside repository streams:
    // one bad field would otherwise kill the whole list (UI shows empty).
    final priorityIndex = ((map['priority'] as num?)?.toInt() ?? 1)
        .clamp(0, TaskPriority.values.length - 1);
    return Task(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      done: (map['done'] as bool?) ?? false,
      priority: TaskPriority.values[priorityIndex],
      category: (map['category'] as String?) ?? 'general',
      dueDate: parseDate(map['dueDate']),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  /// True when the due date is before the given [now] and not done.
  bool isOverdue(DateTime now) =>
      !done && dueDate != null && dueDate!.isBefore(now);
}
