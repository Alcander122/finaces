import 'package:finances/presentations/screens/portafolio/portafolio_detail_screen.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portafolio_chart.dart';
import 'package:finances/core/data/services/portafolio_service.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

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
      appBar: const AppBarFinances(
        title: 'Mis Portafolios',
        showProfileIcon: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PortafolioFormScreen(userId: user.uid),
            ),
          ),
          child: const Icon(Icons.add),
        ),
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
                  child: portafoliosList.isEmpty
                      ? const Center(
                          child: Text(
                            'No tienes portafolios registrados.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 80,
                              ),
                              itemCount: portafoliosList.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final portafolio = portafoliosList[index];
                                final total = investmentsList
                                    .where((inv) =>
                                        inv.portafolioId == portafolio.id)
                                    .fold(0.0,
                                        (sum, inv) => sum + inv.invMensual);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PortafolioDetailScreen(
                                          portafolio: portafolio,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 12.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.folder,
                                              color: Colors.blueGrey),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  portafolio.nombre,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Total: ${UIHelpers.formatCurrency(total)}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      "Eliminar Portafolio"),
                                                  content: const Text(
                                                      "¿Deseas eliminar este portafolio?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                          "Cancelar"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                          "Eliminar"),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                await PortafolioService()
                                                    .eliminarPortafolio(
                                                        user.uid,
                                                        portafolio.id);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Error al cargar inversiones: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text("Error al cargar portafolios: $error")),
      ),
    );
  }
}
