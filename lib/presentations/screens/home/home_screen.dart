import 'package:finances/presentations/widgets/menu_option.dart';
import 'package:finances/presentations/widgets/statistic_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas Personales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Bienvenido, ${user?.displayName ?? 'Usuario'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '\$1,000,000',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const <Widget>[
                StatisticCard(
                    title: 'Ingresos',
                    amount: '\$2,500,000',
                    color: Colors.blue),
                StatisticCard(
                    title: 'Gastos', amount: '\$1,500,000', color: Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Opciones',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            MenuOption(
              icon: Icons.add_circle,
              title: 'Ingresos',
              color: Colors.green,
              onTap: () {
                // Navegar a la pantalla de Ingresos
              },
            ),
            MenuOption(
              icon: Icons.remove_circle,
              title: 'Egresos',
              color: Colors.red,
              onTap: () {
                // Navegar a la pantalla de Egresos
              },
            ),
            MenuOption(
              icon: Icons.savings,
              title: 'Ahorros',
              color: Colors.blue,
              onTap: () {
                // Navegar a la pantalla de Ahorros
              },
            ),
            MenuOption(
              icon: Icons.trending_up,
              title: 'Plan de Inversión',
              color: Colors.purple,
              onTap: () {
                // Navegar a la pantalla de Plan de Inversión
              },
            ),
            MenuOption(
              icon: Icons.schedule,
              title: 'Pagos Programados',
              color: Colors.orange,
              onTap: () {
                // Navegar a la pantalla de Pagos Programados
              },
            ),
            MenuOption(
              icon: Icons.pending_actions,
              title: 'Pagos Pendientes',
              color: Colors.teal,
              onTap: () {
                // Navegar a la pantalla de Pagos Pendientes
              },
            ),
            MenuOption(
              icon: Icons.account_balance,
              title: 'Neo Bank',
              color: Colors.brown,
              onTap: () {
                // Navegar a la pantalla de Neo Bank
              },
            ),
          ],
        ),
      ),
    );
  }
}
