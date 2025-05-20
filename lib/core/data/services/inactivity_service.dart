import 'dart:async';
import 'package:flutter/widgets.dart';

typedef VoidCallback = void Function();

class InactivityService with WidgetsBindingObserver {
  final Duration timeout;
  final VoidCallback onTimeout;
  Timer? _timer;

  InactivityService({required this.timeout, required this.onTimeout});

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  // Llama cada vez que cambia el estado de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetTimer();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  void handleUserInteraction() {
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(timeout, onTimeout);
  }
}
