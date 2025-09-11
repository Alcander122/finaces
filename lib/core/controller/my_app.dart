import 'dart:async';
import 'package:finances/core/data/providers/tutorial_provider.dart';
import 'package:finances/presentations/screens/Tutorial/TutorialScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/presentations/screens/splash_screen.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // Temporizador para manejar la inactividad del usuario
  Timer? _inactivityTimer;

  // Duración máxima de inactividad permitida (15 minutos)
  final Duration _timeoutDuration = const Duration(minutes: 15);

  // Estado de inicialización de la aplicación
  bool _isAppInitialized = false;

  // Clave global para controlar la navegación desde cualquier parte de la app
  // Esto nos permite navegar sin necesidad de context
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Registrar este widget como observador del ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    // Limpiar recursos al destruir el widget
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  /// Inicializa la aplicación después de un breve retraso
  void _initializeApp() async {
    try {
      // Esperar 500ms para simular procesos de inicialización
      await Future.delayed(const Duration(milliseconds: 500));

      // Marcar la app como inicializada y comenzar el temporizador de inactividad
      setState(() {
        _isAppInitialized = true;
      });

      _startInactivityTimer();
    } catch (e) {
      debugPrint('Error en inicialización: $e');
      // Asegurar que la app se muestre incluso si hay errores
      setState(() {
        _isAppInitialized = true;
      });
    }
  }

  /// Maneja cambios en el ciclo de vida de la aplicación
  /// (Ej.: cuando la app pasa a segundo plano y regresa)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando la app regresa al primer plano, reiniciar el temporizador
    if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }

  /// Inicia o reinicia el temporizador de inactividad
  void _startInactivityTimer() {
    // Cancelar cualquier temporizador existente
    _inactivityTimer?.cancel();

    // Crear un nuevo temporizador que llamará a _handleInactivity después del tiempo límite
    _inactivityTimer = Timer(_timeoutDuration, _handleInactivity);
  }

  /// Reinicia el temporizador de inactividad
  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  /// Maneja la inactividad del usuario
  /// En lugar de cerrar sesión, redirige al usuario a la pantalla de bienvenida
  void _handleInactivity() {
    // Verificación de seguridad: asegurar que el navigatorKey esté disponible
    if (_navigatorKey.currentState != null) {
      debugPrint(
          '>>> [Inactividad] Redirigiendo al usuario a la pantalla de bienvenida');

      // Redirigir al usuario a la pantalla de bienvenida y limpiar el stack de navegación
      // Esto asegura que el usuario no pueda regresar a las pantallas anteriores
      _navigatorKey.currentState!.pushNamedAndRemoveUntil(
        AppRoutes.welcome,
        (route) => false, // Elimina todas las rutas anteriores
      );
    }
  }

  /// Construye la aplicación normal (después de la inicialización)
  /// Envuelve la app con un Listener para detectar interacciones del usuario
  Widget _buildNormalApp(AuthState authState) {
    return Listener(
      // Configurar para detectar cualquier toque en la pantalla
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        // Cualquier interacción del usuario reinicia el temporizador
        _resetInactivityTimer();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
        routes: AppRoutes.getRoutes(authState),
        builder: (context, child) {
          return child!;
        },
        // Configurar la clave global para controlar la navegación
        navigatorKey: _navigatorKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasSeenTutorial = ref.watch(tutorialProvider);

    // Si la app no está inicializada, mostrar splash screen
    if (!_isAppInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Inicializando aplicación...'),
              ],
            ),
          ),
        ),
      );
    }

    // Manejo SEGURO del estado del tutorial con .when()
    return hasSeenTutorial.when(
      data: (hasSeen) {
        // Imprimir estado para depuración
        debugPrint(
            '>>> [MyApp.build] Usuario autenticado: ${authState.isAuthenticated}');
        debugPrint('>>> [MyApp.build] ¿Ya vio el tutorial?: $hasSeen');

        // Si está autenticado y NO ha visto el tutorial → mostrar TutorialScreen
        if (authState.isAuthenticated && !hasSeen) {
          debugPrint('>>> [MyApp.build] MOSTRANDO TUTORIAL POR PRIMERA VEZ');
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const TutorialScreen(),
            routes: AppRoutes.getRoutes(authState),
            navigatorKey:
                _navigatorKey, // Asegurar que el tutorial también use el mismo navigatorKey
          );
        }

        debugPrint('>>> [MyApp.build] MOSTRANDO APP NORMAL');
        return _buildNormalApp(authState);
      },
      loading: () {
        debugPrint('>>> [MyApp.build] Cargando estado del tutorial...');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Cargando tutorial...'),
                ],
              ),
            ),
          ),
          routes: AppRoutes.getRoutes(authState),
          navigatorKey:
              _navigatorKey, // Asegurar que el loading también use el mismo navigatorKey
        );
      },
      error: (error, stackTrace) {
        debugPrint(
            '>>> [MyApp.build] Error cargando estado del tutorial: $error');
        return _buildNormalApp(authState);
      },
    );
  }
}
