import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Get actual connection status from provider
    final isConnected = true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.emerald50 : AppColors.red50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.emerald200 : AppColors.red200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.emerald500 : AppColors.red500,
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? AppColors.emerald600 : AppColors.red600,
            size: 20,
          ),
          
          const SizedBox(width: 8),
          
          Text(
            isConnected ? 'Conectado a Arduino' : 'Arduino Desconectado',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isConnected ? AppColors.emerald600 : AppColors.red600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
