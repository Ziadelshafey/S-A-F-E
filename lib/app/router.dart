import 'package:flutter/material.dart';
import '../features/camera/capture_screen.dart';
import '../features/classification/result_screen.dart';
import '../features/hardware/hardware_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

class Routes {
  static const home = '/';
  static const capture = '/capture';
  static const result = '/result';
  static const history = '/history';
  static const settings = '/settings';
  static const hardware = '/hardware';
}

class AppRouter {
  static Route<dynamic> generate(RouteSettings s) {
    final Widget page;
    switch (s.name) {
      case Routes.capture:
        page = CaptureScreen(source: s.arguments as CaptureSource?);
        break;
      case Routes.result:
        page = ResultScreen(args: s.arguments as ResultArgs);
        break;
      case Routes.history:
        page = const HistoryScreen();
        break;
      case Routes.settings:
        page = const SettingsScreen();
        break;
      case Routes.hardware:
        page = const HardwareScreen();
        break;
      default:
        page = const HomeScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
