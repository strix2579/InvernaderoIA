import 'package:flutter/material.dart';

class CropProgressPanel extends StatelessWidget {
  final double vegetablesTotal;
  final double fruitsTotal;
  final double herbsTotal;

  const CropProgressPanel({
    Key? key,
    required this.vegetablesTotal,
    required this.fruitsTotal,
    required this.herbsTotal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = vegetablesTotal + fruitsTotal + herbsTotal;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
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
                const Icon(
                  Icons.agriculture,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Crop Progress',
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
                // Resumen de categorías
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        label: 'Vegetales',
                        value: vegetablesTotal,
                        gradientColors: const [
                          Color(0xFFECFDF5),
                          Color(0xFFD1FAE5)
                        ],
                        borderColor: const Color(0xFFA7F3D0),
                        textColor: const Color(0xFF047857),
                        trend: '+12%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        label: 'Frutas',
                        value: fruitsTotal,
                        gradientColors: const [
                          Color(0xFFFFF7ED),
                          Color(0xFFFED7AA)
                        ],
                        borderColor: const Color(0xFFFDBA74),
                        textColor: const Color(0xFFEA580C),
                        trend: '+8%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        label: 'Hierbas',
                        value: herbsTotal,
                        gradientColors: const [
                          Color(0xFFFAF5FF),
                          Color(0xFFF3E8FF)
                        ],
                        borderColor: const Color(0xFFE9D5FF),
                        textColor: const Color(0xFF9333EA),
                        trend: '+15%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        label: 'Total',
                        value: total,
                        gradientColors: const [
                          Color(0xFFEFF6FF),
                          Color(0xFFDBEAFE)
                        ],
                        borderColor: const Color(0xFFBFDBFE),
                        textColor: const Color(0xFF2563EB),
                        trend: '+11%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Información adicional
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Production data based on current month',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String label,
    required double value,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color textColor,
    required String trend,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 12,
                    color: textColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
