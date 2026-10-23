import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/safe_app.dart';
import 'features/settings/app_controller.dart';
import 'services/animal_info_service.dart';
import 'services/classification_service.dart';
import 'services/hardware_service.dart';
import 'services/history_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.load();
  final animals = await AnimalInfoService.load();
  final controller = AppController(
    settings: settings,
    classifier: ClassificationService(settings),
    history: await HistoryService.load(),
    hardware: HardwareService(MockHardwareTransport()),
  );
  controller.refreshModelStatus();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: controller),
      Provider.value(value: animals),
    ],
    child: const SafeApp(),
  ));
}
