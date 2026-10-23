import 'package:flutter/material.dart';
import '../../app/theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatusChip(
      {super.key, required this.label, required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: SafeColors.surface, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
}
