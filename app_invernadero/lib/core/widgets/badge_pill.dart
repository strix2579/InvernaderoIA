import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Badge pill con icono y texto
class BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Border? border;

  const BadgePill({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor = const Color(0xFFECFDF5),
    this.textColor = const Color(0xFF059669),
    this.iconColor = const Color(0xFF059669),
    this.borderRadius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge pill simple sin icono
class SimpleBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const SimpleBadge({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFECFDF5),
    this.textColor = const Color(0xFF059669),
    this.borderRadius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
