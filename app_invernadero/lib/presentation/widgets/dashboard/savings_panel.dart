import 'package:flutter/material.dart';

class SavingsPanel extends StatelessWidget {
  final double energySaved; // kWh
  final double waterSaved; // Litros
  final double moneySaved; // MXN

  const SavingsPanel({
    Key? key,
    required this.energySaved,
    required this.waterSaved,
    required this.moneySaved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ahorros del Sistema',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSavingCard(
                        icon: Icons.flash_on,
                        label: 'Energy Saved',
                        value: energySaved.toStringAsFixed(1),
                        unit: 'kWh',
                        gradientColors: const [
                          Color(0xFFFACC15),
                          Color(0xFFF97316)
                        ],
                        lightBg: const Color(0xFFFEFCE8),
                        borderColor: const Color(0xFFFDE68A),
                        iconColor: const Color(0xFFD97706),
                        trend: '+23%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSavingCard(
                        icon: Icons.water_drop,
                        label: 'Water Saved',
                        value: waterSaved.toStringAsFixed(0),
                        unit: 'L',
                        gradientColors: const [
                          Color(0xFF3B82F6),
                          Color(0xFF06B6D4)
                        ],
                        lightBg: const Color(0xFFEFF6FF),
                        borderColor: const Color(0xFFBFDBFE),
                        iconColor: const Color(0xFF2563EB),
                        trend: '+18%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSavingCard(
                  icon: Icons.attach_money,
                  label: 'Money Saved',
                  value: moneySaved.toStringAsFixed(0),
                  unit: 'MXN',
                  gradientColors: const [Color(0xFF10B981), Color(0xFF22C55E)],
                  lightBg: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFA7F3D0),
                  iconColor: const Color(0xFF059669),
                  trend: '+31%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required List<Color> gradientColors,
    required Color lightBg,
    required Color borderColor,
    required Color iconColor,
    required String trend,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightBg,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y tendencia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          // Valor
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
