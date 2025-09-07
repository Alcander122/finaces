import 'package:finances/presentations/screens/Bancos/widgets/DialogoLlaves.dart';
import 'package:finances/presentations/screens/Bancos/widgets/DialogoNumeroCuenta.dart';
import 'package:finances/presentations/screens/Bancos/widgets/DialogoSeleccionarBanco.dart';
import 'package:finances/presentations/screens/Bancos/widgets/DialogoTipoIdentificador.dart';
import 'package:finances/presentations/screens/Bancos/widgets/TarjetaBanco.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/theme/themes.dart';

/// Pantalla principal de gestión de cuentas bancarias
///
/// FLUJO CORRECTO DE TRABAJO:
/// 1. Usuario hace clic en el botón "+" para agregar un banco
/// 2. Se muestra DialogoSeleccionarBanco (SOLO CON NOMBRES DE BANCOS)
/// 3. Al seleccionar un banco, se crea un BancoModelo TEMPORAL CON USERID REAL
/// 4. Se muestra DialogoTipoIdentificador
/// 5. Según la selección, se muestra DialogoNumeroCuenta o DialogoLlaves
/// 6. Finalmente, se guarda la información en Firestore
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
    _controladorTabs = TabController(length: 1, vsync: this);
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _controladorTabs,
                children: [
                  _buildBancosTab(bancos, userId),
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

  /// Muestra el diálogo para agregar un nuevo banco
  ///
  /// FLUJO CORREGIDO:
  /// 1. Muestra DialogoSeleccionarBanco (SOLO DEVUELVE NOMBRE DE BANCO)
  /// 2. Con el nombre y el userId REAL, crea un BancoModelo temporal
  /// 3. Muestra DialogoTipoIdentificador
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
        onSeleccionar: (nombreBanco) {
          // CREACIÓN CORRECTA: Solo aquí obtenemos el userId REAL
          final bancoTemporal = BancoModelo(
            id: '', // Firestore generará el ID
            nombre: nombreBanco,
            tipoIdentificador: 'cuenta', // Valor por defecto
            numeroCuenta: null,
            llaves: null,
            userId: userId, // ¡AQUÍ TIENE EL USERID REAL!
          );
          _mostrarDialogoTipoIdentificador(context, bancoTemporal, userId);
        },
      ),
    );
  }

  /// Muestra el diálogo para editar un banco existente
  ///
  /// FLUJO DE EDICIÓN:
  /// 1. Recibe el banco existente que se quiere editar
  /// 2. Dependiendo del tipo de identificador (cuenta o llave), muestra el diálogo correspondiente
  /// 3. Los valores actuales del banco se cargan en los campos
  /// 4. Al guardar, se llama a actualizarBanco() en lugar de crearBanco()
  void _mostrarDialogoEditar(BuildContext context, BancoModelo banco) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    if (banco.tipoIdentificador == 'cuenta') {
      _mostrarDialogoNumeroCuentaEdicion(context, banco, userId);
    } else {
      _mostrarDialogoLlavesEdicion(context, banco, userId);
    }
  }

  /// Muestra el diálogo para seleccionar el tipo de identificador
  void _mostrarDialogoTipoIdentificador(
      BuildContext context, BancoModelo banco, String userId) {
    showDialog(
      context: context,
      builder: (context) => DialogoTipoIdentificador(
        banco: banco,
        onTipoSeleccionado: (tipo) {
          if (tipo == 'cuenta') {
            _mostrarDialogoNumeroCuenta(context, banco, userId);
          } else {
            _mostrarDialogoLlaves(context, banco, userId);
          }
        },
      ),
    );
  }

  /// Muestra el diálogo para ingresar el número de cuenta (para CREAR)
  void _mostrarDialogoNumeroCuenta(
      BuildContext context, BancoModelo banco, String userId) {
    final controladorCuenta = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => DialogoNumeroCuenta(
        banco: banco,
        controladorCuenta: controladorCuenta,
        onGuardar: () {
          // Actualizamos el banco con los datos completos
          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'cuenta',
            numeroCuenta: controladorCuenta.text,
          );

          ref
              .read(bancoNotifierProvider(userId).notifier)
              .crearBanco(bancoCompleto)
              .then((_) {
            Navigator.of(context).pop(); // Cierra el diálogo de cuenta
            Navigator.of(context).pop(); // Cierra el diálogo de tipo
            Navigator.of(context).pop(); // Cierra el diálogo de banco
          });
        },
      ),
    );
  }

  /// Muestra el diálogo para ingresar el número de cuenta (para EDITAR)
  void _mostrarDialogoNumeroCuentaEdicion(
      BuildContext context, BancoModelo banco, String userId) {
    final controladorCuenta = TextEditingController();

    // Cargar el valor existente en el controlador
    if (banco.numeroCuenta != null) {
      controladorCuenta.text = banco.numeroCuenta!;
    }

    showDialog(
      context: context,
      builder: (context) => DialogoNumeroCuenta(
        banco: banco,
        controladorCuenta: controladorCuenta,
        onGuardar: () {
          // Actualizamos el banco con los datos completos
          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'cuenta',
            numeroCuenta: controladorCuenta.text,
          );

          ref
              .read(bancoNotifierProvider(userId).notifier)
              .actualizarBanco(bancoCompleto)
              .then((_) {
            Navigator.of(context).pop(); // Cierra el diálogo de cuenta
            Navigator.of(context)
                .pop(); // Cierra el diálogo de tipo (si está abierto)
          });
        },
      ),
    );
  }

  /// Muestra el diálogo para ingresar las 3 llaves (para CREAR)
  void _mostrarDialogoLlaves(
      BuildContext context, BancoModelo banco, String userId) {
    final controladores = List.generate(3, (_) => TextEditingController());
    showDialog(
      context: context,
      builder: (context) => DialogoLlaves(
        banco: banco,
        controladores: controladores,
        onGuardar: () {
          final llaves = controladores.map((c) => c.text).toList();
          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'llave',
            llaves: llaves,
          );

          ref
              .read(bancoNotifierProvider(userId).notifier)
              .crearBanco(bancoCompleto)
              .then((_) {
            Navigator.of(context).pop(); // Cierra diálogo llaves
            Navigator.of(context).pop(); // Cierra diálogo tipo
            Navigator.of(context).pop(); // Cierra diálogo banco
          });
        },
      ),
    );
  }

  /// Muestra el diálogo para ingresar las 3 llaves (para EDITAR)
  void _mostrarDialogoLlavesEdicion(
      BuildContext context, BancoModelo banco, String userId) {
    final controladores = List.generate(3, (_) => TextEditingController());

    // Cargar los valores existentes en los controladores
    if (banco.llaves != null) {
      for (int i = 0; i < banco.llaves!.length && i < 3; i++) {
        controladores[i].text = banco.llaves![i];
      }
    }

    showDialog(
      context: context,
      builder: (context) => DialogoLlaves(
        banco: banco,
        controladores: controladores,
        onGuardar: () {
          final llaves = controladores.map((c) => c.text).toList();
          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'llave',
            llaves: llaves,
          );

          ref
              .read(bancoNotifierProvider(userId).notifier)
              .actualizarBanco(bancoCompleto)
              .then((_) {
            Navigator.of(context).pop(); // Cierra diálogo llaves
            Navigator.of(context)
                .pop(); // Cierra diálogo tipo (si está abierto)
          });
        },
      ),
    );
  }

  /// Construye la pestaña de bancos
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
        if (banco.nombre.isEmpty) {
          return const SizedBox.shrink();
        }
        return TarjetaBanco(
          banco: banco,
          onEliminar: () {
            ref
                .read(bancoNotifierProvider(userId).notifier)
                .eliminarBanco(banco.id, userId);
          },
          onEditar: () => _mostrarDialogoEditar(
              context, banco), // ¡Parámetro requerido agregado!
        );
      },
    );
  }
}
