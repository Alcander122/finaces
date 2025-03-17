import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/finanzas_provider.dart';
import 'package:finances/presentations/screens/egreso/egresos_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
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
    final authState = ref.watch(authProvider);
    final totalIngresosMesAsync = ref.watch(totalIngresosMesActualProvider);
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);

    final totalIngresos = totalIngresosMesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0.0,
    );

    final totalGastos = totalGastosAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0.0,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Finanzas Personales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          /* IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navegar a la pantalla de configuración
            },
          ),*/
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildUserProfile(authState),
            const SizedBox(height: 30),
            _buildFinancialSummary(totalIngresos, totalGastos),
            const SizedBox(height: 30),
            _buildQuickActions(context),
            const SizedBox(height: 30),
            _buildMainMenu(context),
          ],
        ),
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva Transacción'),
        onPressed: () {
          // Abrir modal para nueva transacción
        },
        backgroundColor: Colors.green,
      ),*/
    );
  }

  Widget _buildUserProfile(AuthState authState) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[300],
          child: Icon(
            Icons.person,
            color: Colors.grey[700],
            size: 40,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${authState.user?.displayName ?? 'Sin nombre'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Resumen de este mes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary(double totalIngresos, double totalGastos) {
    final saldo = totalIngresos - totalGastos;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatisticCard(
                  title: 'Ingresos',
                  amount: totalIngresos,
                  color: Colors.green,
                  icon: Icon(Icons.arrow_upward),
                ),
                StatisticCard(
                  title: 'Gastos',
                  amount: totalGastos,
                  color: Colors.red,
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  saldo >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: saldo >= 0 ? Colors.green : Colors.red,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  '\$${saldo.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: saldo >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              saldo >= 0 ? 'Saldo Positivo' : 'Saldo Negativo',
              style: TextStyle(
                color: saldo >= 0 ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionChip(
          avatar: Icon(Icons.add_circle, color: Colors.green),
          label: const Text('Ingreso'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => IngresosScreen()),
            );
          },
          backgroundColor: Colors.green[50],
        ),
        ActionChip(
          avatar: Icon(Icons.remove_circle, color: Colors.red),
          label: const Text('Gasto'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EgresosScreen()),
            );
          },
          backgroundColor: Colors.red[50],
        ),
        ActionChip(
          avatar: Icon(Icons.bar_chart, color: Colors.blue),
          label: const Text('Estadísticas'),
          onPressed: () {
            // Navegar a la pantalla de estadísticas
          },
          backgroundColor: Colors.blue[50],
        ),
      ],
    );
  }

  Widget _buildMainMenu(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Menú Principal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
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
              title: 'Portafolio de Inversión',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PortafolioScreen()),
                );
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
            MenuOption(
              icon: Icons.history,
              title: 'Historial',
              color: Colors.grey,
              onTap: () {
                // Navegar a la pantalla de Historial
              },
            ),
          ],
        ),
      ],
    );
  }
}
