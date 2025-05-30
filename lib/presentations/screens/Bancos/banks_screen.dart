// Importaciones necesarias
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
    // Inicializa el controlador de las pestañas (2 tabs)
    _controladorTabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Libera recursos cuando el widget se elimina
    _controladorTabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene el estado de autenticación
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';

    // Obtiene la lista de bancos desde el provider (AsyncValue)
    final bancosAsync = ref.watch(bancoNotifierProvider(userId));

    return Scaffold(
      appBar: AppBarFinances(
        useLogoAsTitle: true,
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarDialogoAgregarBanco(context, userId),
          ),
        ],
      ),
      body: bancosAsync.when(
        data: (bancos) => Column(
          children: [
            // Barra de pestañas
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
            // Vista de contenido de pestañas
            Expanded(
              child: TabBarView(
                controller: _controladorTabs,
                children: [
                  _buildBancosTab(bancos), // Pestaña de bancos
                  _buildTasaTab(bancos), // Pestaña de tasas
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

  // Construye la pestaña "Bancos"
  Widget _buildBancosTab(List<BancoModelo> bancos) {
    if (bancos.isEmpty) {
      return const Center(child: Text("No hay bancos registrados."));
    }

    return ListView.builder(
      itemCount: bancos.length,
      itemBuilder: (context, index) {
        final banco = bancos[index];
        return TarjetaBanco(banco: banco);
      },
    );
  }

  // Construye la pestaña "Tasa"
  Widget _buildTasaTab(List<BancoModelo> bancos) {
    if (bancos.isEmpty) {
      return const Center(child: Text("No hay datos disponibles."));
    }

    return ListView.builder(
      itemCount: bancos.length,
      itemBuilder: (context, index) {
        final banco = bancos[index];
        return ListTile(
          title: Text(banco.nombre),
          subtitle: Text('Cuenta: ${banco.numeroCuenta}'),
        );
      },
    );
  }

  // Muestra diálogo para seleccionar un banco
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
          final nuevoBanco = BancoModelo.sinId(
            nombre: banco.nombre,
            numeroCuenta: controladorCuenta.text,
            userId: userId,
          );

          // Guarda el nuevo banco usando Riverpod
          ref
              .read(bancoNotifierProvider(userId).notifier)
              .crearBanco(nuevoBanco)
              .then((_) {
            // Cierra ambos diálogos después de guardar
            Navigator.of(context).pop(); // Cierra diálogo de número de cuenta
            Navigator.of(context).pop(); // Cierra diálogo de selección
          });
        },
      ),
    );
  }
}
