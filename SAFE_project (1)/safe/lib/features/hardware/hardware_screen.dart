import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../services/hardware_service.dart';
import '../settings/app_controller.dart';

class HardwareScreen extends StatelessWidget {
  const HardwareScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final hw = c.hardware;
    return Scaffold(
      appBar: AppBar(title: const Text('Hardware')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        ListTile(
            leading: Icon(Icons.memory,
                color: hw.state == HwState.connected ? SafeColors.teal : SafeColors.muted),
            title: Text(hw.state == HwState.connected
                ? (hw.isSimulated ? 'Connected (simulated device)' : 'Connected')
                : 'Disconnected'),
            subtitle: Text(hw.lastError ?? 'No ESP32 device is paired.')),
        const SizedBox(height: 8),
        if (hw.state != HwState.connected)
          FilledButton(
              onPressed: () => c.connectHardware('mock-safe-device'),
              child: const Text('Connect simulated device (development)'))
        else
          OutlinedButton(onPressed: c.disconnectHardware, child: const Text('Disconnect')),
        const SizedBox(height: 20),
        const Text(
            'Real ESP32 communication is not implemented yet. The protocol is documented in '
            'docs/ESP32_PROTOCOL.md. Hardware output is never triggered by an AI prediction and '
            'always requires explicit confirmation. Ultrasonic deterrence is not proven to be '
            'effective or harmless for all animals.',
            style: TextStyle(color: SafeColors.muted, height: 1.4)),
      ]),
    );
  }
}
