import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../services/classification_service.dart';
import 'app_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url;
  PermissionStatus? _cam;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: context.read<AppController>().settings.apiUrl);
    Permission.camera.status.then((s) => mounted ? setState(() => _cam = s) : null);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final h = c.modelHealth;
    final status = switch (h.status) {
      ModelStatus.ready => 'Ready${h.version != null ? ' (${h.version})' : ''}',
      ModelStatus.loading => 'Loading',
      ModelStatus.unavailable => 'Unavailable${h.detail != null ? ' – ${h.detail}' : ''}',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _h('AI model'),
        ListTile(title: const Text('Status'), subtitle: Text(status)),
        const ListTile(
            title: Text('Inference mode'),
            subtitle: Text('Server (original Keras model via SAFE backend)')),
        if (h.status == ModelStatus.ready)
          ListTile(
              title: const Text('Verification'),
              subtitle: Text('Class order: ${h.labelsVerified ? 'verified' : 'NOT verified'} · '
                  'Preprocessing: ${h.preprocessVerified ? 'verified' : 'NOT verified'}')),
        TextField(
          controller: _url,
          decoration: const InputDecoration(
              labelText: 'Server address', helperText: 'e.g. http://192.168.1.20:8000 (not localhost)'),
          keyboardType: TextInputType.url,
          onSubmitted: c.setApiUrl,
        ),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () => c.setApiUrl(_url.text), child: const Text('Save & test connection'))),
        const SizedBox(height: 8),
        Text('Confidence threshold: ${(c.settings.threshold * 100).toStringAsFixed(0)}%'),
        Slider(
            value: c.settings.threshold,
            min: 0.2,
            max: 0.95,
            divisions: 15,
            onChanged: (v) => c.setThreshold(v)),
        const Text('Results below this raw score are shown as "unable to identify reliably".',
            style: TextStyle(color: SafeColors.muted, fontSize: 12)),
        _h('History & privacy'),
        SwitchListTile(
            title: const Text('Allow saving results'),
            subtitle: const Text('Stores label, scores and time on this device only. No images, no location.'),
            value: c.settings.saveHistory,
            onChanged: c.setSaveHistory),
        ListTile(
            title: const Text('Clear all history'),
            trailing: const Icon(Icons.delete_outline),
            onTap: c.clearHistory),
        const ListTile(
            title: Text('Image handling'),
            subtitle: Text('Photos are sent to your SAFE server for analysis and are not stored by the app.')),
        _h('Device'),
        ListTile(
            title: const Text('Camera permission'),
            subtitle: Text(_cam?.name ?? 'Unknown'),
            trailing: TextButton(onPressed: openAppSettings, child: const Text('Open'))),
        ListTile(
            title: const Text('Hardware'),
            subtitle: Text(c.hardware.state.name),
            onTap: () => Navigator.pushNamed(context, Routes.hardware)),
        _h('About'),
        const ListTile(title: Text('SAFE'), subtitle: Text('Version ${AppConfig.appVersion}')),
        const ListTile(
            title: Text('Model limitations'),
            subtitle: Text(
                'Scores are raw model outputs, not calibrated probabilities. The model only knows 15 '
                'categories and will force any image into one of them. Dogs and wolves can be confused. '
                'Do not rely on SAFE for safety-critical decisions.')),
      ]),
    );
  }

  Widget _h(String t) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(t.toUpperCase(),
          style: const TextStyle(color: SafeColors.teal, letterSpacing: 1.2, fontSize: 12)));
}
