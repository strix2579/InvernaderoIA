import 'package:flutter/material.dart';
import '../../../domain/entities/dashboard_entities.dart';

class AIRecommendations extends StatelessWidget {
  final List<Recommendation> recommendations;

  const AIRecommendations({
    Key? key,
    required this.recommendations,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withOpacity(0.1),
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
                colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
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
                  Icons.psychology,
                  color: Color(0xFF9333EA),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Recommendations',
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
                // AI Status Badge
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                    ),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Engine Active',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Analyzing environmental data in real-time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recomendaciones
                ...recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRecommendationCard(rec),
                    )),

                const SizedBox(height: 16),

                // Performance Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard('94%', 'Efficiency'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard('127', 'Optimizations'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard('24/7', 'Monitoring'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation rec) {
    final config = _getStatusConfig(rec.status);

    return Container(
      decoration: BoxDecoration(
        color: config.backgroundColor,
        border: Border.all(color: config.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              rec.icon,
              size: 20,
              color: config.iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: config.badgeBackground,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              rec.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: config.badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'optimal':
        return StatusConfig(
          backgroundColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFFA7F3D0),
          iconBackground: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF059669),
          badgeBackground: const Color(0xFFD1FAE5),
          badgeText: const Color(0xFF047857),
        );
      case 'action':
        return StatusConfig(
          backgroundColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFDE68A),
          iconBackground: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          badgeBackground: const Color(0xFFFEF3C7),
          badgeText: const Color(0xFF92400E),
        );
      default: // info
        return StatusConfig(
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          iconBackground: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF2563EB),
          badgeBackground: const Color(0xFFDBEAFE),
          badgeText: const Color(0xFF1E40AF),
        );
    }
  }
}



class StatusConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackground;
  final Color iconColor;
  final Color badgeBackground;
  final Color badgeText;

  StatusConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackground,
    required this.iconColor,
    required this.badgeBackground,
    required this.badgeText,
  });
}
