import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/errors/safe_exception.dart';
import '../classification/result_screen.dart';
import '../settings/app_controller.dart';

enum CaptureSource { camera, gallery }

/// Picks/captures a still image, previews it, then runs classification.
/// (Live-frame classification is intentionally not implemented in v1.)
class CaptureScreen extends StatefulWidget {
  final CaptureSource? source;
  const CaptureScreen({super.key, this.source});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  File? _image;
  bool _analyzing = false;
  String? _error;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pick(widget.source ?? CaptureSource.camera));
  }

  Future<void> _pick(CaptureSource src) async {
    setState(() {
      _error = null;
      _permanentlyDenied = false;
    });
    try {
      if (src == CaptureSource.camera) {
        final st = await Permission.camera.request();
        if (!st.isGranted) {
          setState(() {
            _permanentlyDenied = st.isPermanentlyDenied;
            _error = 'Camera permission is required to take a photo. '
                'You can also choose a photo from the gallery.';
          });
          return;
        }
      }
      final x = await _picker.pickImage(
          source: src == CaptureSource.camera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 90);
      if (x != null && mounted) setState(() => _image = File(x.path));
    } catch (e) {
      debugPrint('pick failed: $e');
      if (mounted) setState(() => _error = 'Could not open the camera or gallery.');
    }
  }

  Future<void> _analyze() async {
    final img = _image;
    if (img == null || _analyzing) return; // prevents duplicate submissions
    final c = context.read<AppController>();
    setState(() {
      _analyzing = true;
      _error = null;
    });
    try {
      final p = await c.classifier.classify(img);
      if (!mounted) return;
      await Navigator.pushReplacementNamed(context, Routes.result,
          arguments: ResultArgs(img, p));
    } on SafeException catch (e) {
      debugPrint('$e');
      if (mounted) setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Capture')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: SafeColors.surface, borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: _image == null
                      ? const Center(
                          child: Icon(Icons.image_outlined, size: 64, color: SafeColors.muted))
                      : Image.file(_image!, fit: BoxFit.contain),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: SafeColors.danger)),
                ),
              if (_permanentlyDenied)
                TextButton(onPressed: openAppSettings, child: const Text('Open app settings')),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _analyzing ? null : () => _pick(CaptureSource.camera),
                        icon: const Icon(Icons.refresh),
                        label: Text(_image == null ? 'Camera' : 'Retake'))),
                const SizedBox(width: 12),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _analyzing ? null : () => _pick(CaptureSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'))),
              ]),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (_image == null || _analyzing) ? null : _analyze,
                icon: _analyzing
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(_analyzing ? 'Analysing…' : 'Analyse'),
              ),
            ]),
          ),
        ),
      );
}
