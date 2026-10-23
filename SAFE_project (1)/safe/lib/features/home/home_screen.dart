import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../services/classification_service.dart';
import '../../services/hardware_service.dart';
import '../../shared/widgets/safe_logo.dart';
import '../../shared/widgets/status_chip.dart';
import '../camera/capture_screen.dart';
import '../settings/app_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final h = c.modelHealth;
    final (mLabel, mColor, mIcon) = switch (h.status) {
      ModelStatus.ready => ('Model Ready', SafeColors.teal, Icons.check_circle_outline),
      ModelStatus.loading => ('Model Loading', SafeColors.warn, Icons.hourglass_top),
      ModelStatus.unavailable => ('Model Unavailable', SafeColors.danger, Icons.error_outline),
    };
    final hw = c.hardware.state;
    final hwLabel = hw == HwState.connected
        ? (c.hardware.isSimulated ? 'Hardware Connected (simulated)' : 'Hardware Connected')
        : 'Hardware Disconnected';
    final recent = c.history.entries.take(3).toList();
    final fmt = DateFormat('d MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const SafeLogo(size: 24),
        actions: [
          IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, Routes.settings)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: c.refreshModelStatus,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Identify animals. Stay safe.',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
              'SAFE analyses a photo with an AI model and gives general species '
              'information and cautious safety guidance. Results can be wrong.',
              style: TextStyle(color: SafeColors.muted, height: 1.4)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            StatusChip(label: mLabel, icon: mIcon, color: mColor, onTap: c.refreshModelStatus),
            StatusChip(
                label: hwLabel,
                icon: Icons.memory,
                color: hw == HwState.connected ? SafeColors.teal : SafeColors.muted,
                onTap: () => Navigator.pushNamed(context, Routes.hardware)),
          ]),
          if (h.status == ModelStatus.unavailable && h.detail != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(h.detail!, style: const TextStyle(color: SafeColors.danger, fontSize: 12))),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.center_focus_strong),
            label: const Text('Identify Animal', style: TextStyle(fontSize: 17)),
            onPressed: () =>
                Navigator.pushNamed(context, Routes.capture, arguments: CaptureSource.camera),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take Photo'),
                    onPressed: () => Navigator.pushNamed(context, Routes.capture,
                        arguments: CaptureSource.camera))),
            const SizedBox(width: 12),
            Expanded(
                child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: () => Navigator.pushNamed(context, Routes.capture,
                        arguments: CaptureSource.gallery))),
          ]),
          const SizedBox(height: 28),
          Row(children: [
            const Expanded(
                child: Text('Recent identifications',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.history),
                child: const Text('See all')),
          ]),
          if (recent.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'No saved identifications. History is stored on this device only, and only if you enable it in Settings.',
                        style: TextStyle(color: SafeColors.muted))))
          else
            for (final e in recent)
              Card(
                  child: ListTile(
                      title: Text(e.label),
                      subtitle: Text(fmt.format(e.timestamp)),
                      trailing: Text('${(e.score * 100).toStringAsFixed(0)}%'))),
        ]),
      ),
    );
  }
}
