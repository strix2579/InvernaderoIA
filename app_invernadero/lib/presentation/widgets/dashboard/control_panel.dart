import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../providers/dashboard_provider.dart';

class ControlPanel extends ConsumerStatefulWidget {
  const ControlPanel({super.key});

  @override
  ConsumerState<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends ConsumerState<ControlPanel> {
  // Estado local optimista (hasta que tengamos feedback real del hardware)
  bool _fansActive = false;
  bool _extractorsActive = false;
  bool _lightsActive = false;

  void _toggleActuator(String id) {
    setState(() {
      if (id == 'fan') _fansActive = !_fansActive;
      if (id == 'extractors') _extractorsActive = !_extractorsActive;
      if (id == 'lights') _lightsActive = !_lightsActive;
    });

    final isActive = id == 'fan' ? _fansActive : (id == 'extractors' ? _extractorsActive : _lightsActive);
    ref.read(dashboardProvider.notifier).toggleActuator(id, isActive);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple500.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control de Actuadores',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sistema en línea',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Actuator Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final crossAxisCount = isDesktop ? 3 : 2;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  ActuatorButton(
                    label: 'Ventiladores',
                    sublabel: '3x',
                    icon: Icons.air,
                    isActive: _fansActive,
                    gradient: AppColors.cyanGradient,
                    onTap: () => _toggleActuator('fan'),
                  ),
                  ActuatorButton(
                    label: 'Extractores',
                    sublabel: '3x',
                    icon: Icons.wind_power,
                    isActive: _extractorsActive,
                    gradient: AppColors.blueGradient,
                    onTap: () => _toggleActuator('extractors'),
                  ),
                  ActuatorButton(
                    label: 'LEDs UVA',
                    sublabel: '12x',
                    icon: Icons.lightbulb,
                    isActive: _lightsActive,
                    gradient: AppColors.purpleGradient,
                    onTap: () => _toggleActuator('lights'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ActuatorButton extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isActive;
  final Gradient gradient;
  final VoidCallback onTap;

  const ActuatorButton({
    super.key,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isActive,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<ActuatorButton> createState() => _ActuatorButtonState();
}

class _ActuatorButtonState extends State<ActuatorButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            0,
            _isPressed ? 2 : (_isHovered ? -4 : 0),
            0,
          ),
          decoration: BoxDecoration(
            gradient: widget.isActive ? widget.gradient : null,
            color: widget.isActive ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isActive 
                  ? Colors.transparent 
                  : (_isHovered ? Colors.grey.shade300 : Colors.grey.shade200),
              width: 1.5,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(_isHovered ? 0.4 : 0.3),
                      blurRadius: _isHovered ? 25 : 20,
                      offset: Offset(0, _isHovered ? 12 : 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? Colors.white.withOpacity(0.25)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isActive ? Colors.white : AppColors.gray600,
                    size: 32,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Label
                Text(
                  widget.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: widget.isActive ? Colors.white : AppColors.gray800,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 4),
                
                // Sublabel
                Text(
                  widget.sublabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: widget.isActive 
                        ? Colors.white.withOpacity(0.8) 
                        : AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.isActive ? Colors.white : AppColors.gray400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isActive ? 'ENCENDIDO' : 'APAGADO',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.isActive ? Colors.white : AppColors.gray500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
