// my_app.dart
import 'dart:async';
import 'package:finances/core/data/providers/tutorial_provider.dart';
import 'package:finances/presentations/screens/Tutorial/TutorialScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/core/data/services/BiometricAuthService.dart';
import 'package:finances/presentations/screens/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // Temporizador de inactividad
  Timer? _inactivityTimer;
  final Duration _timeoutDuration = const Duration(minutes: 15);

  // Estado de inicialización
  bool _isAppInitialized = false;

  // Navegación global
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  /// Inicializa la app
  void _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isAppInitialized = true);
    _startInactivityTimer();
  }

  /// === CICLO DE VIDA ===
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
      _checkSessionSecurityOnResume(); // NUEVO: Bloqueo al reanudar
    }
  }

  /// === INACTIVIDAD ===
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, _handleInactivity);
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _handleInactivity() {
    if (_navigatorKey.currentState != null) {
      debugPrint('Inactividad: Redirigiendo a welcome');
      _navigatorKey.currentState!.pushNamedAndRemoveUntil(
        AppRoutes.welcome,
        (route) => false,
      );
    }
  }

  /// === SEGURIDAD AL REANUDAR APP ===
  Future<void> _checkSessionSecurityOnResume() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) return;

    final uid = authState.user!.uid;
    final biometricEnabled = await BiometricAuthService().isBiometricEnabled();
    final isFirstLogin = await _isFirstLogin(uid);

    // Si NO es primer login y NO tiene biometría → BLOQUEAR
    if (!isFirstLogin && !biometricEnabled) {
      debugPrint('Seguridad: Bloqueando app al reanudar (sin biometría)');
      _goToBlockedScreen();
    }
  }

  Future<bool> _isFirstLogin(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists && (doc.data()?['firstLogin'] == true);
    } catch (e) {
      debugPrint('Error verificando firstLogin: $e');
      return false;
    }
  }

  void _goToBlockedScreen() {
    if (!mounted) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    // Limpiar stack y ir directo a bloqueo
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.appBlocked,
      (route) => false,
    );
  }

  /// === APP NORMAL ===
  Widget _buildNormalApp(AuthState authState) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(), // Solo visual
        routes: AppRoutes.getRoutes(authState),
        navigatorKey: _navigatorKey,
        builder: (context, child) => child!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasSeenTutorial = ref.watch(tutorialProvider);

    if (!_isAppInitialized) {
      return _buildLoadingScreen();
    }

    return hasSeenTutorial.when(
      data: (hasSeen) {
        debugPrint(
            'MyApp.build → Auth: ${authState.isAuthenticated}, Tutorial: $hasSeen');

        // Tutorial por primera vez
        if (authState.isAuthenticated && !hasSeen) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const TutorialScreen(),
            routes: AppRoutes.getRoutes(authState),
            navigatorKey: _navigatorKey,
          );
        }

        // App normal
        return _buildNormalApp(authState);
      },
      loading: () => _buildLoadingScreen('Cargando tutorial...'),
      error: (error, _) {
        debugPrint('Error tutorial: $error');
        return _buildNormalApp(authState);
      },
    );
  }

  Widget _buildLoadingScreen([String message = 'Inicializando aplicación...']) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}
