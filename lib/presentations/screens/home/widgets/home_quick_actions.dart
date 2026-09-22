import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/screens/movimientos/movimientos_screen.dart';
import 'package:finances/presentations/theme/theme.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required dynamic icon,
    required Color color,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: HomeGlassmorphicCard(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        borderRadius: 16.0,
        backgroundColor: context.isDarkMode
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.8),
        child: Column(
          children: [
            icon is FaIconData
                ? FaIcon(icon, color: color, size: 18)
                : Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Unificado de Movimientos (Gastos e Ingresos con Tabs)
          Expanded(
            child: _actionButton(
              context: context,
              label: '💳 Movimientos',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF26A69A),
              screen: const MovimientosScreen(),
            ),
          ),
          const SizedBox(width: 12),
          // Botón de Estadísticas
          Expanded(
            child: _actionButton(
              context: context,
              label: '📊 Estadísticas',
              icon: FontAwesomeIcons.chartPie,
              color: const Color(0xFFAB47BC),
              screen: const StatisticScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
