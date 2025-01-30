import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:finances/presentations/widgets/egreso_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EgresosScreen extends ConsumerWidget {
  const EgresosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final egresosAsync = ref.watch(egresosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egresos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EgresoForm()),
              );
            },
          ),
        ],
      ),
      body: egresosAsync.when(
        data: (egresos) => ListView.builder(
          itemCount: egresos.length,
          itemBuilder: (context, index) {
            return EgresoItem(egreso: egresos[index]);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
