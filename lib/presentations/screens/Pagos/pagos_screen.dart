// Pantalla principal de pagos (refactorizada y con diseño adaptado a Themes)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/payment_provider.dart';
import 'package:finances/presentations/screens/Pagos/pendientes_tab.dart';
import 'package:finances/presentations/screens/Pagos/programados_tab.dart';
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

    ref.watch(paymentProvider(userId));

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        useLogoAsTitle: true,
        showProfileIcon: false,
      ),
      body: Column(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/agregar-pago'),
        backgroundColor: Themes.iconsButton,
        child: const Icon(Icons.add, color: Themes.white),
      ),
    );
  }
}
