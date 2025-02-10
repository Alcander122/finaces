import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/core/data/services/investment_service.dart';
import 'package:finances/presentations/screens/portafolio/investment_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/widgets/portafolio_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

class PortafolioDetailScreen extends ConsumerWidget {
  final Portafolio portafolio;

  const PortafolioDetailScreen({super.key, required this.portafolio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref
        .watch(investmentsProvider(Tuple2(portafolio.userId, portafolio.id)));

    return Scaffold(
      appBar: AppBar(
        title: Text(portafolio.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PortafolioFormScreen(
                  userId: portafolio.userId,
                  portafolio: portafolio,
                ),
              ),
            ),
          ),
        ],
      ),
      body: investments.when(
        data: (investmentsList) => Column(
          children: [
            PortafolioChart(
              investments: investmentsList,
              portfolios: [portafolio],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: investmentsList.length,
                itemBuilder: (context, index) {
                  final investment = investmentsList[index];
                  return ListTile(
                    title: Text(
                        '${investment.invMensual.toStringAsFixed(2)} ${investment.moneda}'),
                    subtitle: Text(investment.descripcion),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvestmentFormScreen(
                                userId: portafolio.userId,
                                portafolioId: portafolio.id,
                                investment: investment,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await InvestmentService().eliminarInvestment(
                              portafolio.userId,
                              portafolio.id,
                              investment.userId,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvestmentFormScreen(
              userId: portafolio.userId,
              portafolioId: portafolio.id,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
