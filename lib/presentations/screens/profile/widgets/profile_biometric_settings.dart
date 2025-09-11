// profile_biometric_settings.dart
import 'package:flutter/material.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/presentations/theme/themes.dart';

/// Configuración de biometría (switch) - Ahora StatefulWidget
class ProfileBiometricSettings extends StatefulWidget {
  const ProfileBiometricSettings({super.key});

  @override
  State<ProfileBiometricSettings> createState() =>
      _ProfileBiometricSettingsState();
}

class _ProfileBiometricSettingsState extends State<ProfileBiometricSettings> {
  bool? _isBiometricAvailable;
  bool? _isBiometricEnabled;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    try {
      final isAvailable = await BiometricAuthService().isBiometricAvailable();
      bool isEnabled = false;

      if (isAvailable) {
        isEnabled = await BiometricAuthService().isBiometricEnabled();
      }

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBiometricAvailable = false;
        });
      }
    }
  }

  Future<void> _onBiometricChanged(bool value) async {
    try {
      await BiometricAuthService().setBiometricEnabled(value);

      // Actualizar el estado local inmediatamente después del cambio
      final isEnabled = await BiometricAuthService().isBiometricEnabled();

      if (mounted) {
        setState(() {
          _isBiometricEnabled = isEnabled;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ Autenticación biométrica activada'
                  : '❌ Autenticación biométrica desactivada',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Error al cambiar la configuración')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        title: Text('Autenticación Biométrica'),
        subtitle: Text('Verificando disponibilidad...'),
        trailing: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_isBiometricAvailable == false) {
      return const ListTile(
        title: Text('Autenticación Biométrica'),
        subtitle: Text('No disponible en este dispositivo'),
        trailing: Icon(Icons.block, color: Colors.grey),
      );
    }

    return SwitchListTile(
      title: const Text('Iniciar sesión con huella'),
      subtitle: const Text('Protege tu app con tu biometría'),
      value: _isBiometricEnabled ?? false,
      onChanged: _onBiometricChanged,
      activeThumbColor: Themes.primary,
      secondary: const Icon(Icons.fingerprint),
    );
  }
}
