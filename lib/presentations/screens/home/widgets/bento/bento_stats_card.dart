import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/theme/theme.dart';

class BentoStatsCard extends ConsumerWidget {
  const BentoStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final egresosAsync = ref.watch(egresosProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticScreen()),
        );
      },
      child: HomeGlassmorphicCard(
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: egresosAsync.when(
          data: (egresos) {
            final now = DateTime.now();
            final egresosMesActual = egresos
                .where((e) =>
                    e.fecha.month == now.month && e.fecha.year == now.year)
                .toList();

            if (egresosMesActual.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '¿En qué gasté?',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const FaIcon(
                        FontAwesomeIcons.chartPie,
                        color: Color(0xFFAB47BC),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Categorías del mes',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sin gastos aún',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Toca para registrar',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 8,
                    ),
                  ),
                ],
              );
            }

            final totalGastos =
                egresosMesActual.fold(0.0, (total, e) => total + e.valor);
            final Map<String, double> gastosPorCategoria = {};
            for (var e in egresosMesActual) {
              gastosPorCategoria[e.categoria] =
                  (gastosPorCategoria[e.categoria] ?? 0.0) + e.valor;
            }

            final sortedCategories = gastosPorCategoria.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final topCategories = sortedCategories.take(2).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¿En qué gasté?',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const FaIcon(
                      FontAwesomeIcons.chartPie,
                      color: Color(0xFFAB47BC),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Categorías del mes',
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                ...List.generate(topCategories.length, (index) {
                  final cat = topCategories[index];
                  final percent = (cat.value / totalGastos) * 100;
                  final Color circleColor = index == 0
                      ? const Color(0xFFEF5350)
                      : const Color(0xFF64B5F6);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${cat.key} ${percent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: context.colors.onSurface
                                  .withValues(alpha: 0.75),
                              fontSize: 9.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFAB47BC),
              ),
            ),
          ),
          error: (_, __) => Text(
            'Error',
            style: TextStyle(
              color: context.colors.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
