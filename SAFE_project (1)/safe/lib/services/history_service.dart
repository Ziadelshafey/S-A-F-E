import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/history_entry.dart';

/// Local persistent history. Stores no images and no location.
class HistoryService {
  static const _key = 'history_v1';
  static const maxEntries = 200;
  final SharedPreferences _p;
  List<HistoryEntry> _entries;

  HistoryService._(this._p, this._entries);

  static Future<HistoryService> load() async {
    final p = await SharedPreferences.getInstance();
    return HistoryService._(p, _decode(p.getString(_key)));
  }

  static List<HistoryEntry> _decode(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // corrupted storage must not crash the app
    }
  }

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> _persist() =>
      _p.setString(_key, jsonEncode(_entries.map((e) => e.toJson()).toList()));

  Future<void> add(HistoryEntry e) async {
    _entries = [e, ..._entries.where((x) => x.id != e.id)];
    if (_entries.length > maxEntries) _entries = _entries.sublist(0, maxEntries);
    await _persist();
  }

  Future<void> update(HistoryEntry e) async {
    _entries = _entries.map((x) => x.id == e.id ? e : x).toList();
    await _persist();
  }

  Future<void> delete(String id) async {
    _entries = _entries.where((e) => e.id != id).toList();
    await _persist();
  }

  Future<void> clear() async {
    _entries = [];
    await _p.remove(_key);
  }
}
