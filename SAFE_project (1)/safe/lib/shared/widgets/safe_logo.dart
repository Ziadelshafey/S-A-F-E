import 'package:flutter/material.dart';
import '../../app/theme.dart';

class SafeLogo extends StatelessWidget {
  final double size;
  const SafeLogo({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size * 1.1,
          height: size * 1.1,
          decoration: BoxDecoration(
              color: SafeColors.teal, borderRadius: BorderRadius.circular(size * 0.3)),
          child: Icon(Icons.shield_outlined, color: SafeColors.navy, size: size * 0.75),
        ),
        SizedBox(width: size * 0.35),
        Text('SAFE',
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                letterSpacing: size * 0.12,
                color: SafeColors.text)),
      ]);
}
