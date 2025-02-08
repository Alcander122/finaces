import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
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
      body: SafeArea(
        child: portafolios.when(
          data: (portafolios) {
            final total = portafolios.isEmpty
                ? 0.0
                : portafolios.fold(0.0, (sum, item) => sum + item.valor);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(total, context),
                  const Divider(height: 32),
                  _buildPortfolioList(portafolios, user.uid, context, ref),
                  const SizedBox(height: 24),
                  PortafolioChart(portafolios: portafolios),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text("Error: ${error.toString()}")),
        ),
      ),
    );
  }

  Widget _buildHeader(double total, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen General',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inversión Total:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioList(List<Portafolio> portafolios, String userId,
      BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portafolios Activos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: portafolios.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final portafolio = portafolios[index];
              return _buildPortfolioItem(portafolio, userId, context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(Portafolio portafolio, String userId,
      BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(
        portafolio.nombre,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.attach_money, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${portafolio.valor.toStringAsFixed(2)} ${portafolio.moneda}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.category, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                portafolio.categoria,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon:
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PortafolioFormScreen(
                  userId: userId,
                  portafolio: portafolio,
                ),
              ),
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            onPressed: () => ref
                .read(portafolioServiceProvider)
                .eliminarPortafolio(userId, portafolio.id),
          ),
        ],
      ),
    );
  }
}
