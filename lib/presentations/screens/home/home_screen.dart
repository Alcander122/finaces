import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/presentations/screens/Ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/Bancos/banks_screen.dart';
import 'package:finances/presentations/screens/Egreso/egresos_screen.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/Pagos/pagos_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/widgets/smart_ad_banner.dart'; // 🆕 Nuevo
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

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando...'),
            ],
          ),
        ),
      );
    }

    final totalIngresosMesAsync = ref.watch(totalIngresosMesActualProvider);
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundContainer(
        backgroundImagePath: 'assets/images/bg3.jpg',
        child: CustomScrollView(
          slivers: [
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
                      ScaffoldMessenger.of(context).clearSnackBars();
                      Navigator.pushNamed(context, '/profile');
                    },
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Perfil del usuario
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

                  // 2. Resumen financiero
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: totalIngresosMesAsync.when(
                      data: (ingresos) => totalGastosAsync.when(
                        data: (gastos) =>
                            _buildFinancialSummary(ingresos, gastos),
                        loading: () => _buildLoadingFinancialSummary(),
                        error: (error, _) => _buildErrorFinancialSummary(error),
                      ),
                      loading: () => _buildLoadingFinancialSummary(),
                      error: (error, _) => _buildErrorFinancialSummary(error),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 3. Acciones rápidas
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Acciones rápidas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildQuickActions(context),
                  ),
                  const SizedBox(height: 20),

                  // 4. Tarjetas de acceso rápido (Metas, Bancos, etc)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMenuCardsSeccion(context),
                  ),

                  // 5. 🔥 ANUNCIO (Solo si no es premium)
                  const SmartAdBanner(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE AYUDA (ORIGINALES) ---

  Widget _buildUserProfile(BuildContext context, AuthState authState) {
    return authState.user == null
        ? const CircularProgressIndicator()
        : Row(
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.pushNamed(context, '/profile');
                },
                child: const CircleAvatar(
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
                          color: Themes.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Resumen del mes',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildFinancialSummary(double ingresos, double gastos) {
    final saldo = ingresos - gastos;
    final isPositive = saldo >= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Themes.infoBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))
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
              child: Image.asset('assets/images/logobill.png',
                  width: 150, color: const Color(0xFF1A2B63)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen financiero',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800])),
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
                    Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 30),
                    const Text('Saldo disponible',
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(formatCurrency(saldo),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customStatCard(
      String label, double amount, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(formatCurrency(amount),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(context, 'Ingresos', Icons.add_circle, Colors.green,
            const IngresosScreen()),
        _actionButton(context, 'Gastos', Icons.remove_circle, Colors.red,
            const EgresosScreen()),
        _actionButton(context, 'Estadísticas', Icons.bar_chart, Colors.purple,
            const StatisticScreen()),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon,
      Color color, Widget screen) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => screen));
          },
          child: CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMenuCardsSeccion(BuildContext context) {
    final List<Map<String, dynamic>> tips = [
      {
        'icon': const Icon(FontAwesomeIcons.piggyBank, color: Colors.orange),
        'title': 'Metas',
        'description': 'Tus metas de ahorro',
        'screen': const AhorroScreen()
      },
      {
        'icon': const Icon(FontAwesomeIcons.buildingColumns, color: Colors.red),
        'title': 'Mis Bancos',
        'description': 'Accede a tus cuentas',
        'screen': const PantallaBancos()
      },
      {
        'icon': const Icon(FontAwesomeIcons.chartLine, color: Colors.green),
        'title': 'Portafolio',
        'description': 'Tu portafolio',
        'screen': const PortafolioScreen()
      },
      {
        'icon':
            const Icon(FontAwesomeIcons.calendarCheck, color: Colors.orange),
        'title': 'Pagos',
        'description': 'Pagos programados',
        'screen': const PagosScreen()
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Accesos rápidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final item = tips[index];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => item['screen']));
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Themes.degradientLight,
                      Themes.degradientDark
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      item['icon'],
                      const SizedBox(height: 8),
                      Text(item['title'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(item['description'],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
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

  // --- CARGA Y ERROR ---
  Widget _buildLoadingFinancialSummary() =>
      const Center(child: CircularProgressIndicator());
  Widget _buildErrorFinancialSummary(Object error) =>
      Center(child: Text('Error: $error'));
}

class _AppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight, maxHeight;
  final Widget Function(double shrinkOffset) onBuildTitle;

  _AppBarDelegate(
      {required this.minHeight,
      required this.maxHeight,
      required this.onBuildTitle});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Themes.white, child: onBuildTitle(shrinkOffset));
  }

  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;
  @override
  bool shouldRebuild(covariant _AppBarDelegate oldDelegate) => true;
}

String formatCurrency(double value) {
  final formatter = NumberFormat.decimalPattern('es_CO');
  return '\$${formatter.format(value)}';
}
