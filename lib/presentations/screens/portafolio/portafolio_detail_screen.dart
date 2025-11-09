import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/core/data/services/investment_service.dart';
import 'package:finances/presentations/screens/portafolio/investment_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/widgets/investment_chart.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';
import 'package:finances/core/data/utils/ui_helpers.dart'; // Importa UIHelpers.

class PortafolioDetailScreen extends ConsumerWidget {
  final Portafolio portafolio;

  const PortafolioDetailScreen({super.key, required this.portafolio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref
        .watch(investmentsProvider(Tuple2(portafolio.userId, portafolio.id)));

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
          title: portafolio.nombre,
          showProfileIcon: false,
          actions: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PortafolioFormScreen(
                              userId: portafolio.userId,
                              portafolio: portafolio)));
                }),
          ]),
      body: investments.when(
        data: (investmentsList) => Column(
          children: [
            InvestmentChart(investments: investmentsList),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Inversiones",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey))),
            ),
            Expanded(
              child: investmentsList.isEmpty
                  ? const Center(
                      child: Text('No hay inversiones registradas.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: investmentsList.length,
                      itemBuilder: (context, index) {
                        final investment = investmentsList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              title: Text(investment.descripcion,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${UIHelpers.formatCurrency(investment.invMensual)} ${investment.moneda}',
                                  style: const TextStyle()), // Usa UIHelpers.
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    InvestmentFormScreen(
                                                        userId:
                                                            portafolio.userId,
                                                        portafolioId:
                                                            portafolio.id,
                                                        investment:
                                                            investment)),
                                          )),
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirm = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                "Eliminar Inversión"),
                                            content: const Text(
                                                "¿Estás seguro de que deseas eliminar esta inversión?"),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child:
                                                      const Text("Cancelar")),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child:
                                                      const Text("Eliminar")),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await InvestmentService()
                                              .eliminarInvestment(
                                                  portafolio.userId,
                                                  portafolio.id,
                                                  investment.id);
                                        }
                                      }),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error al cargar datos: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => InvestmentFormScreen(
                    userId: portafolio.userId, portafolioId: portafolio.id))),
        child: const Icon(Icons.add),
      ),
    );
  }
}
