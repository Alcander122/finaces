import 'package:finances/presentations/screens/portafolio/portafolio_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portafolio_chart.dart';
import 'package:finances/core/data/services/portafolio_service.dart';
import 'package:finances/presentations/theme/themes.dart';

class PortafolioScreen extends ConsumerWidget {
  const PortafolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Debe iniciar sesión primero")),
      );
    }

    final portafolios = ref.watch(portafoliosProvider(user.uid));
    final investments = ref.watch(allInvestmentsProvider(user.uid));

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBar(
        title: const Text("Mis Portafolios"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PortafolioFormScreen(userId: user.uid),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: portafolios.when(
        data: (portafoliosList) => investments.when(
          data: (investmentsList) {
            return Column(
              children: [
                PortafolioChart(
                  investments: investmentsList,
                  portfolios: portafoliosList,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: portafoliosList.length,
                    itemBuilder: (context, index) {
                      final portafolio = portafoliosList[index];
                      final total = investmentsList
                          .where((inv) => inv.portafolioId == portafolio.id)
                          .fold(0.0, (sum, inv) => sum + inv.invMensual);
                      return ListTile(
                        title: Text(portafolio.nombre),
                        subtitle: Text('Total: \$${total.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                // Mostrar diálogo de confirmación
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Eliminar Portafolio"),
                                    content: const Text(
                                        "¿Estás seguro de que deseas eliminar este portafolio?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancelar"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Eliminar"),
                                      ),
                                    ],
                                  ),
                                );

                                // Si el usuario confirma, eliminar el portafolio
                                if (confirm == true) {
                                  await PortafolioService().eliminarPortafolio(
                                      user.uid, portafolio.id);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PortafolioDetailScreen(
                              portafolio: portafolio,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("Error: ${error.toString()}")),
      ),
    );
  }
}
