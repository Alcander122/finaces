// Pantalla principal para gestionar bancos
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
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';
    final bancos = ref.watch(proveedorBancos);

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
                // Pestaña: Lista de bancos
                ListView.builder(
                  itemCount: bancos.length,
                  itemBuilder: (context, indice) {
                    final banco = bancos[indice];
                    return TarjetaBanco(banco: banco);
                  },
                ),
                // Pestaña: Tasa de interés
                ListView.builder(
                  itemCount: bancos.length,
                  itemBuilder: (context, indice) {
                    final banco = bancos[indice];
                    return ListTile(
                      title: Text(banco.nombre),
                      subtitle: Text('${banco.tasaInteres}%'),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo para seleccionar un banco
  void _mostrarDialogoAgregarBanco(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => DialogoSeleccionarBanco(
        onSeleccionar: (banco) =>
            _mostrarDialogoNumeroCuenta(context, banco, userId),
      ),
    );
  }

  // Mostrar diálogo para ingresar número de cuenta
  void _mostrarDialogoNumeroCuenta(
      BuildContext context, BancoModelo banco, String userId) {
    final controladorCuenta = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => DialogoNumeroCuenta(
        banco: banco,
        controladorCuenta: controladorCuenta,
        onGuardar: () {
          final bancoActualizado = BancoModelo(
            id: banco.id,
            nombre: banco.nombre,
            tasaInteres: banco.tasaInteres,
            numeroCuenta: controladorCuenta.text,
            // agrega aquí otros campos si existen en BancoModelo
          );
          ref
              .read(proveedorBancos.notifier)
              .agregarBanco(bancoActualizado, userId);
        },
      ),
    );
  }
}
