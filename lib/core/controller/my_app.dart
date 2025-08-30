import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/presentations/screens/splash_screen.dart'; // Importar el SplashScreen

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

  /// Inicialización controlada de la aplicación
  void _initializeApp() async {
    try {
      // Pequeña pausa para asegurar que todo esté listo
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isAppInitialized = true;
      });

      _startInactivityTimer();
    } catch (e) {
      debugPrint('Error en inicialización: $e');
      setState(() {
        _isAppInitialized = true; // Aún así marcamos como inicializado
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _resetInactivityTimer();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(), // Usar SplashScreen como pantalla inicial
        routes: AppRoutes.getRoutes(authState),
        // Evitar rebuilds innecesarios
        builder: (context, child) {
          return child!;
        },
      ),
    );
  }
}
