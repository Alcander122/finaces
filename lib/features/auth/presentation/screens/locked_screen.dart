import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

class LockedScreen extends ConsumerStatefulWidget {
  const LockedScreen({super.key});

  @override
  ConsumerState<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends ConsumerState<LockedScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _biometricsFailed = false;

  @override
  void initState() {
    super.initState();
    // Al cargar la pantalla, intentamos desbloquear automáticamente con huella
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricUnlock() async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(authProvider.notifier).unlockWithBiometrics();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _biometricsFailed = !success;
      });
      
      if (!success) {
        // Opcional: mostrar un SnackBar indicando que falló o se canceló
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autenticación biométrica cancelada o fallida')),
        );
      }
    }
  }

  Future<void> _unlockWithPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).unlockWithPassword(password);
      // Si es exitoso, el provider cambiará el estado y MyApp redibujará el HomeScreen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aplicación Bloqueada',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por tu seguridad, hemos bloqueado la sesión por inactividad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),

                if (_isLoading)
                  const CircularProgressIndicator()
                else if (!_biometricsFailed)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint, size: 32),
                    label: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Desbloquear con Huella / FaceID', style: TextStyle(fontSize: 16)),
                    ),
                    onPressed: _tryBiometricUnlock,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  // Fallback a contraseña
                  Column(
                    children: [
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.password),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _unlockWithPassword,
                          child: const Text('Desbloquear', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Intentar huella de nuevo'),
                        onPressed: () {
                          setState(() => _biometricsFailed = false);
                          _tryBiometricUnlock();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  TextButton(
                    onPressed: () {
                      // Si el usuario quiere cerrar sesión completamente
                      ref.read(authProvider.notifier).signOut();
                    },
                    child: const Text(
                      'Cerrar sesión y salir',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
