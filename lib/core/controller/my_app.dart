import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/SecondScreen.dart';
import 'package:finances/presentations/screens/auth/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    print("Estado de autenticación: $authState"); // Depuración

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: authState == null ? LoginScreen() : const SecondScreen(),
    );
  }
}
