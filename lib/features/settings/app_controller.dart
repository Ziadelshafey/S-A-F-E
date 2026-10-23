import 'package:flutter/foundation.dart';
import '../../services/classification_service.dart';
import '../../shared/models/history_entry.dart';
import '../../services/hardware_service.dart';
import '../../services/history_service.dart';
import '../../services/settings_service.dart';

/// Single app-level state holder (UI never talks to storage/network directly).
class AppController extends ChangeNotifier {
  final SettingsService settings;
  final ClassificationService classifier;
  final HistoryService history;
  final HardwareService hardware;

  ModelHealth modelHealth = const ModelHealth(ModelStatus.loading);

  AppController({
    required this.settings,
    required this.classifier,
    required this.history,
    required this.hardware,
  });

  Future<void> refreshModelStatus() async {
    modelHealth = const ModelHealth(ModelStatus.loading);
    notifyListeners();
    modelHealth = await classifier.checkHealth();
    notifyListeners();
  }

  Future<void> setApiUrl(String v) async {
    await settings.setApiUrl(v);
    await refreshModelStatus();
  }

  Future<void> setThreshold(double v) async {
    await settings.setThreshold(v);
    notifyListeners();
  }

  Future<void> setSaveHistory(bool v) async {
    await settings.setSaveHistory(v);
    notifyListeners();
  }

  Future<void> addHistory(HistoryEntry e) async {
    await history.add(e);
    notifyListeners();
  }

  Future<void> updateHistory(HistoryEntry e) async {
    await history.update(e);
    notifyListeners();
  }

  Future<void> deleteHistory(String id) async {
    await history.delete(id);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await history.clear();
    notifyListeners();
  }

  Future<void> connectHardware(String id) async {
    notifyListeners();
    await hardware.connect(id);
    notifyListeners();
  }

  Future<void> disconnectHardware() async {
    await hardware.disconnect();
    notifyListeners();
  }
}
