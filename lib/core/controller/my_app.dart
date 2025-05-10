// lib/core/controller/my_app.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // print("Estado de autenticación: $authState");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.getRoutes(authState),
    );
  }
}
