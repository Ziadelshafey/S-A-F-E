import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

class SettingsService {
  final SharedPreferences _p;
  SettingsService._(this._p);

  static Future<SettingsService> load() async =>
      SettingsService._(await SharedPreferences.getInstance());

  /// For tests: pass SharedPreferences.setMockInitialValues first.
  static Future<SettingsService> forTest() => load();

  String get apiUrl => _p.getString('apiUrl') ?? AppConfig.defaultApiUrl;
  Future<void> setApiUrl(String v) => _p.setString('apiUrl', v.trim());

  double get threshold =>
      (_p.getDouble('threshold') ?? AppConfig.defaultThreshold).clamp(0.05, 0.99);
  Future<void> setThreshold(double v) => _p.setDouble('threshold', v);

  /// History is opt-in: nothing is stored unless the user enabled it.
  bool get saveHistory => _p.getBool('saveHistory') ?? false;
  Future<void> setSaveHistory(bool v) => _p.setBool('saveHistory', v);
}
