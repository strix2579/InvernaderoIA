import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/repositories/greenhouse_repository.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/sensor_chart.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();
  String _selectedSensorType = 'all';
  
  List<SensorData> _temperatureData = [];
  List<SensorData> _humidityData = [];
  List<SensorData> _lightData = [];
  List<SensorData> _soilData = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(greenhouseRepositoryProvider);
      final data = await repository.getHistoricalData(
        startDate: _startDate,
        endDate: _endDate,
        sensorType: _selectedSensorType == 'all' ? null : _selectedSensorType,
      );

      setState(() {
        _temperatureData = data.where((s) => s.type == 'temperature').toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _humidityData = data.where((s) => s.type == 'humidity').toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _lightData = data.where((s) => s.type == 'light').toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _soilData = data.where((s) => s.type == 'soil_moisture').toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSensorType,
                        decoration: const InputDecoration(
                          labelText: 'Sensor',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(value: 'temperature', child: Text('Temperatura')),
                          DropdownMenuItem(value: 'humidity', child: Text('Humedad')),
                          DropdownMenuItem(value: 'light', child: Text('Luz')),
                          DropdownMenuItem(value: 'soil_moisture', child: Text('Humedad Suelo')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSensorType = value;
                            });
                            _fetchData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Charts
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_selectedSensorType == 'all' || _selectedSensorType == 'temperature')
                          SensorChart(
                            data: _temperatureData,
                            title: 'Temperatura',
                            color: AppTheme.temperatureColor,
                            unit: '°C',
                          ),
                        
                        if (_selectedSensorType == 'all' || _selectedSensorType == 'humidity')
                          SensorChart(
                            data: _humidityData,
                            title: 'Humedad',
                            color: AppTheme.humidityColor,
                            unit: '%',
                          ),
                        
                        if (_selectedSensorType == 'all' || _selectedSensorType == 'light')
                          SensorChart(
                            data: _lightData,
                            title: 'Luz',
                            color: AppTheme.lightColor,
                            unit: 'lux',
                          ),
                        
                        if (_selectedSensorType == 'all' || _selectedSensorType == 'soil_moisture')
                          SensorChart(
                            data: _soilData,
                            title: 'Humedad del Suelo',
                            color: AppTheme.soilMoistureColor,
                            unit: '%',
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
