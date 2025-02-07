import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/widgets/portafolio_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Portafolios")),
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
        data: (portafolios) => Column(
          children: [
            PortafolioChart(portafolios: portafolios),
            Expanded(
              child: ListView.builder(
                itemCount: portafolios.length,
                itemBuilder: (context, index) {
                  final portafolio = portafolios[index];
                  return ListTile(
                    title: Text(portafolio.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Valor: ${portafolio.valor.toStringAsFixed(2)} ${portafolio.moneda}"),
                        Text("Categoría: ${portafolio.categoria}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PortafolioFormScreen(
                                userId: user.uid,
                                portafolio: portafolio,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => ref
                              .read(portafolioServiceProvider)
                              .eliminarPortafolio(user.uid, portafolio.id),
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
        error: (error, _) => Center(child: Text("Error: ${error.toString()}")),
      ),
    );
  }
}
