import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence layer backed by SharedPreferences.
///
/// Stores JSON documents/arrays under namespaced keys and exposes change
/// streams so repositories can behave reactively (mirroring Firestore
/// snapshots semantics).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;
  final Map<String, StreamController<void>> _controllers = {};

  /// Stream of change events for [key].
  Stream<void> changes(String key) => _controllers
      .putIfAbsent(key, StreamController<void>.broadcast)
      .stream;

  void _emit(String key) =>
      _controllers.putIfAbsent(key, StreamController<void>.broadcast).add(null);

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } on FormatException {
      // Corrupted payload — start clean rather than crash the app.
      return const [];
    }
  }

  void writeList(String key, List<Map<String, dynamic>> value) {
    _prefs.setString(key, jsonEncode(value));
    _emit(key);
  }

  Map<String, dynamic>? readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
  }

  void writeMap(String key, Map<String, dynamic>? value) {
    if (value == null) {
      _prefs.remove(key);
    } else {
      _prefs.setString(key, jsonEncode(value));
    }
    _emit(key);
  }

  Map<String, List<String>> readMapOfSets(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): [
            if (entry.value is List)
              for (final v in entry.value as List) v.toString(),
          ],
      };
    } on FormatException {
      return const {};
    }
  }

  void writeMapOfSets(String key, Map<String, List<String>> value) {
    _prefs.setString(key, jsonEncode(value));
    _emit(key);
  }

  String? readString(String key, {String? fallback}) {
    final value = _prefs.getString(key);
    return value ?? fallback;
  }

  void writeString(String key, String? value) {
    if (value == null) {
      _prefs.remove(key);
    } else {
      _prefs.setString(key, value);
    }
    _emit(key);
  }

  bool readBool(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;

  void writeBool(String key, bool value) {
    _prefs.setBool(key, value);
    _emit(key);
  }

  int readInt(String key, {int fallback = 0}) =>
      _prefs.getInt(key) ?? fallback;

  void writeInt(String key, int value) {
    _prefs.setInt(key, value);
    _emit(key);
  }

  /// Reactive read: emits the current value on listen, then again on every
  /// change of [key]. Single-subscription by design (one provider listens).
  Stream<T> watch<T>(String key, T Function() read) {
    late final StreamController<T> controller;
    late final StreamSubscription<void> sub;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        sub = changes(key).listen((_) => controller.add(read()));
      },
      onCancel: () => sub.cancel(),
    );
    return controller.stream;
  }

  /// Removes every key and fires change events (used by "delete all data").
  void wipeAll(Iterable<String> keys) {
    for (final key in keys) {
      _prefs.remove(key);
      _emit(key);
    }
  }
}
