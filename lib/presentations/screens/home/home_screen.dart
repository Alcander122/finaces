import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/finanzas_provider.dart';
import 'package:finances/presentations/screens/ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/auth/LoginScreen.dart';
import 'package:finances/presentations/screens/egreso/egresos_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/presentations/widgets/menu_option.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import '../ingresos/ingresos_screen.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    /*logger.d(
        'Estado de autenticación en HomeScreen: ${authState.isAuthenticated}');
    print(
        'Estado de autenticación en HomeScreen: ${authState.isAuthenticated}');*/

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen(); // Asegúrate de redirigir al login
    }
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
      appBar: const AppBarFinances(),
      backgroundColor: Color(0xFFd6eaf8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            _buildUserProfile(authState),
            const SizedBox(height: 5),
            _buildFinancialSummary(totalIngresos, totalGastos),
            const SizedBox(height: 5),
            _buildQuickActions(context),
            const SizedBox(height: 5),
            _buildMainMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(AuthState authState) {
    return authState.user == null
        ? const CircularProgressIndicator()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3A57E8),
                  Color(0xFF0C1F6F),
                  Color(0xFF050A30),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1B263B),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, ${authState.user?.displayName ?? 'Sin nombre'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Resumen de este mes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9BAEC8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildFinancialSummary(double totalIngresos, double totalGastos) {
    final saldo = totalIngresos - totalGastos;
    final isPositive = saldo >= 0;

    String formatCurrency(double value) {
      final formatter = NumberFormat.decimalPattern('es_CO');
      return '\$${formatter.format(value)}';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF050A30),
            Color(0xFF08124D),
            Color(0xFF0C1F6F),
            Color(0xFF2045C6),
            Color(0xFF3A57E8),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Resumen financiero",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _customStatCard(
                title: "Ingresos",
                amount: totalIngresos,
                icon: Icons.arrow_upward,
                color: Colors.greenAccent,
              ),
              _customStatCard(
                title: "Gastos",
                amount: totalGastos,
                icon: Icons.arrow_downward,
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                size: 34,
              ),
              const SizedBox(width: 10),
              Text(
                formatCurrency(saldo),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isPositive ? '¡Estás en positivo!' : 'Atención: saldo negativo',
            style: TextStyle(
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    String formatCurrency(double value) {
      final formatter = NumberFormat.decimalPattern('es_CO');
      return '\$${formatter.format(value)}';
    }

    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),

        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCurrency(amount),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(context, 'Ingreso', Icons.add_circle, Colors.green,
            IngresosScreen()),
        _actionButton(
            context, 'Gasto', Icons.remove_circle, Colors.red, EgresosScreen()),
        _actionButton(
            context, 'Estadisticas', Icons.bar_chart, Colors.purple, null),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon,
      Color color, Widget? screen) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (screen != null) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => screen));
            }
          },
          child: CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.3),

            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Color(0xFF0B0D39))),
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
              title: 'Ahorros', // Acortado
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AhorroScreen()),
                );
              },
            ),
            MenuOption(
              icon: Icons.trending_up,
              title: 'Portafolio', // Acortado
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
              title: 'Pagos Programados', // Acortado
              color: Colors.orange,
              onTap: () {
                // Navegar a la pantalla de Pagos Programados
              },
            ),
            MenuOption(
              icon: Icons.pending_actions,
              title: 'Pagos Pendientes', // Acortado
              color: Colors.teal,
              onTap: () {
                // Navegar a la pantalla de Pagos Pendientes
              },
            ),
            MenuOption(
              icon: Icons.account_balance,
              title: 'Mis Bancos', // Acortado
              color: Colors.brown,
              onTap: () {
                // Navegar a la pantalla de Neo Bank
              },
            ),
            MenuOption(
              icon: Icons.history,
              title: 'Historial', // Acortado
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
