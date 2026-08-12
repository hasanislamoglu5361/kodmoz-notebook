import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _palette[label.toLowerCase()] ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

const Map<String, Color> _palette = {
  // notebook / source / note status
  'ready': Color(0xFF22C55E),
  'processing': Color(0xFF3B82F6),
  'failed': Color(0xFFEF4444),
  'archived': Color(0xFF6B7280),
  'unknown': Color(0xFF6B7280),
  // note types
  'human': Color(0xFFFBBF24),
  'ai': Color(0xFFA855F7),
  // chat
  'user': Color(0xFF60A5FA),
  'assistant': Color(0xFFA855F7),
  'system': Color(0xFF6B7280),
};

Color statusColor(String label, BuildContext context) =>
    _palette[label.toLowerCase()] ?? Theme.of(context).colorScheme.primary;
