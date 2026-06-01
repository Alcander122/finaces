import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/Pagos/providers/payment_providers.dart';
import 'package:finances/presentations/screens/Pagos/pendientes_tab.dart';
import 'package:finances/presentations/screens/Pagos/programados_tab.dart';
import 'package:finances/presentations/screens/Pagos/widgets/payment_summary_header.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/theme/themes.dart';

class PagosScreen extends ConsumerStatefulWidget {
  const PagosScreen({super.key});

  @override
  ConsumerState<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends ConsumerState<PagosScreen>
    with TickerProviderStateMixin {
  late TabController _controladorTabs;

  @override
  void initState() {
    super.initState();
    _controladorTabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controladorTabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';

    if (!authState.isAuthenticated || userId.isEmpty) {
      return const Scaffold(
        backgroundColor: Themes.degradientLight,
        body: Center(
          child: Text(
            "Inicia sesión para ver tus pagos.",
            style: TextStyle(color: Themes.white, fontSize: 16),
          ),
        ),
      );
    }

    ref.watch(paymentsStreamProvider(userId));

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        useLogoAsTitle: true,
        showProfileIcon: false,
      ),
      body: isTablet 
          ? _buildTabletSplitLayout(userId)
          : _buildMobileLayout(userId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/agregar-pago'),
        backgroundColor: Themes.iconsButton,
        child: const Icon(Icons.add, color: Themes.white),
      ),
    );
  }

  // Layout de doble columna para Tablets / PCs
  Widget _buildTabletSplitLayout(String userId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Columna Izquierda: KPIs y Resúmenes (40% de la pantalla)
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade200, width: 1.5),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen del Mes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Themes.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Visualiza y controla tus egresos periódicos.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  PaymentSummaryHeader(userId: userId, isVertical: true),
                ],
              ),
            ),
          ),
        ),
        // Columna Derecha: Tabs y Listados de Pagos (60% de la pantalla)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Themes.degradientDark, Themes.degradientLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: TabBar(
                  controller: _controladorTabs,
                  labelColor: Themes.white,
                  unselectedLabelColor: Themes.greyDisabled,
                  indicatorColor: Themes.white,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(Icons.access_time), text: 'Pendientes'),
                    Tab(icon: Icon(Icons.calendar_today), text: 'Programados'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _controladorTabs,
                  children: [
                    PendientesTab(userId: userId),
                    ProgramadosTab(userId: userId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Layout estándar vertical para móviles
  Widget _buildMobileLayout(String userId) {
    return Column(
      children: [
        // Cabecera de KPIs con scroll si es necesario
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: PaymentSummaryHeader(userId: userId, isVertical: false),
        ),
        // Separador visual ligero
        Divider(color: Colors.grey.shade200, height: 1),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Themes.degradientDark, Themes.degradientLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: TabBar(
            controller: _controladorTabs,
            labelColor: Themes.white,
            unselectedLabelColor: Themes.greyDisabled,
            indicatorColor: Themes.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.access_time), text: 'Pendientes'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Programados'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _controladorTabs,
            children: [
              PendientesTab(userId: userId),
              ProgramadosTab(userId: userId),
            ],
          ),
        ),
      ],
    );
  }
}
