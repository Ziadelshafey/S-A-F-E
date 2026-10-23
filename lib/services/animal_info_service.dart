import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../shared/models/animal_info.dart';

/// Local, model-independent animal knowledge base (assets/data/animals.json).
class AnimalInfoService {
  final Map<String, AnimalInfo> _data;
  AnimalInfoService(this._data);

  static Future<AnimalInfoService> load() async =>
      AnimalInfoService.fromJsonString(
          await rootBundle.loadString('assets/data/animals.json'));

  factory AnimalInfoService.fromJsonString(String s) {
    final raw = jsonDecode(s) as Map<String, dynamic>;
    return AnimalInfoService(raw.map((k, v) =>
        MapEntry(k.toLowerCase(), AnimalInfo.fromJson(v as Map<String, dynamic>))));
  }

  /// Returns null when the label has no entry (UI then says information is unavailable).
  AnimalInfo? lookup(String label) => _data[label.toLowerCase()];
  int get count => _data.length;
}
