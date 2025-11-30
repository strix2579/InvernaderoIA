import 'package:flutter/material.dart';

class TanksPanel extends StatelessWidget {
  final double tank1Level;
  final double tank2Level;

  const TanksPanel({
    Key? key,
    required this.tank1Level,
    required this.tank2Level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tanques de Agua',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTankIndicator(
            label: 'Tanque Principal',
            level: tank1Level,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
          ),
          const SizedBox(height: 20),
          _buildTankIndicator(
            label: 'Tanque Secundario',
            level: tank2Level,
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTankIndicator({
    required String label,
    required double level,
    required Gradient gradient,
  }) {
    final percentage = (level * 100).toInt();
    final isLow = level < 0.3;
    final isHigh = level > 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            Row(
              children: [
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLow
                        ? const Color(0xFFFEE2E2)
                        : (isHigh
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLow
                          ? const Color(0xFFDC2626)
                          : (isHigh
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B)),
                    ),
                  ),
                  child: Text(
                    isLow ? 'BAJO' : (isHigh ? 'ÓPTIMO' : 'MEDIO'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isLow
                          ? const Color(0xFFDC2626)
                          : (isHigh
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B)),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            // Fondo de la barra
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
            ),
            // Barra de progreso con gradiente
            FractionallySizedBox(
              widthFactor: level,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Capacidad: ${(level * 1000).toInt()}L / 1000L',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
