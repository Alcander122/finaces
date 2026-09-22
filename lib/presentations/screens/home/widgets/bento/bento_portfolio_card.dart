import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/theme/theme.dart';

class BentoPortfolioCard extends ConsumerWidget {
  final String userId;

  const BentoPortfolioCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioDashboardProvider(userId));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PortafolioScreen()),
        );
      },
      child: HomeGlassmorphicCard(
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: portfolioAsync.when(
          data: (dashboardState) {
            final items = dashboardState.portfolioItems;

            if (items.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Portafolio',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const FaIcon(
                        FontAwesomeIcons.chartLine,
                        color: Color(0xFF66BB6A),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tus inversiones',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sin inversiones',
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
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portafolio',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const FaIcon(
                      FontAwesomeIcons.chartLine,
                      color: Color(0xFF66BB6A),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Total valorizado',
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  UIHelpers.formatCurrency(
                      dashboardState.totalPortfolioValueCOP),
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${dashboardState.numberOfAssets} activos',
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.75),
                    fontSize: 9.5,
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
                color: Color(0xFF66BB6A),
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
                    'Portafolio',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const FaIcon(
                    FontAwesomeIcons.chartLine,
                    color: Color(0xFF66BB6A),
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Tus inversiones',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                'Sin inversiones',
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
