import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../services/animal_info_service.dart';
import '../../shared/models/history_entry.dart';
import '../../shared/models/prediction.dart';
import '../animal_info/animal_info_card.dart';
import '../camera/capture_screen.dart';
import '../safety_guidance/safety_guidance_card.dart';
import '../settings/app_controller.dart';

class ResultArgs {
  final File image;
  final Prediction prediction;
  const ResultArgs(this.image, this.prediction);
}

class ResultScreen extends StatefulWidget {
  final ResultArgs args;
  const ResultScreen({super.key, required this.args});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  HistoryEntry? _saved;

  Prediction get p => widget.args.prediction;

  Future<void> _save() async {
    final c = context.read<AppController>();
    if (!c.settings.saveHistory) {
      final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text('Save history on this device?'),
                content: const Text(
                    'SAFE will store the label, scores and time of saved results locally. '
                    'No images or location are stored. You can turn this off or delete it in Settings.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Allow & save')),
                ],
              ));
      if (ok != true) return;
      await c.setSaveHistory(true);
    }
    final entry = HistoryEntry.fromPrediction(p);
    await c.addHistory(entry);
    if (!mounted) return;
    setState(() => _saved = entry);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved to history on this device.')));
  }

  Future<void> _report() async {
    final c = context.read<AppController>();
    if (_saved != null) {
      _saved = _saved!.withFeedback('incorrect');
      await c.updateHistory(_saved!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marked as incorrect. Feedback stays on this device.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = context.read<AnimalInfoService>().lookup(p.label);
    final accepted = p.accepted;
    final statusColor = accepted ? SafeColors.teal : SafeColors.warn;
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(widget.args.image, height: 220, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          if (!p.labelsVerified || !p.preprocessVerified)
            _banner(
                Icons.science_outlined,
                'Model setup not fully verified (${!p.labelsVerified ? 'class order' : ''}'
                '${!p.labelsVerified && !p.preprocessVerified ? ', ' : ''}'
                '${!p.preprocessVerified ? 'preprocessing' : ''}). Treat results with extra caution.',
                SafeColors.warn),
          if (accepted) ...[
            Row(children: [
              Icon(Icons.pets, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(p.label,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 4),
            Text('Model score: ${(p.score * 100).toStringAsFixed(1)}% (raw output, not a calibrated probability)',
                style: const TextStyle(color: SafeColors.muted, fontSize: 13)),
          ] else
            _banner(Icons.help_outline,
                'Unable to identify reliably. Please capture another image.', SafeColors.warn),
          if (p.ambiguous)
            _banner(Icons.compare_arrows,
                'The top predictions have similar scores. The result may be wrong.', SafeColors.warn),
          for (final w in p.qualityWarnings)
            _banner(Icons.photo_size_select_actual_outlined, _qualityText(w), SafeColors.warn),
          const SizedBox(height: 12),
          const Text('Top predictions', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final t in p.top)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 84, child: Text(t.label)),
                Expanded(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: t.score,
                            minHeight: 8,
                            color: statusColor,
                            backgroundColor: SafeColors.surfaceHi))),
                SizedBox(
                    width: 56,
                    child: Text('${(t.score * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.end)),
              ]),
            ),
          const SizedBox(height: 4),
          Text('Inference: ${p.inferenceMs.toStringAsFixed(0)} ms · ${p.modelVersion}',
              style: const TextStyle(color: SafeColors.muted, fontSize: 12)),
          if (accepted) ...[
            const SizedBox(height: 16),
            AnimalInfoCard(info: info, label: p.label),
            const SizedBox(height: 12),
            SafetyGuidanceCard(info: info),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: const Text('Capture another image'),
              onPressed: () => Navigator.pushReplacementNamed(context, Routes.capture,
                  arguments: CaptureSource.camera)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(_saved == null ? 'Save result' : 'Saved'),
                    onPressed: _saved == null ? () => _save() : null)),
            const SizedBox(width: 12),
            Expanded(
                child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report incorrect'),
                    onPressed: _report)),
          ]),
        ]),
      ),
    );
  }

  String _qualityText(String w) => switch (w) {
        'very_dark' => 'The image is very dark; results may be unreliable.',
        'overexposed' => 'The image is overexposed; results may be unreliable.',
        'low_contrast_or_blank' => 'The image has very little detail; results may be unreliable.',
        _ => 'Image quality may be low.',
      };

  Widget _banner(IconData i, String t, Color c) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, color: c, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: const TextStyle(height: 1.35))),
        ]),
      );
}
