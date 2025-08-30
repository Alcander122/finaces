// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Estados para el SplashScreen
enum SplashScreenStatus {
  initializing, // Inicializando componentes
  checkingAuth, // Verificando estado de autenticación
  authenticated, // Usuario autenticado
  unauthenticated, // Usuario no autenticado
  error // Error en el proceso
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

    // Configurar animación de preloader
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Iniciar el proceso de verificación
    _checkAppStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Función principal que verifica el estado de la aplicación
  Future<void> _checkAppStatus() async {
    try {
      // Verificar si se excedió el número máximo de reintentos
      if (_retryCount >= _maxRetries) {
        _showFinalError();
        return;
      }

      // Fase 1: Inicialización
      setState(() {
        _status = SplashScreenStatus.initializing;
        _statusMessage = 'Configurando servicios...';
      });

      // Pequeña pausa para permitir que la UI se actualice
      await Future.delayed(const Duration(milliseconds: 300));

      // Fase 2: Verificación de autenticación
      setState(() {
        _status = SplashScreenStatus.checkingAuth;
        _statusMessage = 'Verificando sesión...';
      });

      // Obtener el estado actual de autenticación
      final authState = ref.read(authProvider);

      // Si está cargando, esperar con timeout para evitar bloqueos
      if (authState.isLoading) {
        await Future.delayed(const Duration(seconds: 2))
            .timeout(const Duration(seconds: 5));
      }

      // Obtener el estado actualizado después de la espera
      final updatedAuthState = ref.read(authProvider);

      // Redirigir según el estado de autenticación
      if (updatedAuthState.isAuthenticated) {
        _handleAuthenticated();
      } else {
        _handleUnauthenticated();
      }
    } catch (e) {
      // Manejar cualquier error durante el proceso
      _handleError(e);
    }
  }

  /// Maneja el estado de usuario autenticado
  void _handleAuthenticated() async {
    setState(() {
      _status = SplashScreenStatus.authenticated;
      _statusMessage = '¡Bienvenido de vuelta!';
    });

    // Pequeña pausa para mostrar el mensaje de bienvenida
    await Future.delayed(const Duration(milliseconds: 800));
    _navigateToHome();
  }

  /// Maneja el estado de usuario no autenticado
  void _handleUnauthenticated() async {
    setState(() {
      _status = SplashScreenStatus.unauthenticated;
      _statusMessage = 'Listo para iniciar sesión';
    });

    // Pequeña pausa antes de redirigir al login
    await Future.delayed(const Duration(milliseconds: 800));
    _navigateToLogin();
  }

  /// Maneja errores durante el proceso de verificación
  void _handleError(dynamic e) async {
    // Registrar el error con el número de intento
    logger.e(
        'Error en SplashScreen (intento ${_retryCount + 1}/$_maxRetries): $e');

    setState(() {
      _status = SplashScreenStatus.error;
      _statusMessage = 'Error al iniciar. Reintentando...';
    });

    // Incrementar contador de reintentos
    _retryCount++;

    // Esperar antes de reintentar (con aumento progresivo del tiempo)
    await Future.delayed(Duration(seconds: 1 + _retryCount));

    // Reintentar solo si el widget todavía está montado
    if (mounted) {
      _checkAppStatus();
    }
  }

  /// Muestra mensaje de error final después de múltiples intentos fallidos
  void _showFinalError() {
    setState(() {
      _statusMessage = 'Error crítico. Por favor, reinicie la aplicación.';
    });
  }

  /// Navega a la pantalla principal
  void _navigateToHome() {
    if (mounted && !_isInitialized) {
      _isInitialized = true;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  /// Navega a la pantalla de login
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
              // Logo con animación de pulsación
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
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

              // Indicador de progreso
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

              // Mensaje de estado
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

              // Contador de reintentos (solo para estado de error)
              if (_status == SplashScreenStatus.error && _retryCount > 0)
                Text(
                  'Reintento $_retryCount de $_maxRetries',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

              const SizedBox(height: 20),

              // Botón de reintento manual para errores
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
