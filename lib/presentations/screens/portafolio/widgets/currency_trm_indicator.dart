import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';

/// Widget que muestra el indicador de TRM en tiempo real con fecha/hora de actualización
/// y un botón interactivo para forzar la actualización manual.
class CurrencyTrmIndicator extends ConsumerStatefulWidget {
  final bool compact;

  const CurrencyTrmIndicator({
    super.key,
    this.compact = false,
  });

  @override
  ConsumerState<CurrencyTrmIndicator> createState() => _CurrencyTrmIndicatorState();
}

class _CurrencyTrmIndicatorState extends ConsumerState<CurrencyTrmIndicator> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await ref
          .read(exchangeRatesStateProvider.notifier)
          .loadRates(forceRefresh: true);

      if (mounted) {
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: PortafolioStrings.trmActualizadaExito,
        );
      }
    } catch (_) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
          context: context,
          message: PortafolioStrings.trmActualizadaError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratesStateAsync = ref.watch(exchangeRatesStateProvider);

    return ratesStateAsync.when(
      data: (ratesData) {
        final usdFormatted = UIHelpers.formatCurrency(ratesData.usdToCop);
        final eurFormatted = UIHelpers.formatCurrency(ratesData.eurToCop);
        final timeFormat = DateFormat('d MMM, HH:mm', 'es');
        final formattedDate = timeFormat.format(ratesData.lastUpdated);

        final textColor = context.colors.onSurfaceVariant;
        final chipBg = context.isDarkMode
            ? context.colors.surfaceContainerHigh.withAlpha(200)
            : const Color(0xFFF1F5F9);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.outlineVariant.withAlpha(80),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.currency_exchange_rounded,
                size: widget.compact ? 14 : 16,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      'USD: $usdFormatted',
                      style: TextStyle(
                        fontSize: widget.compact ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      'EUR: $eurFormatted',
                      style: TextStyle(
                        fontSize: widget.compact ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${PortafolioStrings.trmActualizado} $formattedDate',
                          style: TextStyle(
                            fontSize: widget.compact ? 10 : 11,
                            color: textColor,
                          ),
                        ),
                        if (ratesData.isFromCache) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              PortafolioStrings.trmEnCache,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                label: 'Actualizar tasas de cambio manualmente',
                button: true,
                child: InkWell(
                  onTap: _isRefreshing ? null : _handleRefresh,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: _isRefreshing
                        ? SizedBox(
                            width: widget.compact ? 12 : 14,
                            height: widget.compact ? 12 : 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.primary,
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: widget.compact ? 15 : 18,
                            color: context.colors.primary,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
