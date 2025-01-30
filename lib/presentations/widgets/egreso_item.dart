import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EgresoItem extends ConsumerWidget {
  final Egreso egreso;

  const EgresoItem({super.key, required this.egreso});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final egresoService = ref.read(egresoServiceProvider);

    return ListTile(
      title: Text(egreso.concepto),
      subtitle: Text('${egreso.valor} - ${egreso.estado}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EgresoForm(egreso: egreso),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await egresoService.eliminarEgreso(egreso.id, user.uid);
              }
            },
          ),
        ],
      ),
    );
  }
}
