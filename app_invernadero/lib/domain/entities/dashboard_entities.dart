import 'package:flutter/material.dart';

class Plant {
  final int id;
  final String commonName;
  final String scientificName;
  final String idealTemperature;
  final String idealMoisture;
  final String idealPH;
  final String lightType;

  Plant({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.idealTemperature,
    required this.idealMoisture,
    required this.idealPH,
    required this.lightType,
  });
}

class SelectedPlant {
  final String id;
  final String commonName;
  final String scientificName;
  final String idealTemperature;
  final String idealMoisture;
  final String idealPH;
  final String lightType;

  SelectedPlant({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.idealTemperature,
    required this.idealMoisture,
    required this.idealPH,
    required this.lightType,
  });
}

class Recommendation {
  final IconData icon;
  final String title;
  final String description;
  final String status; // 'optimal', 'action', 'warning'

  Recommendation({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
  });
}

class AlertItem {
  final String id;
  final String severity; // 'info', 'warn', 'error'
  final String source;
  final String message;
  final String value;
  final String timestamp;

  AlertItem({
    required this.id,
    required this.severity,
    required this.source,
    required this.message,
    required this.value,
    required this.timestamp,
  });
}

// Catálogo de plantas completo
class PlantCatalog {
  static final List<String> _plantNames = [
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

  static List<Plant> get plants {
    return List.generate(_plantNames.length, (index) {
      final name = _plantNames[index];
      return Plant(
        id: index + 1,
        commonName: name,
        scientificName: _getScientificName(name),
        idealTemperature: '20-25°C', // Valor genérico por defecto
        idealMoisture: '60-70%',      // Valor genérico por defecto
        idealPH: '6.0-7.0',           // Valor genérico por defecto
        lightType: 'Variable',        // Valor genérico por defecto
      );
    });
  }

  static String _getScientificName(String commonName) {
    // Mapeo simple para algunos nombres comunes, el resto genérico
    final map = {
      'Tomate': 'Solanum lycopersicum',
      'Lechuga': 'Lactuca sativa',
      'Espinaca': 'Spinacia oleracea',
      'Pepino': 'Cucumis sativus',
      'Zanahoria': 'Daucus carota',
      'Maíz dulce': 'Zea mays',
      'Arroz': 'Oryza sativa',
      'Aloe vera': 'Aloe barbadensis miller',
      'Monstera deliciosa': 'Monstera deliciosa',
    };
    return map[commonName] ?? 'Species $commonName';
  }
}
