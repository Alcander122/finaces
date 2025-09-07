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
  Timer? _inactivityTimer;
  final Duration _timeoutDuration = const Duration(minutes: 15);
  bool _isAppInitialized = false;

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
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isAppInitialized = true;
      });
      _startInactivityTimer();
    } catch (e) {
      debugPrint('Error en inicialización: $e');
      setState(() {
        _isAppInitialized = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, _handleInactivity);
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _handleInactivity() {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.signOut();
  }

  Widget _buildNormalApp(AuthState authState) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _resetInactivityTimer();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
        routes: AppRoutes.getRoutes(authState),
        builder: (context, child) {
          return child!;
        },
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
        // ✅ VERIFICACIÓN: Imprime el estado actual del tutorial y autenticación
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
