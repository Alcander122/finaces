import 'package:flutter/material.dart';
import 'package:finances/presentations/screens/home/widgets/bento/bento_banks_card.dart';
import 'package:finances/presentations/screens/home/widgets/bento/bento_goals_card.dart';
import 'package:finances/presentations/screens/home/widgets/bento/bento_payments_card.dart';
import 'package:finances/presentations/screens/home/widgets/bento/bento_portfolio_card.dart';
import 'package:finances/presentations/screens/home/widgets/bento/bento_stats_card.dart';
import 'package:finances/presentations/theme/theme.dart';

class HomeBentoGrid extends StatelessWidget {
  final String userId;

  const HomeBentoGrid({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mi Panel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Fila 1: Metas y Ahorros principal
          const BentoGoalsCard(),
          const SizedBox(height: 16),

          // Fila 2: Mis Bancos y Portafolio
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 125,
                  child: BentoBanksCard(userId: userId),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 125,
                  child: BentoPortfolioCard(userId: userId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fila 3: Visual de Categorías y Próximos Pagos
          Row(
            children: [
              const Expanded(
                child: SizedBox(
                  height: 125,
                  child: BentoStatsCard(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 125,
                  child: BentoPaymentsCard(userId: userId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
