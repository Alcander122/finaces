import 'package:finances/presentations/screens/portafolio/portafolio_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/widgets/portafolio_chart.dart';

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
                        trailing: Text(
                          portafolio.descripcion ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
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
