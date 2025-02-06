import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/finanzas_provider.dart';
import 'package:finances/core/data/services/egreso_service.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/presentations/screens/egreso/egresos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/presentations/widgets/statistic_card.dart';
import 'package:finances/presentations/widgets/menu_option.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import '../ingresos/ingresos_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final totalIngresosMesAsync = ref.watch(totalIngresosMesActualProvider);
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);

    final totalIngresos = totalIngresosMesAsync.maybeWhen(
      data: (value) {
        print("🔹 Total ingresos en la vista: $value");
        return value;
      },
      orElse: () => 0.0,
    );

    final totalGastos = totalGastosAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0.0,
    );

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
          children: [
            Text(
              'Bienvenido, ${user?.displayName ?? 'Usuario'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${(totalIngresos - totalGastos).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatisticCard(
                  title: 'Ingresos',
                  amount: totalIngresos,
                  color: Colors.blue,
                ),
                StatisticCard(
                  title: 'Gastos',
                  amount: totalGastos,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._buildMenuOptions(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuOptions(BuildContext context) {
    return [
      const SizedBox(height: 10),
      MenuOption(
        icon: Icons.add_circle,
        title: 'Ingresos',
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IngresosScreen()),
          );
        },
      ),
      MenuOption(
        icon: Icons.remove_circle,
        title: 'Egresos',
        color: Colors.red,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EgresosScreen()),
          );
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
        title: 'Portafolio de  Inversión',
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
    ];
  }
}
