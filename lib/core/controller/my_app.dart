import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Timer? _inactivityTimer;

  /// Duración de inactividad antes de cerrar sesión automáticamente
  final Duration _timeoutDuration = const Duration(minutes: 50);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer(); // Inicia el temporizador cuando inicia la app
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel(); // Limpia el temporizador al cerrar la app
    super.dispose();
  }

  /// Reinicia el temporizador si la app vuelve al primer plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }

  /// Inicia el temporizador de inactividad
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, _handleInactivity);
  }

  /// Reinicia el temporizador de inactividad
  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  /// Cierra sesión por inactividad
  void _handleInactivity() {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        // Cada toque del usuario reinicia el temporizador
        _resetInactivityTimer();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.welcome,
        routes: AppRoutes.getRoutes(authState),
      ),
    );
  }
}
