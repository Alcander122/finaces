import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/presentations/screens/Ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/Auth/LoginScreen.dart';
import 'package:finances/presentations/screens/Bancos/banks_screen.dart';
import 'package:finances/presentations/screens/Egreso/egresos_screen.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import '../ingresos/ingresos_screen.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/background_container.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Mostrar un indicador de carga si el estado de autenticación está cargando
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Redirigir al login si no está autenticado
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Obtener datos financieros del usuario
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
      backgroundColor: Colors.transparent,
      body: BackgroundContainer(
        backgroundImagePath: 'assets/images/bg3.jpg',
        child: CustomScrollView(
          slivers: [
            // AppBar persistente
            SliverPersistentHeader(
              pinned: true,
              delegate: _AppBarDelegate(
                minHeight: 100,
                maxHeight: 100,
                onBuildTitle: (shrinkOffset) {
                  final showTitle = shrinkOffset > 0;
                  return AppBarFinances(
                    useLogoAsTitle: !showTitle,
                    title: showTitle ? 'BillNance' : null,
                    showProfileIcon: true,
                    onProfilePressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  );
                },
              ),
            ),

            // Contenido principal
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del usuario
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Themes.degradientDark, Themes.degradientLight],
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

                  // Resumen financiero
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildFinancialSummary(totalIngresos, totalGastos),
                  ),
                  const SizedBox(height: 25),

                  // Acciones rápidas
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Acciones rápidas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildQuickActions(context),
                  ),
                  const SizedBox(height: 20),

                  // Tarjetas de acceso rápido
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
                    child: _buildMenuCardsSeccion(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construir perfil del usuario
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
                  child: Icon(Icons.person,
                      color: const Color(0xFF3674B5), size: 32),
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
                        color: Themes.white,
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

  // Construir resumen financiero
  Widget _buildFinancialSummary(double ingresos, double gastos) {
    final saldo = ingresos - gastos;
    final isPositive = saldo >= 0;
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Themes.infoBlue,
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
            bottom: -50,
            right: -15,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/logobill.png',
                width: 150,
                color: const Color(0xFF1A2B63),
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

  // Tarjeta personalizada para estadísticas
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
            offset: const Offset(0, 2),
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

  // Botones de acciones rápidas
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(context, 'Ingresos', Icons.add_circle, Colors.green,
            IngresosScreen()),
        _actionButton(context, 'Gastos', Icons.remove_circle, Colors.red,
            EgresosScreen()),
        _actionButton(context, 'Estadísticas', Icons.bar_chart, Colors.purple,
            StatisticScreen()),
      ],
    );
  }

  // Botón individual de acción rápida
  Widget _actionButton(BuildContext context, String label, IconData icon,
      Color color, Widget screen) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderScope(child: screen),
              )),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha:0.2),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Tarjetas de acceso rápido
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
        'screen': PantallaBancos(),
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
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderScope(child: item['screen']),
                    )),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Themes.degradientLight, Themes.degradientDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
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
                            color: Themes.white),
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

// Delegado para el AppBar persistente
typedef BuildTitle = Widget Function(double shrinkOffset);

class _AppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final BuildTitle onBuildTitle;

  _AppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.onBuildTitle,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Themes.white,
      child: onBuildTitle(shrinkOffset),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _AppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        onBuildTitle != oldDelegate.onBuildTitle;
  }
}
