import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/control_command.dart';
import '../../domain/repositories/greenhouse_repository.dart';
import '../providers/providers.dart';

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({super.key});

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  bool _waterPumpOn = false;
  bool _fanOn = false;
  bool _lightsOn = false;
  double _fanSpeed = 50.0;
  double _valvePosition = 0.0;

  Future<void> _sendCommand(ControlCommand command) async {
    try {
      final repository = ref.read(greenhouseRepositoryProvider);
      await repository.sendControlCommand(command);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comando enviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Manual'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispositivos',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Water Pump
            _ControlCard(
              title: 'Bomba de Agua',
              icon: Icons.water_drop,
              color: Colors.blue,
              child: SwitchListTile(
                title: Text(_waterPumpOn ? 'Encendida' : 'Apagada'),
                value: _waterPumpOn,
                onChanged: (value) {
                  setState(() {
                    _waterPumpOn = value;
                  });
                  _sendCommand(
                    ControlCommand(
                      deviceId: 'water_pump',
                      action: value ? 'turn_on' : 'turn_off',
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fan with Speed Control
            _ControlCard(
              title: 'Ventilador',
              icon: Icons.air,
              color: Colors.teal,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(_fanOn ? 'Encendido' : 'Apagado'),
                    value: _fanOn,
                    onChanged: (value) {
                      setState(() {
                        _fanOn = value;
                      });
                      _sendCommand(
                        ControlCommand(
                          deviceId: 'fan',
                          action: value ? 'turn_on' : 'turn_off',
                          value: _fanSpeed,
                        ),
                      );
                    },
                  ),
                  if (_fanOn) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Velocidad: ${_fanSpeed.toInt()}%',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Slider(
                            value: _fanSpeed,
                            min: 0,
                            max: 100,
                            divisions: 10,
                            label: '${_fanSpeed.toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _fanSpeed = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _sendCommand(
                                ControlCommand(
                                  deviceId: 'fan',
                                  action: 'set_value',
                                  value: value,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lights
            _ControlCard(
              title: 'Luces',
              icon: Icons.lightbulb,
              color: Colors.amber,
              child: SwitchListTile(
                title: Text(_lightsOn ? 'Encendidas' : 'Apagadas'),
                value: _lightsOn,
                onChanged: (value) {
                  setState(() {
                    _lightsOn = value;
                  });
                  _sendCommand(
                    ControlCommand(
                      deviceId: 'lights',
                      action: value ? 'turn_on' : 'turn_off',
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Valve Position
            _ControlCard(
              title: 'Válvula de Riego',
              icon: Icons.tune,
              color: Colors.green,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posición: ${_valvePosition.toInt()}%',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _valvePosition,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: '${_valvePosition.toInt()}%',
                      onChanged: (value) {
                        setState(() {
                          _valvePosition = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _sendCommand(
                          ControlCommand(
                            deviceId: 'valve',
                            action: 'set_value',
                            value: value,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _ControlCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
