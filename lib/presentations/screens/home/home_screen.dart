import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/presentations/screens/Ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/Auth/LoginScreen.dart';
import 'package:finances/presentations/screens/Egreso/egresos_screen.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import '../ingresos/ingresos_screen.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen();
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
      backgroundColor: const Color(0xFFd6eaf8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3A59D1), Color(0xFF3A59D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 32.0),
                child: _buildUserProfile(context, authState),
              ),
            ),
            const SizedBox(height: 25),
            _buildFinancialSummary(totalIngresos, totalGastos),
            const SizedBox(height: 25),
            const Text(
              'Acciones rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildMenuCardsSeccion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AuthState authState) {
    return authState.user == null
        ? const CircularProgressIndicator()
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF3674B5), size: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${authState.user?.displayName ?? 'Usuario'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Resumen del mes',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildFinancialSummary(double ingresos, double gastos) {
    final saldo = ingresos - gastos;
    final isPositive = saldo >= 0;
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            bottom: -70,
            right: -25,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/logobill.png',
                width: 180,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen financiero',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _customStatCard(
                      'Ingresos', ingresos, Icons.arrow_upward, Colors.green),
                  _customStatCard(
                      'Gastos', gastos, Icons.arrow_downward, Colors.red),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saldo disponible',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(saldo),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Subcomponente reutilizable
  Widget _customStatCard(
      String label, double amount, IconData icon, Color iconColor) {
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
          const SizedBox(height: 4),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(context, 'Ingreso', Icons.add_circle, Colors.green,
            IngresosScreen()),
        _actionButton(
            context, 'Gasto', Icons.remove_circle, Colors.red, EgresosScreen()),
        _actionButton(context, 'Estadísticas', Icons.bar_chart, Colors.purple,
            StatisticScreen()),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon,
      Color color, Widget screen) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => screen)),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha:0.2),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ],
    );
  }

  Widget _buildMenuCardsSeccion(BuildContext context) {
    final List<Map<String, dynamic>> tips = [
      {
        'icon': const Icon(FontAwesomeIcons.piggyBank, color: Colors.orange),
        'title': 'Ahorros',
        'description': 'Controla tus ahorros.',
        'screen': AhorroScreen(),
      },
      {
        'icon': const Icon(FontAwesomeIcons.buildingColumns, color: Colors.red),
        'title': 'Mis Bancos',
        'description': 'Accede a tus cuentas.',
        'screen': AhorroScreen(),
      },
      {
        'icon': const Icon(FontAwesomeIcons.chartLine,
            color: Color.fromARGB(255, 77, 235, 103)),
        'title': 'Portafolio',
        'description': 'Visualiza tu portafolio.',
        'screen': PortafolioScreen(),
      },
      {
        'icon':
            const Icon(FontAwesomeIcons.calendarCheck, color: Colors.orange),
        'title': 'Pagos',
        'description': 'Pagos agendados.',
        'screen': AhorroScreen(),
      },
      {
        'icon': const Icon(FontAwesomeIcons.clockRotateLeft, color: Colors.red),
        'title': 'Historial',
        'description': 'Historial de movimientos.',
        'screen': AhorroScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text('Accesos rápidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final item = tips[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => item['screen'])),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF578FCA), Color(0xFF3A59D1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      item['icon'] as Widget,
                      const SizedBox(height: 8),
                      Text(
                        item['title'],
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'],
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
