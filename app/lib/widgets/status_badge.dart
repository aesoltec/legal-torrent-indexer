import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  factory StatusBadge.legal(bool isLegal) {
    return isLegal
        ? const StatusBadge(
            label: 'Autorisé',
            color: AppTheme.success,
            icon: Icons.check_circle_outline,
          )
        : const StatusBadge(
            label: 'Refusé',
            color: AppTheme.danger,
            icon: Icons.block,
          );
  }

  factory StatusBadge.adult(bool isAdult) {
    return isAdult
        ? const StatusBadge(
            label: 'Adulte',
            color: AppTheme.danger,
            icon: Icons.warning_amber_rounded,
          )
        : const StatusBadge(
            label: 'SFW',
            color: AppTheme.success,
            icon: Icons.shield_outlined,
          );
  }

  factory StatusBadge.confidence(String level) {
    final c = switch (level) {
      'high' => AppTheme.success,
      'medium' => AppTheme.warning,
      _ => AppTheme.danger,
    };
    return StatusBadge(
      label: 'Confiance: $level',
      color: c,
      icon: Icons.insights_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
