import 'package:flutter/material.dart';

import '../core/nexio.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: NexioColors.smallTitle),
            const SizedBox(height: 10),
            Text(text, style: NexioType.body2),
          ],
        ),
      ),
    );
  }
}

Color probabilityColor(String probability) {
  switch (probability) {
    case '高':
      return NexioColors.error;
    case '低':
      return const Color(0xFF30A46C);
    default:
      return const Color(0xFFF5A524);
  }
}

class ProbabilityChip extends StatelessWidget {
  final String probability;
  const ProbabilityChip({super.key, required this.probability});

  @override
  Widget build(BuildContext context) {
    final c = probabilityColor(probability);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$probability风险',
          style: NexioType.footnote2
              .copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}