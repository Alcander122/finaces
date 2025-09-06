// splash_screen.dart
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:logger/logger.dart';

final logger = Logger();

enum SplashScreenStatus {
  initializing,
  checkingAuth,
  authenticated,
  unauthenticated,
  error
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  SplashScreenStatus _status = SplashScreenStatus.initializing;
  String _statusMessage = 'Iniciando aplicación...';
  bool _isInitialized = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _checkAppStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAppStatus() async {
    try {
      if (_retryCount >= _maxRetries) {
        _showFinalError();
        return;
      }

      setState(() {
        _status = SplashScreenStatus.initializing;
        _statusMessage = 'Configurando servicios...';
      });

      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _status = SplashScreenStatus.checkingAuth;
        _statusMessage = 'Verificando sesión...';
      });

      final authState = ref.read(authProvider);

      if (authState.isLoading) {
        await Future.delayed(const Duration(seconds: 2))
            .timeout(const Duration(seconds: 5));
      }

      final updatedAuthState = ref.read(authProvider);

      if (updatedAuthState.isAuthenticated) {
        await _handleAuthenticated();
      } else {
        _handleUnauthenticated();
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _handleAuthenticated() async {
    setState(() {
      _status = SplashScreenStatus.authenticated;
      _statusMessage = 'Verificando identidad...';
    });

    try {
      final biometricService = BiometricAuthService();
      final isBiometricEnabled = await biometricService.isBiometricEnabled();
      final isBiometricAvailable =
          await biometricService.isBiometricAvailable();

      logger.d(
          'Biometría - Habilitada: $isBiometricEnabled, Disponible: $isBiometricAvailable');

      // Solo proceder con biometría si está disponible y habilitada
      if (isBiometricEnabled && isBiometricAvailable) {
        try {
          final authenticated = await biometricService.authenticate();

          if (!authenticated) {
            logger
                .d('Autenticación biométrica fallida o cancelada por usuario');
            // En lugar de cerrar sesión, permitimos el acceso normal
            // ya que el usuario podría haber cancelado la autenticación
            await Future.delayed(const Duration(milliseconds: 800));
            _navigateToHome();
            return;
          }

          logger.d('Autenticación biométrica exitosa');
          await Future.delayed(const Duration(milliseconds: 800));
          _navigateToHome();
        } on PlatformException catch (e) {
          if (e.code == 'no_fragment_activity') {
            logger.e('ERROR: Configuración de actividad incorrecta');
            // Mostrar mensaje de error temporal
            setState(() {
              _statusMessage = 'Error de configuración, continuando...';
            });
            await Future.delayed(const Duration(seconds: 2));
            // Continuar sin biometría
            _navigateToHome();
          } else {
            // Otros errores de plataforma
            logger.e(
                'Error de plataforma en autenticación biométrica: ${e.message}');
            _navigateToHome();
          }
        } catch (e) {
          logger.e('Error inesperado en autenticación biométrica: $e');
          _navigateToHome();
        }
      } else {
        // Biometría no configurada - proceder normalmente
        logger.d('Biometría no configurada - procediendo directamente');
        await Future.delayed(const Duration(milliseconds: 800));
        _navigateToHome();
      }
    } catch (e) {
      logger.e('Error verificando estado de biometría: $e');
      // En caso de error, proceder al home por seguridad
      _navigateToHome();
    }
  }

  void _handleUnauthenticated() async {
    setState(() {
      _status = SplashScreenStatus.unauthenticated;
      _statusMessage = 'Redirigiendo al login...';
    });
    await Future.delayed(const Duration(milliseconds: 800));
    _navigateToLogin();
  }

  void _handleError(dynamic e) async {
    logger.e(
        'Error en SplashScreen (intento ${_retryCount + 1}/$_maxRetries): $e');
    setState(() {
      _status = SplashScreenStatus.error;
      _statusMessage = 'Error al iniciar. Reintentando...';
    });
    _retryCount++;
    await Future.delayed(Duration(seconds: 1 + _retryCount));
    if (mounted) _checkAppStatus();
  }

  void _showFinalError() {
    setState(() {
      _statusMessage = 'Error crítico. Por favor, reinicie la aplicación.';
    });
  }

  void _navigateToHome() {
    if (mounted && !_isInitialized) {
      _isInitialized = true;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _navigateToLogin() {
    if (mounted && !_isInitialized) {
      _isInitialized = true;
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2B63), Color(0xFF3674B5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logobill.png',
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _status == SplashScreenStatus.error
                          ? Colors.red
                          : Colors.white),
                  strokeWidth: 4.0,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              if (_status == SplashScreenStatus.error && _retryCount > 0)
                Text(
                  'Reintento $_retryCount de $_maxRetries',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 20),
              if (_status == SplashScreenStatus.error)
                TextButton(
                  onPressed: _checkAppStatus,
                  child: const Text(
                    'Reintentar ahora',
                    style: TextStyle(color: Colors.white),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
