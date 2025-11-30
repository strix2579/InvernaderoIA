import 'package:flutter/material.dart';

class PlantsControlPanel extends StatelessWidget {
  final PlantData plantA;
  final PlantData plantB;
  final String mode;
  final bool isOwner;
  final Function(String, bool)? onTogglePump;
  final Function(String, int)? onDurationChange;
  final Function(String, String)? onPlantTypeChange;

  const PlantsControlPanel({
    Key? key,
    required this.plantA,
    required this.plantB,
    required this.mode,
    this.isOwner = false,
    this.onTogglePump,
    this.onDurationChange,
    this.onPlantTypeChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bothTanksEmpty = !plantA.hasWater && !plantB.hasWater;

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
            color: Colors.black.withOpacity(0.05),
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
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
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
                  Icons.eco,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Control de Plantas',
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
                _buildPlantCard('A', plantA),
                const SizedBox(height: 24),
                _buildPlantCard('B', plantB),

                // Avisos contextuales
                if (mode == 'auto') ...[
                  const SizedBox(height: 16),
                  _buildInfoBanner(
                    'Modo Automático Activo: Las bombas se activarán automáticamente según los niveles de humedad configurados.',
                    Colors.blue,
                  ),
                ],

                if (bothTanksEmpty) ...[
                  const SizedBox(height: 16),
                  _buildWarningBanner(
                    '¡ALERTA! Ambos tanques de agua vacíos. Las bombas no funcionarán hasta que se rellenen los tanques.',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(String plantId, PlantData plant) {
    final humidityStatus = _getHumidityStatus(plant.soilMoisture);
    final isDisabled = mode == 'auto' || !isOwner;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de planta
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planta $plantId',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availablePlants.contains(plant.name) ? plant.name : null,
                        hint: Text(
                          plant.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: availablePlants.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: isDisabled
                            ? null
                            : (newValue) {
                                if (newValue != null) {
                                  onPlantTypeChange?.call(plantId, newValue);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
              if (!plant.hasWater)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Nivel Bajo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Métricas
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: humidityStatus.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 16,
                            color: humidityStatus.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Humedad Suelo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plant.soilMoisture.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: humidityStatus.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        humidityStatus.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.water_drop,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nivel Agua',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plant.hasWater ? 'OK' : 'BAJO',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: plant.hasWater
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Controles
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isDisabled
                      ? null
                      : () => onTogglePump?.call(plantId, !plant.pumpActive),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plant.pumpActive
                        ? const Color(0xFF16A34A)
                        : Colors.grey.shade100,
                    foregroundColor:
                        plant.pumpActive ? Colors.white : Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: plant.pumpActive ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.power_settings_new, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        plant.pumpActive ? 'Bomba ON' : 'Activar Riego',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF4B5563),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: TextField(
                        enabled: !isDisabled,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '${plant.duration}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          final duration = int.tryParse(value);
                          if (duration != null) {
                            onDurationChange?.call(plantId, duration);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'seg',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String message, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  HumidityStatus _getHumidityStatus(double value) {
    if (value < 40) {
      return HumidityStatus(
        color: const Color(0xFFDC2626),
        backgroundColor: const Color(0xFFFEE2E2),
        status: 'Bajo',
      );
    } else if (value > 80) {
      return HumidityStatus(
        color: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFDBEAFE),
        status: 'Alto',
      );
    } else {
      return HumidityStatus(
        color: const Color(0xFF16A34A),
        backgroundColor: const Color(0xFFDCFCE7),
        status: 'Óptimo',
      );
    }
  }
}

class PlantData {
  final String name;
  final double soilMoisture;
  final bool hasWater;
  final bool pumpActive;
  final int duration;

  PlantData({
    this.name = 'Planta Desconocida',
    required this.soilMoisture,
    required this.hasWater,
    this.pumpActive = false,
    this.duration = 10,
  });
}

const List<String> availablePlants = [
  'Tomate', 'Lechuga', 'Espinaca', 'Acelga', 'Col rizada', 'Brócoli', 'Coliflor',
  'Pepino', 'Pimiento morrón', 'Zanahoria', 'Maranta', 'Aglaonema', 'Schefflera',
  'Croton', 'Trigo', 'Cebada', 'Avena', 'Arroz', 'Maíz dulce', 'Frijol', 'Soya',
  'Girasol comestible', 'Amaranto', 'Lenteja', 'Árnica', 'Diente de león',
  'Valeriana', 'Equinácea', 'Ginseng', 'Moringa', 'Hierba luisa', 'Stevia',
  'Bugambilia', 'Cuna de Moisés', 'Bromelia', 'Ave del paraíso', 'Plumeria',
  'Coleo', 'Impatiens', 'Vinca', 'Gardenia', 'Loto', 'Helecho de Boston',
  'Ficus benjamina', 'Monstera deliciosa', 'Pothos', 'Calathea', 'Dieffenbachia',
  'Dracaena', 'Spathiphyllum', 'Anthurium', 'Philodendron', 'Alocasia', 'Maranta',
  'Echeveria', 'Aloe vera', 'Haworthia', 'Lithops', 'Sedum', 'Kalanchoe'
];

class HumidityStatus {
  final Color color;
  final Color backgroundColor;
  final String status;

  HumidityStatus({
    required this.color,
    required this.backgroundColor,
    required this.status,
  });
}
