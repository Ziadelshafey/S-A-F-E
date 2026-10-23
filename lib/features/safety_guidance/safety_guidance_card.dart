import "package:flutter/material.dart";
import "../../app/theme.dart";
import "../../shared/models/animal_info.dart";

class SafetyGuidanceCard extends StatelessWidget {
  final AnimalInfo? info;
  const SafetyGuidanceCard({super.key, required this.info});

  static const general = [
    "Keep a safe distance; do not approach, corner, touch or feed the animal.",
    "Move calmly. Avoid sudden movements and loud noises.",
    "Leave the area or move to a safe place if you feel threatened.",
    "Contact local animal control, wildlife authorities or emergency services if there is danger.",
  ];

  @override
  Widget build(BuildContext context) {
    final specific = info?.safety ?? const <String>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.health_and_safety_outlined, color: SafeColors.teal),
            SizedBox(width: 8),
            Text("Safety guidance", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          if (specific.isNotEmpty) ...[
            const Text("For this category", style: TextStyle(color: SafeColors.muted)),
            for (final s in specific) _bullet(s),
            const SizedBox(height: 8),
          ],
          const Text("General principles", style: TextStyle(color: SafeColors.muted)),
          for (final s in general) _bullet(s),
          const SizedBox(height: 10),
          const Text(
              "Species alone does not determine whether an animal is dangerous. SAFE cannot "
              "assess aggression, illness or rabies from a photo. It is not a substitute for "
              "professional wildlife guidance or emergency services.",
              style: TextStyle(color: SafeColors.warn, fontSize: 12, height: 1.4)),
        ]),
      ),
    );
  }

  Widget _bullet(String s) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("•  "),
          Expanded(child: Text(s, style: const TextStyle(height: 1.35))),
        ]),
      );
}
