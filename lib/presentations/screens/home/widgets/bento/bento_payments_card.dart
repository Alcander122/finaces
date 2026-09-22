import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/Pagos/models/payment_enums.dart';
import 'package:finances/presentations/screens/Pagos/pagos_screen.dart';
import 'package:finances/presentations/screens/Pagos/providers/payment_providers.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/theme/theme.dart';

class BentoPaymentsCard extends ConsumerWidget {
  final String userId;

  const BentoPaymentsCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsStreamProvider(userId));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PagosScreen()),
        );
      },
      child: HomeGlassmorphicCard(
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: paymentsAsync.when(
          data: (pagos) {
            final activePagos = pagos
                .where((p) =>
                    p.recurrence.unit != FrequencyUnit.none &&
                    p.nextDueDate != null)
                .toList();

            if (activePagos.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pagos',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const FaIcon(
                        FontAwesomeIcons.calendarCheck,
                        color: Color(0xFFE57373),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Próximos cobros',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sin cobros',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Toca para agregar',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.4),
                      fontSize: 8,
                    ),
                  ),
                ],
              );
            }

            activePagos.sort(
                (a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
            final proximoPago = activePagos.first;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final dueDate = proximoPago.nextDueDate!;
            final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
            final diasFaltantes = due.difference(today).inDays;

            final vencimientoText = diasFaltantes < 0
                ? 'Vencido'
                : diasFaltantes == 0
                    ? 'Vence hoy'
                    : (diasFaltantes == 1
                        ? 'Vence mañana'
                        : 'Vence en $diasFaltantes días');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pagos',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const FaIcon(
                      FontAwesomeIcons.calendarCheck,
                      color: Color(0xFFE57373),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Próximo vencimiento',
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  proximoPago.title.isNotEmpty
                      ? proximoPago.title
                      : proximoPago.description,
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  UIHelpers.formatCurrency(proximoPago.totalAmount),
                  style: const TextStyle(
                    color: Color(0xFFE57373),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  vencimientoText,
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE57373),
              ),
            ),
          ),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pagos',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const FaIcon(
                    FontAwesomeIcons.calendarCheck,
                    color: Color(0xFFE57373),
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Próximos cobros',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                'Sin cobros',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Toca para agregar',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.6),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
