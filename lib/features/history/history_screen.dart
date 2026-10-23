import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../settings/app_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final items = c.history.entries;
    final fmt = DateFormat('d MMM yyyy, HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('History'), actions: [
        if (items.isNotEmpty)
          IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                          title: const Text('Clear all history?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                          ],
                        ));
                if (ok == true) await c.clearHistory();
              }),
      ]),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No saved identifications yet.', style: TextStyle(color: SafeColors.muted))))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final e = items[i];
                return Dismissible(
                  key: ValueKey(e.id),
                  background: Container(color: SafeColors.danger),
                  onDismissed: (_) => c.deleteHistory(e.id),
                  child: ListTile(
                    title: Text(e.label),
                    subtitle: Text(
                        '${fmt.format(e.timestamp)}${e.feedback == 'incorrect' ? ' · marked incorrect' : ''}\n'
                        '${e.top.map((t) => '${t.label} ${(t.score * 100).toStringAsFixed(0)}%').join(', ')}'),
                    isThreeLine: true,
                    trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => c.deleteHistory(e.id)),
                  ),
                );
              }),
    );
  }
}
