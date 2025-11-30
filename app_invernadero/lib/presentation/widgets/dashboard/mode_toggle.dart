import 'package:flutter/material.dart';

class ModeToggle extends StatefulWidget {
  final String currentMode;
  final Function(String)? onModeChange;

  const ModeToggle({
    Key? key,
    required this.currentMode,
    this.onModeChange,
  }) : super(key: key);

  @override
  State<ModeToggle> createState() => _ModeToggleState();
}

class _ModeToggleState extends State<ModeToggle> {
  bool _isAutoHovered = false;
  bool _isManualHovered = false;

  @override
  Widget build(BuildContext context) {
    final isAuto = widget.currentMode == 'auto';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.settings_suggest,
                  color: Color(0xFF7C3AED),
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Modo:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Toggles
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactToggle(
                  label: 'Auto',
                  icon: Icons.auto_awesome,
                  isSelected: isAuto,
                  color: const Color(0xFF10B981),
                  onTap: () => widget.onModeChange?.call('auto'),
                ),
                const SizedBox(width: 2),
                _buildCompactToggle(
                  label: 'Manual',
                  icon: Icons.touch_app,
                  isSelected: !isAuto,
                  color: const Color(0xFF3B82F6),
                  onTap: () => widget.onModeChange?.call('manual'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
