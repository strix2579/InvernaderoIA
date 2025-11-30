import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/entities/control_command.dart';
import '../../domain/repositories/greenhouse_repository.dart';
import 'providers.dart';

class DashboardState {
  final List<SensorData> sensorData;
  final ConnectionStatus connectionStatus;
  final bool isLoading;
  final List<AlertItem> alerts;
  final List<Recommendation> recommendations;
  final List<SelectedPlant> selectedPlants;
  
  // Estado de plantas activas para control (A y B)
  final String plantAName;
  final String plantBName;
  
  DashboardState({
    this.sensorData = const [],
    this.connectionStatus = ConnectionStatus.disconnected,
    this.isLoading = false,
    this.alerts = const [],
    this.recommendations = const [],
    this.selectedPlants = const [],
    this.plantAName = 'Tomate', // Valor inicial por defecto, se actualizará desde backend
    this.plantBName = 'Lechuga', // Valor inicial por defecto
  });
  
  DashboardState copyWith({
    List<SensorData>? sensorData,
    ConnectionStatus? connectionStatus,
    bool? isLoading,
    List<AlertItem>? alerts,
    List<Recommendation>? recommendations,
    List<SelectedPlant>? selectedPlants,
    String? plantAName,
    String? plantBName,
  }) {
    return DashboardState(
      sensorData: sensorData ?? this.sensorData,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      recommendations: recommendations ?? this.recommendations,
      selectedPlants: selectedPlants ?? this.selectedPlants,
      plantAName: plantAName ?? this.plantAName,
      plantBName: plantBName ?? this.plantBName,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final GreenhouseRepository _repository;
  
  DashboardNotifier(this._repository) : super(DashboardState()) {
    _init();
  }
  
  void _init() {
    // Listen to sensor data stream
    _repository.getSensorDataStream().listen((data) {
      state = state.copyWith(sensorData: data);
      _updateRecommendationsBasedOnSensors(data);
      _checkAlerts(data);
    });
    
    // Listen to connection status
    _repository.getConnectionStatus().listen((status) {
      state = state.copyWith(connectionStatus: status);
    });
    
    // Connect
    connect();
  }
  
  Future<void> connect() async {
    state = state.copyWith(isLoading: true);
    await _repository.connect();
    state = state.copyWith(isLoading: false);
  }
  
  Future<void> disconnect() async {
    await _repository.disconnect();
  }

  void updatePlantName(String plantId, String name) {
    if (plantId == 'A') {
      state = state.copyWith(plantAName: name);
    } else if (plantId == 'B') {
      state = state.copyWith(plantBName: name);
    }
    // TODO: Enviar actualización al backend
  }

  void addPlant(SelectedPlant plant) {
    if (state.selectedPlants.length < 2) {
      final updatedList = [...state.selectedPlants, plant];
      state = state.copyWith(selectedPlants: updatedList);
      // Actualizar nombres de control automáticamente
      if (state.selectedPlants.isEmpty) {
        state = state.copyWith(plantAName: plant.commonName);
      } else if (state.selectedPlants.length == 1) {
        state = state.copyWith(plantBName: plant.commonName);
      }
    }
  }

  void removePlant(String plantId) {
    final updatedList = state.selectedPlants.where((p) => p.id != plantId).toList();
    state = state.copyWith(selectedPlants: updatedList);
  }

  // Lógica de negocio básica para generar recomendaciones reales basadas en sensores
  void _updateRecommendationsBasedOnSensors(List<SensorData> data) {
    // Esta lógica se moverá al backend idealmente, pero por ahora procesamos localmente
    // para reactividad inmediata
    // ... Implementación futura
  }

  Future<void> togglePump(String plantId, bool isActive) async {
    final actuatorId = plantId == 'A' ? 'pump1' : 'pump2';
    await toggleActuator(actuatorId, isActive);
  }

  Future<void> toggleActuator(String actuatorId, bool isActive) async {
    final action = isActive ? 'ON' : 'OFF';
    
    final command = ControlCommand(
      deviceId: actuatorId,
      action: action,
    );
    
    try {
      await _repository.sendControlCommand(command);
      print('Sent command: $actuatorId -> $action');
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  void _checkAlerts(List<SensorData> data) {
    // Generar alertas locales si los valores salen de rango
    // ... Implementación futura
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(greenhouseRepositoryProvider);
  return DashboardNotifier(repository);
});
