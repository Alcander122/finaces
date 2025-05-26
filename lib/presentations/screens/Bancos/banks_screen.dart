import 'package:finances/presentations/screens/Bancos/widgets/DialogoNumeroCuenta.dart';
import 'package:finances/presentations/screens/Bancos/widgets/DialogoSeleccionarBanco.dart';
import 'package:finances/presentations/screens/Bancos/widgets/TarjetaBanco.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

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
    // Obtenemos el estado de autenticación
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';
    
    // Usamos el StreamProvider con el userId como parámetro
    final bancosAsync = ref.watch(proveedorBancos(userId)); 

    return Scaffold(
      appBar: AppBarFinances(
        useLogoAsTitle: true,
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            // Mostramos diálogo para agregar banco
            onPressed: () => _mostrarDialogoAgregarBanco(context, userId),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _controladorTabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Bancos'),
                Tab(text: 'Tasa'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _controladorTabs,
              children: [
                _buildBancosTab(bancosAsync),
                _buildTasaTab(bancosAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construye la pestaña de bancos
  Widget _buildBancosTab(AsyncValue<List<BancoModelo>> bancosAsync) {
    return bancosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
      data: (bancos) {
        return ListView.builder(
          itemCount: bancos.length,
          itemBuilder: (context, index) {
            final banco = bancos[index];
            return TarjetaBanco(banco: banco);
          },
        );
      },
    );
  }

  // Construye la pestaña de tasa
  Widget _buildTasaTab(AsyncValue<List<BancoModelo>> bancosAsync) {
    return bancosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
      data: (bancos) {
        return ListView.builder(
          itemCount: bancos.length,
          itemBuilder: (context, index) {
           // final banco = bancos[index];
            return ListTile(
             // title: Text(banco.nombre),
              //subtitle: Text('${banco.tasaInteres}%'),
            );
          },
        );
      },
    );
  }

  // Muestra diálogo para agregar banco
  void _mostrarDialogoAgregarBanco(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => DialogoSeleccionarBanco(
        onSeleccionar: (banco) =>
            _mostrarDialogoNumeroCuenta(context, banco, userId),
      ),
    );
  }

  // Muestra diálogo para ingresar número de cuenta
  void _mostrarDialogoNumeroCuenta(
      BuildContext context, BancoModelo banco, String userId) {
    final controladorCuenta = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => DialogoNumeroCuenta(
        banco: banco,
        controladorCuenta: controladorCuenta,
        onGuardar: () {
          final nuevoBanco = BancoModelo(
            id: '', // Firestore generará el ID
            nombre: banco.nombre,
            numeroCuenta: controladorCuenta.text,
            userId: userId,
          );
          // Usamos el StateNotifierProvider para crear el banco
          ref.read(bancoNotifierProvider.notifier).crearBanco(nuevoBanco);
        },
      ),
    );
  }
}