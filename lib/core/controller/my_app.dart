import 'dart:async';
import 'package:finances/core/data/providers/tutorial_provider.dart';
import 'package:finances/presentations/screens/Tutorial/TutorialScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  // ============================================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================================

  // ⏱️ Inactividad (App abierta): 10 min sin tocar la pantalla
  final Duration _inactivityTimeout = const Duration(minutes: 10);

  // 🕒 Segundo Plano (App minimizada): 2 min antes de bloquear
  final Duration _backgroundLockThreshold = const Duration(minutes: 2);

  // Variable para guardar el momento en que se minimiza
  DateTime? _backgroundTimestamp;

  Timer? _inactivityTimer;
  bool _isAppInitialized = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // ============================================================================
  // CICLO DE VIDA
  // ============================================================================

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

  void _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isAppInitialized = true);
      _startInactivityTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando la app se minimiza
    if (state == AppLifecycleState.paused) {
      _backgroundTimestamp = DateTime.now();
      debugPrint('📱 App minimizada: $_backgroundTimestamp');
    }

    // Cuando la app se abre de nuevo
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App reanudada');
      _resetInactivityTimer();
      _checkSessionSecurityOnResume(); // Validar si bloqueamos o no
    }
  }

  // ============================================================================
  // GESTIÓN DE INACTIVIDAD (App Abierta)
  // ============================================================================

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, _handleInactivity);
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _handleInactivity() {
    if (_navigatorKey.currentState != null) {
      debugPrint('🔒 Bloqueo por inactividad (10 min)');
      _navigatorKey.currentState!.pushNamedAndRemoveUntil(
        AppRoutes.welcome,
        (route) => false,
      );
    }
  }

  // ============================================================================
  // SEGURIDAD AL REANUDAR (CORREGIDA)
  // ============================================================================

  Future<void> _checkSessionSecurityOnResume() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) return;

    // 🔥 CORRECCIÓN AQUÍ:
    // Si el timestamp es nulo, significa que la app acaba de arrancar de cero
    // o no pasó por un estado de 'paused' real. NO bloqueamos.
    if (_backgroundTimestamp == null) {
      debugPrint('ℹ️ No hay registro de pausa previa. Se mantiene en Home.');
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(_backgroundTimestamp!);
    debugPrint('⏱️ Tiempo fuera: ${difference.inSeconds} segundos');

    // 1. Si el tiempo fuera es MENOR a 2 minutos, NO bloqueamos
    if (difference < _backgroundLockThreshold) {
      debugPrint('✅ Regreso rápido (Menos de 2 min): Sin bloqueo.');
      _backgroundTimestamp = null; // Limpiar para el siguiente ciclo
      return;
    }

    // 2. Si pasaron los 2 minutos, verificamos biometría y primer login
    final uid = authState.user!.uid;
    final biometricEnabled = await BiometricAuthService().isBiometricEnabled();
    final isFirstLogin = await _isFirstLogin(uid);

    // Solo bloqueamos si TIENE huella activa y NO es su primer inicio
    if (!isFirstLogin && biometricEnabled) {
      debugPrint(
          '🔐 Bloqueando: Se excedieron los 2 min y la biometría está activa.');
      _goToBlockedScreen();
    }

    // Limpiar siempre al terminar
    _backgroundTimestamp = null;
  }

  Future<bool> _isFirstLogin(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists && (doc.data()?['firstLogin'] == true);
    } catch (e) {
      return false;
    }
  }

  void _goToBlockedScreen() {
    if (!mounted) return;
    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.appBlocked,
        (route) => false,
      );
    }
  }

  // ============================================================================
  // CONSTRUCCIÓN UI
  // ============================================================================

  Widget _buildNormalApp(AuthState authState) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'CO'), // Español de Colombia
          Locale('es', ''),   // Español genérico
          Locale('en', ''),   // Inglés
        ],
        home: const SplashScreen(),
        routes: AppRoutes.getRoutes(authState),
        navigatorKey: _navigatorKey,
        builder: (context, child) => child!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de autenticación para redirigir si se cierra la sesión
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous != null && previous.isAuthenticated && !next.isAuthenticated) {
        if (_navigatorKey.currentState != null) {
          _navigatorKey.currentState!.pushNamedAndRemoveUntil(
            AppRoutes.welcome,
            (route) => false,
          );
        }
      }
    });

    final authState = ref.watch(authProvider);
    final hasSeenTutorial = ref.watch(tutorialProvider);

    if (!_isAppInitialized) {
      return _buildLoadingScreen();
    }

    return hasSeenTutorial.when(
      data: (hasSeen) {
        if (authState.isAuthenticated && !hasSeen) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'CO'), // Español de Colombia
              Locale('es', ''),   // Español genérico
              Locale('en', ''),   // Inglés
            ],
            home: const TutorialScreen(),
            routes: AppRoutes.getRoutes(authState),
            navigatorKey: _navigatorKey,
          );
        }
        return _buildNormalApp(authState);
      },
      loading: () => _buildLoadingScreen('Cargando...'),
      error: (error, _) => _buildNormalApp(authState),
    );
  }

  Widget _buildLoadingScreen([String message = 'Inicializando...']) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'), // Español de Colombia
        Locale('es', ''),   // Español genérico
        Locale('en', ''),   // Inglés
      ],
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
