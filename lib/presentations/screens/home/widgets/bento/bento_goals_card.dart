import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/ahorro_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/Ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/theme/theme.dart';

class BentoGoalsCard extends ConsumerWidget {
  const BentoGoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metasAsync = ref.watch(metasAhorroProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AhorroScreen()),
        );
      },
      child: HomeGlassmorphicCard(
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: metasAsync.when(
          data: (metas) {
            if (metas.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ahorros y Bolsillos',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const FaIcon(FontAwesomeIcons.piggyBank,
                          color: Color(0xFFFFB74D), size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Organiza tus metas y cajitas',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tienes metas activas aún',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca aquí para separar tu primer ahorro.',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.45),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }

            final principalMeta = metas.first;
            final progresoPercent = principalMeta.progreso / 100.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ahorros y Bolsillos',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const FaIcon(FontAwesomeIcons.piggyBank,
                        color: Color(0xFFFFB74D), size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Progreso de tu meta activa principal',
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      principalMeta.nombre,
                      style: TextStyle(
                        color: context.colors.onSurface.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${principalMeta.progreso.toStringAsFixed(0)}% completado',
                      style: const TextStyle(
                        color: Color(0xFFFFB74D),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresoPercent,
                    minHeight: 5,
                    backgroundColor:
                        context.colors.onSurface.withValues(alpha: 0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${UIHelpers.formatCurrency(principalMeta.montoActual)} de ${UIHelpers.formatCurrency(principalMeta.montoObjetivo)}',
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFFB74D),
              ),
            ),
          ),
          error: (err, _) => Text(
            'Error al cargar metas',
            style: TextStyle(
              color: context.colors.onSurface.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
