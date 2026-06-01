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
        title: Text('Autenticación Biométrica', style: TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text('Verificando disponibilidad...', style: TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
        ),
      );
    }

    if (_isBiometricAvailable == false) {
      return const ListTile(
        title: Text('Autenticación Biométrica', style: TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text('No disponible en este dispositivo', style: TextStyle(color: Colors.white30, fontSize: 12)),
        trailing: Icon(Icons.block, color: Colors.white24),
      );
    }

    return SwitchListTile(
      title: const Text('Iniciar sesión con huella', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: const Text('Protege tu app con tu biometría', style: TextStyle(color: Colors.white60, fontSize: 12)),
      value: _isBiometricEnabled ?? false,
      onChanged: _onBiometricChanged,
      activeColor: const Color(0xFF26A69A), // Esmeralda para activo
      activeTrackColor: const Color(0xFF26A69A).withValues(alpha: 0.3),
      inactiveThumbColor: Colors.white70,
      inactiveTrackColor: Colors.white10,
      secondary: const Icon(Icons.fingerprint, color: Color(0xFF64B5F6), size: 24), // Azul para icono
    );
  }
}
