import "package:flutter/material.dart";
import "../../app/theme.dart";
import "../../shared/models/animal_info.dart";

class AnimalInfoCard extends StatelessWidget {
  final AnimalInfo? info;
  final String label;
  const AnimalInfoCard({super.key, required this.info, required this.label});

  @override
  Widget build(BuildContext context) {
    final i = info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: i == null
            ? Text("General information for \"$label\" is unavailable.")
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Species information (general)",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                const Text("About the predicted category, not this individual animal.",
                    style: TextStyle(color: SafeColors.muted, fontSize: 12)),
                const SizedBox(height: 10),
                _row("Common name", i.commonName),
                _row("Scientific name", i.scientificName),
                _row("Group", i.group),
                _row("Characteristics", i.characteristics),
                _row("Habitat", i.habitat),
                _row("Behaviour", i.behavior),
                _row("Diet", i.diet),
                _row("Encounter risks", i.risks),
              ]),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 108, child: Text(k, style: const TextStyle(color: SafeColors.muted))),
          Expanded(child: Text(v)),
        ]),
      );
}
