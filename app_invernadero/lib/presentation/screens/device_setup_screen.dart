import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/entities/iot_device.dart';
import '../../data/services/device_config_service.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final DeviceConfigService _configService = DeviceConfigService();
  final TextEditingController _passwordController = TextEditingController();

  SetupStep _currentStep = SetupStep.connecting;
  IoTDevice? _device;
  List<WiFiNetwork> _networks = [];
  WiFiNetwork? _selectedNetwork;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connectToDevice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Intentar conectar al AP del dispositivo
      final device = await _configService.getDeviceStatus(
        DeviceConfigService.defaultAPIP,
      );

      setState(() {
        _device = device;
        _currentStep = SetupStep.scanningNetworks;
      });

      // Obtener redes disponibles
      await _scanNetworks();
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo conectar al dispositivo.\n'
            'Asegúrate de estar conectado a la red WiFi del dispositivo (GreenTech-XXXX)';
        _currentStep = SetupStep.error;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanNetworks() async {
    setState(() => _isLoading = true);

    try {
      final networks = await _configService.getAvailableNetworks(
        DeviceConfigService.defaultAPIP,
      );

      setState(() {
        _networks = networks;
        _currentStep = SetupStep.selectingNetwork;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al escanear redes WiFi: $e';
        _currentStep = SetupStep.error;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _configureDevice() async {
    if (_selectedNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una red WiFi')),
      );
      return;
    }

    if (_passwordController.text.isEmpty && !_selectedNetwork!.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la contraseña de la red')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _currentStep = SetupStep.configuring;
    });

    try {
      final config = DeviceConfiguration(
        wifiSSID: _selectedNetwork!.ssid,
        wifiPassword: _passwordController.text,
        userToken: null, // TODO: Obtener del auth provider si existe sesión
      );

      final success = await _configService.configureDevice(
        DeviceConfigService.defaultAPIP,
        config,
      );

      if (success) {
        setState(() => _currentStep = SetupStep.success);

        // Esperar a que el dispositivo se reinicie
        await Future.delayed(const Duration(seconds: 3));

        // Navegar de vuelta o a la siguiente pantalla
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('La configuración falló');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al configurar: $e';
        _currentStep = SetupStep.error;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Configurar Dispositivo'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case SetupStep.connecting:
        return _buildConnectingView();
      case SetupStep.scanningNetworks:
        return _buildScanningView();
      case SetupStep.selectingNetwork:
        return _buildNetworkSelectionView();
      case SetupStep.configuring:
        return _buildConfiguringView();
      case SetupStep.success:
        return _buildSuccessView();
      case SetupStep.error:
        return _buildErrorView();
    }
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.wifi_find,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Conectando al dispositivo...',
            style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Asegúrate de estar conectado a la red WiFi del dispositivo (GreenTech-XXXX)',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Escaneando redes WiFi...',
            style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.devices, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispositivo Encontrado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_device?.deviceId ?? 'Unknown'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Selecciona tu red WiFi',
            style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
          ),

          const SizedBox(height: 16),

          // Networks List
          ...(_networks.map((network) => _buildNetworkCard(network))),

          const SizedBox(height: 24),

          // Password Field (if network selected and not open)
          if (_selectedNetwork != null && !_selectedNetwork!.isOpen) ...[
            Text(
              'Contraseña de la red',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.gray700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Ingresa la contraseña',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Configure Button
          if (_selectedNetwork != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _configureDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Configurar Dispositivo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(WiFiNetwork network) {
    final isSelected = _selectedNetwork?.ssid == network.ssid;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNetwork = network;
          if (network.isOpen) {
            _passwordController.clear();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              network.isOpen ? Icons.wifi : Icons.wifi_lock,
              color: isSelected ? AppColors.primary : AppColors.gray600,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.ssid,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    network.isOpen ? 'Red abierta' : 'Red protegida',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            _buildSignalStrengthIcon(network.signalStrength),
            if (isSelected) ...[
              const SizedBox(width: 12),
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignalStrengthIcon(int rssi) {
    return Icon(
      Icons.network_wifi,
      color: rssi > -70 ? Colors.green : rssi > -80 ? Colors.orange : Colors.red,
      size: 20,
    );
  }

  Widget _buildConfiguringView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Configurando dispositivo...',
            style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'El dispositivo se reiniciará y se conectará a tu red WiFi',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '¡Configuración Exitosa!',
            style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'El dispositivo se ha configurado correctamente y está conectándose a tu red WiFi',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Error de Configuración',
              style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = SetupStep.connecting;
                  _errorMessage = '';
                });
                _connectToDevice();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

enum SetupStep {
  connecting,
  scanningNetworks,
  selectingNetwork,
  configuring,
  success,
  error,
}
