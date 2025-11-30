import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/entities/sensor_data.dart';
import '../widgets/dashboard/header_widget.dart';
import '../widgets/dashboard/hero_section.dart';
import '../widgets/dashboard/connection_status.dart';
import '../widgets/dashboard/sensor_card.dart';
import '../widgets/dashboard/control_panel.dart';
import '../widgets/dashboard/system_info.dart';
import '../widgets/dashboard/alerts_panel.dart';
import '../widgets/dashboard/mode_toggle.dart';
import '../widgets/dashboard/plants_control_panel.dart';
import '../widgets/dashboard/tanks_panel.dart';
import '../widgets/dashboard/plant_selector.dart';
import '../widgets/dashboard/ai_recommendations.dart';
import '../widgets/dashboard/footer.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getSensorValue(List<SensorData> data, String type) {
    try {
      final sensor = data.firstWhere((s) => s.type == type);
      return sensor.value.toStringAsFixed(1);
    } catch (e) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          // Header Sticky
          const SliverToBoxAdapter(
            child: HeaderWidget(),
          ),

          // Hero Section
          const SliverToBoxAdapter(
            child: HeroSection(),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // System Info
                  const SystemInfo(),

                  const SizedBox(height: 32),

                  // Connection Status
                  const ConnectionStatus(),

                  const SizedBox(height: 32),

                  // Alerts Panel
                  AlertsPanel(
                    alerts: dashboardState.alerts,
                    onAcknowledge: (alertId) {
                      // TODO: Implement acknowledge logic via provider
                      print('Acknowledged alert: $alertId');
                    },
                  ),

                  const SizedBox(height: 48),

                  // Mode Toggle
                  ModeToggle(
                    currentMode: 'auto', // TODO: Get from provider
                    onModeChange: (mode) {
                      // TODO: Implement mode change logic via provider
                      print('Mode changed to: $mode');
                    },
                  ),

                  const SizedBox(height: 48),

                  // Sensor Cards Section
                  Text(
                    'Monitoreo en Tiempo Real',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sensor Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 1024;
                      final isTablet = constraints.maxWidth > 768;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          SensorCard(
                            title: 'Temperatura',
                            value: _getSensorValue(dashboardState.sensorData, 'temperature'),
                            unit: '°C',
                            icon: Icons.thermostat_outlined,
                            gradient: AppColors.orangeGradient,
                            optimalRange: '18-30°C',
                            status: SensorStatus.optimal,
                          ),
                          SensorCard(
                            title: 'Humedad',
                            value: _getSensorValue(dashboardState.sensorData, 'humidity'),
                            unit: '%',
                            icon: Icons.water_drop_outlined,
                            gradient: AppColors.blueGradient,
                            optimalRange: '60-75%',
                            status: SensorStatus.optimal,
                          ),
                          SensorCard(
                            title: 'CO₂',
                            value: _getSensorValue(dashboardState.sensorData, 'co2'),
                            unit: 'ppm',
                            icon: Icons.air_outlined,
                            gradient: AppColors.purpleGradient,
                            optimalRange: '350-450 ppm',
                            status: SensorStatus.optimal,
                          ),
                          SensorCard(
                            title: 'AQI',
                            value: _getSensorValue(dashboardState.sensorData, 'aqi'),
                            unit: '',
                            icon: Icons.filter_drama_outlined,
                            gradient: AppColors.emeraldGradient,
                            optimalRange: '0-50',
                            status: SensorStatus.optimal,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // Plants Control & Tanks - Two Columns
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 1024;

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: PlantsControlPanel(
                                plantA: PlantData(
                                  name: dashboardState.plantAName,
                                  soilMoisture: double.tryParse(_getSensorValue(dashboardState.sensorData, 'soil_moisture_a')) ?? 0.0,
                                  hasWater: true, // TODO: Get from sensors
                                  pumpActive: false, // TODO: Get from actuators
                                  duration: 10,
                                ),
                                plantB: PlantData(
                                  name: dashboardState.plantBName,
                                  soilMoisture: double.tryParse(_getSensorValue(dashboardState.sensorData, 'soil_moisture_b')) ?? 0.0,
                                  hasWater: true,
                                  pumpActive: false,
                                  duration: 10,
                                ),
                                mode: 'auto',
                                onTogglePump: (plantId, state) {
                                ref.read(dashboardProvider.notifier).togglePump(plantId, state);
                              },
                                onDurationChange: (plantId, duration) {
                                  print('Duration $plantId: $duration');
                                },
                                onPlantTypeChange: (plantId, name) {
                                  ref.read(dashboardProvider.notifier).updatePlantName(plantId, name);
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            const Expanded(
                              child: TanksPanel(
                                tank1Level: 0.75, // TODO: Get from sensors
                                tank2Level: 0.45,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            PlantsControlPanel(
                              plantA: PlantData(
                                name: dashboardState.plantAName,
                                soilMoisture: double.tryParse(_getSensorValue(dashboardState.sensorData, 'soil_moisture_a')) ?? 0.0,
                                hasWater: true,
                                pumpActive: false,
                                duration: 10,
                              ),
                              plantB: PlantData(
                                name: dashboardState.plantBName,
                                soilMoisture: double.tryParse(_getSensorValue(dashboardState.sensorData, 'soil_moisture_b')) ?? 0.0,
                                hasWater: true,
                                pumpActive: false,
                                duration: 10,
                              ),
                              mode: 'auto',
                              onTogglePump: (plantId, state) {
                                ref.read(dashboardProvider.notifier).togglePump(plantId, state);
                              },
                              onDurationChange: (plantId, duration) {
                                print('Duration $plantId: $duration');
                              },
                              onPlantTypeChange: (plantId, name) {
                                ref.read(dashboardProvider.notifier).updatePlantName(plantId, name);
                              },
                            ),
                            const SizedBox(height: 24),
                            const TanksPanel(
                              tank1Level: 0.75,
                              tank2Level: 0.45,
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 48),

                  // Control Panel
                  Text(
                    'Control de Actuadores',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const ControlPanel(),

                  const SizedBox(height: 48),

                  // Plant Selector
                  PlantSelector(
                    selectedPlants: dashboardState.selectedPlants,
                    maxPlants: 2,
                    onAddPlant: (plant) {
                      // Convert Plant to SelectedPlant
                      final selected = SelectedPlant(
                        id: plant.id.toString(),
                        commonName: plant.commonName,
                        scientificName: plant.scientificName,
                        idealTemperature: plant.idealTemperature,
                        idealMoisture: plant.idealMoisture,
                        idealPH: plant.idealPH,
                        lightType: plant.lightType,
                      );
                      ref.read(dashboardProvider.notifier).addPlant(selected);
                    },
                    onRemovePlant: (plantId) {
                      ref.read(dashboardProvider.notifier).removePlant(plantId);
                    },
                  ),

                  const SizedBox(height: 48),

                  // AI Recommendations
                  AIRecommendations(
                    recommendations: dashboardState.recommendations,
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Footer
          const SliverToBoxAdapter(
            child: AppFooter(),
          ),
        ],
      ),
    );
  }
}
