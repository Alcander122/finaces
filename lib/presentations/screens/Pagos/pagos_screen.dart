// Pantalla principal de pagos (refactorizada)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/payment_provider.dart';
import 'package:finances/presentations/screens/Pagos/pendientes_tab.dart';
import 'package:finances/presentations/screens/Pagos/programados_tab.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';

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
        body: Center(child: Text("Inicia sesión para ver tus pagos.")),
      );
    }

    ref.watch(paymentProvider(userId));

    return Scaffold(
      appBar: AppBarFinances(
        useLogoAsTitle: true,
        showProfileIcon: false,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _controladorTabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade300,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/agregar-pago'),
        child: const Icon(Icons.add),
      ),
    );
  }
}