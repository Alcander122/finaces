import 'package:finances/presentations/screens/Bancos/widgets/DialogoNumeroCuenta.dart';
import 'package:finances/presentations/screens/Bancos/widgets/DialogoSeleccionarBanco.dart';
import 'package:finances/presentations/screens/Bancos/widgets/TarjetaBanco.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/theme/themes.dart';

class PantallaBancos extends ConsumerStatefulWidget {
  const PantallaBancos({super.key});

  @override
  ConsumerState<PantallaBancos> createState() => _EstadoPantallaBancos();
}

class _EstadoPantallaBancos extends ConsumerState<PantallaBancos>
    with SingleTickerProviderStateMixin {
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

    final bancosAsync = ref.watch(bancoNotifierProvider(userId));

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        useLogoAsTitle: true,
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Themes.white,
            onPressed: () => _mostrarDialogoAgregarBanco(context, userId),
          ),
        ],
      ),
      body: bancosAsync.when(
        data: (bancos) => Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Themes.degradientDark, Themes.degradientLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TabBar(
                controller: _controladorTabs,
                labelColor: Themes.white,
                unselectedLabelColor: Colors.grey[300],
                indicatorColor: Themes.white,
                tabs: const [
                  Tab(text: 'Bancos'),
                  //Tab(text: 'Tasa'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _controladorTabs,
                children: [
                  _buildBancosTab(bancos, userId),
                  _buildTasaTab(bancos),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildBancosTab(List<BancoModelo> bancos, String userId) {
    if (bancos.isEmpty) {
      return const Center(child: Text("No hay bancos registrados."));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: bancos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final banco = bancos[index];
        return TarjetaBanco(
          banco: banco,
          onEliminar: () {
            ref
                .read(bancoNotifierProvider(userId).notifier)
                .eliminarBanco(banco.id, userId);
          },
        );
      },
    );
  }

  Widget _buildTasaTab(List<BancoModelo> bancos) {
    if (bancos.isEmpty) {
      return const Center(child: Text("No hay datos disponibles."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bancos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final banco = bancos[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              banco.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Cuenta: ${banco.numeroCuenta}'),
            leading: const Icon(Icons.account_balance),
          ),
        );
      },
    );
  }

  void _mostrarDialogoAgregarBanco(BuildContext context, String userId) {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DialogoSeleccionarBanco(
        onSeleccionar: (banco) =>
            _mostrarDialogoNumeroCuenta(context, banco, userId),
      ),
    );
  }

  void _mostrarDialogoNumeroCuenta(
      BuildContext context, BancoModelo banco, String userId) {
    final controladorCuenta = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => DialogoNumeroCuenta(
        banco: banco,
        controladorCuenta: controladorCuenta,
        onGuardar: () {
          final nuevoBanco = BancoModelo.sinId(
            nombre: banco.nombre,
            numeroCuenta: controladorCuenta.text,
            userId: userId,
          );

          ref
              .read(bancoNotifierProvider(userId).notifier)
              .crearBanco(nuevoBanco)
              .then((_) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
        },
      ),
    );
  }
}
