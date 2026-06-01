import 'package:finances/core/data/services/ingresos_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_card.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingresos_empty_state.dart';
import 'package:finances/presentations/screens/ingresos/widgets/ingreso_form_bottom_sheet.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:intl/intl.dart';
import 'package:finances/presentations/theme/themes.dart';

class IngresosDashboardScreen extends ConsumerWidget {
  const IngresosDashboardScreen({super.key});

  void _mostrarFormulario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const IngresoFormBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchar errores u operaciones fallidas en segundo plano
    ref.listen<AsyncValue<void>>(
      ingresosControllerProvider,
      (_, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
    );

    // Consumimos el Stream de ingresos (Asegúrate de que este sea el nombre correcto de tu provider de lista)
    final ingresosAsync = ref.watch(ingresosFiltradosProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mis Ingresos',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Themes.degradientLight, Themes.degradientDark],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeaderKPI(context, ref, ingresosAsync),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40.0),
                      topRight: Radius.circular(40.0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40.0),
                      topRight: Radius.circular(40.0),
                    ),
                    child: CustomScrollView(
                      slivers: [
                        ingresosAsync.when(
                          data: (ingresos) => ingresos.isEmpty
                              ? const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: IngresosEmptyState(),
                                )
                              : SliverPadding(
                                  padding: const EdgeInsets.only(
                                      top: 20, bottom: 80),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (_, index) =>
                                          IngresoCard(ingreso: ingresos[index]),
                                      childCount: ingresos.length,
                                    ),
                                  ),
                                ),
                          loading: () => const SliverFillRemaining(
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.green))),
                          error: (err, _) => SliverFillRemaining(
                              child: Center(
                                  child: Text('Error al cargar ingresos:\n$err',
                                      textAlign: TextAlign.center,
                                      style:
                                          const TextStyle(color: Colors.red)))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context),
        backgroundColor: Colors.green.shade600,
        elevation: 3,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ingreso',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Construye la tarjeta superior (Header KPI) con el total calculado dinámicamente
  Widget _buildHeaderKPI(BuildContext context, WidgetRef ref,
      AsyncValue<List<Ingreso>> ingresosAsync) {
    // Calculamos el total de la lista cargada (si hay datos)
    final double total = ingresosAsync.maybeWhen(
      data: (ingresos) => ingresos.fold(0.0, (sum, item) => sum + item.valor),
      orElse: () => 0.0,
    );

    final formatCurrency =
        NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Total Ingresos',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatCurrency.format(total),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
