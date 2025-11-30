import 'package:flutter/material.dart';
import '../../domain/repositories/greenhouse_repository.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        text = 'Conectado';
        icon = Icons.check_circle;
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        text = 'Conectando...';
        icon = Icons.sync;
        break;
      case ConnectionStatus.disconnected:
        color = Colors.grey;
        text = 'Desconectado';
        icon = Icons.cloud_off;
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        text = 'Error';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
