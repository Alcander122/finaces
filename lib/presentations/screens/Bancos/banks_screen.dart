// 📱 lib/presentations/screens/Bancos/banks_screen.dart
// ============================================================================
// PANTALLA PRINCIPAL DE BANCOS - REFACTORIZADA CON CONTROLLER Y METADATOS PREMIUM
// ============================================================================

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
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
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
    
    // Escuchamos el nuevo stream de bancos enriquecidos con su branding
    final bancosAsync = ref.watch(userBanksProvider(userId));
    
    // 🔥 CACHÉ DE MEMORIA RESILIENTE: Si ya se cargaron bancos anteriormente con éxito,
    // conservamos la lista en pantalla incluso si hay un error o estado de carga temporal al reanudar la app.
    final bancosCached = bancosAsync.valueOrNull;

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        useLogoAsTitle: true,
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Vincular banco',
            onPressed: () => _mostrarDialogoAgregarBanco(context, userId),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Themes.degradientDark, Themes.degradientLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Cuentas Vinculadas'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _controladorTabs,
              children: [
                if (bancosCached != null)
                  _buildBancosTab(bancosCached, userId)
                else
                  bancosAsync.when(
                    data: (bancos) => _buildBancosTab(bancos, userId),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Themes.primary),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              '${ErrorStrings.loadFailed}\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pestaña que lista las cuentas del usuario
  Widget _buildBancosTab(List<BancoModelo> bancos, String userId) {
    if (bancos.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userBanksProvider(userId));
          await ref.read(userBanksProvider(userId).future).catchError((_) => <BancoModelo>[]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Obliga a que siempre sea deslizable para permitir pull-to-refresh
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Themes.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 64,
                  color: Themes.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No hay cuentas vinculadas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Themes.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vincula tus cuentas bancarias para gestionarlas\ny organizar tus saldos de manera inteligente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoAgregarBanco(context, userId),
                icon: const Icon(Icons.add),
                label: const Text('Vincular primera cuenta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Themes.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userBanksProvider(userId));
        // Await silencioso del future para refrescar la carga en background
        await ref.read(userBanksProvider(userId).future).catchError((_) => <BancoModelo>[]);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: bancos.length,
        itemBuilder: (context, index) {
          final banco = bancos[index];
          if (banco.nombre.isEmpty) {
            return const SizedBox.shrink();
          }
          return TarjetaBanco(
            banco: banco,
            onEliminar: () => _eliminarBanco(banco.id, userId, banco.nombre),
            onEditar: () => _mostrarDialogoEditar(context, banco),
          );
        },
      ),
    );
  }

  // ============================================================================
  // FLUJOS DE ACCIÓN ASÍNCRONOS Y SEGUROS (PREVENCIÓN DOBLE SUBMIT)
  // ============================================================================

  void _mostrarDialogoAgregarBanco(BuildContext context, String userId) {
    if (userId.isEmpty) {
      UIHelpers.showErrorSnackBar(context: context, message: 'Usuario no autenticado.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DialogoSeleccionarBanco(
        onSeleccionar: (nombreBanco) {
          final bancoTemporal = BancoModelo(
            id: '',
            nombre: nombreBanco,
            tipoIdentificador: 'cuenta',
            numeroCuenta: null,
            llaves: null,
            userId: userId,
          );
          _mostrarDialogoTipoIdentificador(context, bancoTemporal, userId);
        },
      ),
    );
  }

  void _mostrarDialogoTipoIdentificador(
      BuildContext context, BancoModelo banco, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DialogoTipoIdentificador(
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

  /// Mostrar diálogo para ingresar número de cuenta (CREACIÓN)
  void _mostrarDialogoNumeroCuenta(
      BuildContext context, BancoModelo banco, String userId) {
    final controladorCuenta = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DialogoNumeroCuenta(
        banco: banco,
        controladorCuenta: controladorCuenta,
        onGuardar: () async {
          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'cuenta',
            numeroCuenta: controladorCuenta.text.trim(),
          );

          // Ejecutamos la mutación en el controlador de Riverpod
          await ref.read(bancoControllerProvider.notifier).crearBanco(bancoCompleto);

          if (mounted) {
            Navigator.pop(dialogContext); // Cierra diálogo cuenta
            UIHelpers.showSuccessSnackBar(
              context: context,
              message: 'Banco "${banco.nombre}" vinculado exitosamente.',
            );
          }
        },
      ),
    );
  }

  /// Mostrar diálogo para ingresar llaves (CREACIÓN)
  void _mostrarDialogoLlaves(
      BuildContext context, BancoModelo banco, String userId) {
    final controladores = List.generate(3, (_) => TextEditingController());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DialogoLlaves(
        banco: banco,
        controladores: controladores,
        onGuardar: () async {
          final llaves = controladores
              .where((c) => c.text.trim().isNotEmpty)
              .map((c) => c.text.trim())
              .toList();

          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'llave',
            llaves: llaves,
          );

          await ref.read(bancoControllerProvider.notifier).crearBanco(bancoCompleto);

          if (mounted) {
            Navigator.pop(dialogContext); // Cierra diálogo llaves
            UIHelpers.showSuccessSnackBar(
              context: context,
              message: 'Banco "${banco.nombre}" vinculado exitosamente.',
            );
          }
        },
      ),
    );
  }

  // ============================================================================
  // EDICIÓN DE BANCOS
  // ============================================================================

  void _mostrarDialogoEditar(BuildContext context, BancoModelo banco) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';

    if (userId.isEmpty) {
      UIHelpers.showErrorSnackBar(context: context, message: 'Usuario no autenticado.');
      return;
    }

    if (banco.tipoIdentificador == 'cuenta') {
      _mostrarDialogoNumeroCuentaEdicion(context, banco, userId);
    } else {
      _mostrarDialogoLlavesEdicion(context, banco, userId);
    }
  }

  /// Editar número de cuenta
  void _mostrarDialogoNumeroCuentaEdicion(
      BuildContext context, BancoModelo banco, String userId) {
    final controladorCuenta = TextEditingController();

    if (banco.numeroCuenta != null) {
      controladorCuenta.text = banco.numeroCuenta!;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DialogoNumeroCuenta(
        banco: banco,
        controladorCuenta: controladorCuenta,
        onGuardar: () async {
          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'cuenta',
            numeroCuenta: controladorCuenta.text.trim(),
          );

          await ref.read(bancoControllerProvider.notifier).actualizarBanco(bancoCompleto);

          if (mounted) {
            Navigator.pop(dialogContext); // Cierra diálogo de cuenta
            UIHelpers.showSuccessSnackBar(
              context: context,
              message: 'Cuenta bancaria actualizada correctamente.',
            );
          }
        },
      ),
    );
  }

  /// Editar llaves
  void _mostrarDialogoLlavesEdicion(
      BuildContext context, BancoModelo banco, String userId) {
    final controladores = List.generate(3, (_) => TextEditingController());

    if (banco.llaves != null) {
      for (int i = 0; i < banco.llaves!.length && i < 3; i++) {
        controladores[i].text = banco.llaves![i];
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DialogoLlaves(
        banco: banco,
        controladores: controladores,
        onGuardar: () async {
          final llaves = controladores
              .where((c) => c.text.trim().isNotEmpty)
              .map((c) => c.text.trim())
              .toList();

          final bancoCompleto = banco.copyWith(
            tipoIdentificador: 'llave',
            llaves: llaves,
          );

          await ref.read(bancoControllerProvider.notifier).actualizarBanco(bancoCompleto);

          if (mounted) {
            Navigator.pop(dialogContext); // Cierra diálogo llaves
            UIHelpers.showSuccessSnackBar(
              context: context,
              message: 'Llaves actualizadas correctamente.',
            );
          }
        },
      ),
    );
  }

  // ============================================================================
  // ELIMINACIÓN DE CUENTA VINCULADA
  // ============================================================================

  Future<void> _eliminarBanco(String bancoId, String userId, String nombreBanco) async {
    if (!mounted) return;
    UIHelpers.showLoadingDialog(context, message: 'Desvinculado cuenta...');

    try {
      await ref.read(bancoControllerProvider.notifier).eliminarBanco(bancoId, userId);
      
      if (mounted) {
        UIHelpers.hideLoadingDialog(context);
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: 'Banco "$nombreBanco" desvinculado correctamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.hideLoadingDialog(context);
        UIHelpers.showErrorSnackBar(
          context: context,
          message: e.toString(),
        );
      }
    }
  }
}
