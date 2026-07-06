import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../providers/payment_providers.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/themes.dart';

class PaymentSummaryHeader extends ConsumerWidget {
  final String userId;
  final bool isVertical;

  const PaymentSummaryHeader({
    super.key,
    required this.userId,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(paymentStatsProvider(userId));

    final cards = [
      _SummaryCard(
        title: 'Pendiente del Mes',
        value: UIHelpers.formatCurrency(stats.pendingMonth),
        icon: Icons.access_time_filled,
        iconColor: Colors.amber.shade700,
        backgroundColor: Colors.amber.withValues(alpha: 0.1),
      ),
      _SummaryCard(
        title: 'Pagado del Mes',
        value: UIHelpers.formatCurrency(stats.paidMonth),
        icon: Icons.check_circle,
        iconColor: Colors.green,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
      ),
      _SummaryCard(
        title: 'Pagos Vencidos',
        value: UIHelpers.formatCurrency(stats.overdueTotal),
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
      ),
      _SummaryCard(
        title: 'Próximos 7 días',
        value: '${stats.upcomingCount} recordatorio${stats.upcomingCount == 1 ? '' : 's'}',
        icon: Icons.notifications_active,
        iconColor: Colors.blue,
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
      ),
    ];

    if (isVertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 24) / 2;
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: cards.map((card) {
            return SizedBox(
              width: cardWidth > 140 ? cardWidth : double.infinity,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AutoSizeText(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    minFontSize: 9,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Themes.primary,
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
