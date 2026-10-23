/// Build-time defaults. Override with:
///   flutter run --dart-define=SAFE_API_URL=http://192.168.1.20:8000
/// Never use localhost for a physical phone: use your computer's LAN IP
/// (or 10.0.2.2 for the Android emulator). The URL is also editable in Settings.
class AppConfig {
  static const appName = 'SAFE';
  static const appVersion = '1.0.0';
  static const defaultApiUrl =
      String.fromEnvironment('SAFE_API_URL', defaultValue: 'http://10.0.2.2:8000');
  static const defaultThreshold = 0.60;
  static const requestTimeout = Duration(seconds: 30);
  static const healthTimeout = Duration(seconds: 5);
}
