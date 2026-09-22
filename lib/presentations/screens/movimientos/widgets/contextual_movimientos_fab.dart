import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finances/presentations/screens/egreso/egreso_form.dart';
import 'package:finances/presentations/screens/ingresos/Ingreso_form.dart';

class ContextualMovimientosFab extends StatelessWidget {
  final TabController tabController;

  const ContextualMovimientosFab({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        final isGastos = tabController.index == 0;
        final themeColor =
            isGastos ? const Color(0xFFEF5350) : const Color(0xFF26A69A);
        final labelText = isGastos ? 'Nuevo Gasto' : 'Nuevo Ingreso';
        const iconData = Icons.add_rounded;

        return FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.lightImpact();
            if (isGastos) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EgresoForm(egreso: null),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IngresoForm(ingreso: null),
                ),
              );
            }
          },
          backgroundColor: themeColor,
          elevation: 4,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              iconData,
              key: ValueKey<int>(tabController.index),
              color: Colors.white,
              size: 20,
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Text(
              labelText,
              key: ValueKey<String>(labelText),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      },
    );
  }
}
