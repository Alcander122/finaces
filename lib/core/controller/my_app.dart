import 'dart:async';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/tutorial_provider.dart';
import 'package:finances/features/auth/presentation/screens/locked_screen.dart';
import 'package:finances/presentations/screens/Auth/welcome_screen.dart';
import 'package:finances/presentations/screens/Tutorial/TutorialScreen.dart';
import 'package:finances/presentations/screens/home/home_screen.dart';
import 'package:finances/presentations/screens/splash_screen.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:finances/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final Duration _timeout = const Duration(minutes: 5);
  Timer? _timer;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authNotifier = ref.read(authProvider.notifier);

    // 📱 APP EN BACKGROUND
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
      debugPrint("📱 App en background");
    }

    // 🚀 APP REANUDADA
    if (state == AppLifecycleState.resumed) {
      debugPrint("🚀 App resumida");

      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        debugPrint("⏱️ Tiempo fuera: ${diff.inSeconds} seg");

        // Validar tiempo fuera de la app
        if (diff >= _timeout) {
          debugPrint("🔒 Tiempo excedido -> Bloqueando");
          authNotifier.lockApp();
        } else {
          debugPrint("✅ Regreso rápido -> No bloquear");
          _resetTimer();
        }
      }
      _backgroundTime = null;
    }

    // ❌ CIERRE TOTAL (Detached)
    if (state == AppLifecycleState.detached) {
      // Bloquear síncronamente antes de que el proceso muera
      authNotifier.lockApp();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () => ref.read(authProvider.notifier).lockApp());
  }

  void _resetTimer() {
    _startTimer();
    ref.read(authProvider.notifier).resetInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tutorial = ref.watch(tutorialProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.getRoutes(authState),
        home: tutorial.when(
          loading: () => const SplashScreen(),
          error: (_, __) => const Scaffold(body: Center(child: Text("Error"))),
          data: (seen) {
            if (authState.isLoading) return const SplashScreen();

            // 1. Mostrar pantalla de bloqueo si el estado es Locked
            if (authState.isLocked) return const LockedScreen();

            // 2. Flujo de navegación normal
            if (authState.isAuthenticated) {
              return !seen ? const TutorialScreen() : const HomeScreen();
            }

            return const WelcomeScreen();
          },
        ),
      ),
    );
  }
}
