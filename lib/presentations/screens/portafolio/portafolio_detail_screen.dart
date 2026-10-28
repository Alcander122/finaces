import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';
import 'package:finances/presentations/screens/portafolio/investment_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/investment_simulator_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/widgets/currency_trm_indicator.dart';
import 'package:finances/presentations/screens/portafolio/widgets/delete_confirmation_dialog.dart';
import 'package:finances/presentations/screens/portafolio/widgets/investment_chart.dart';
import 'package:finances/presentations/screens/portafolio/widgets/investment_item_card.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portafolio_shimmer_loading.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portfolio_empty_state.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portfolio_kpi_header.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';

class PortafolioDetailScreen extends ConsumerWidget {
  final Portafolio portafolio;

  const PortafolioDetailScreen({super.key, required this.portafolio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(
      portfolioDetailProvider(Tuple2(portafolio.userId, portafolio.id)),
    );

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBarFinances(
        title: portafolio.nombre,
        showProfileIcon: false,
        actions: [
          Semantics(
            label: PortafolioStrings.simuladorTooltip,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.auto_graph_rounded),
              color: Colors.white,
              tooltip: PortafolioStrings.simuladorTooltip,
              onPressed: () {
                final items = investmentsAsync.value ?? [];
                final hasForeign = items.any(
                  (i) =>
                      i.investment.moneda.toUpperCase() == 'USD' ||
                      i.investment.moneda.toUpperCase() == 'EUR',
                );
                final foreignCurrency = items.any(
                        (i) => i.investment.moneda.toUpperCase() == 'EUR')
                    ? 'EUR'
                    : 'USD';
                final totalCOP =
                    items.fold(0.0, (sum, i) => sum + i.convertedValueCOP);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvestmentSimulatorScreen(
                      initialCapital: totalCOP > 0 ? totalCOP : null,
                      investmentTitle: portafolio.nombre,
                      hasForeignCurrency: hasForeign,
                      currency: hasForeign ? foreignCurrency : 'COP',
                    ),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: PortafolioStrings.editarPortafolioTooltip,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: Colors.white,
              tooltip: PortafolioStrings.editarPortafolioTooltip,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PortafolioFormScreen(
                      userId: portafolio.userId,
                      portafolio: portafolio,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Semantics(
        label: PortafolioStrings.nuevaInversionBtn,
        button: true,
        child: FloatingActionButton.extended(
          elevation: 4,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvestmentFormScreen(
                userId: portafolio.userId,
                portafolioId: portafolio.id,
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            PortafolioStrings.nuevaInversionBtn,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: investmentsAsync.when(
        data: (investmentsList) {
          final totalCOP =
              investmentsList.fold(0.0, (sum, i) => sum + i.convertedValueCOP);

          return Column(
            children: [
              const CurrencyTrmIndicator(compact: true),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 1050;
                    final isTablet =
                        constraints.maxWidth >= 650 && constraints.maxWidth < 1050;

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: investmentsList.isEmpty
                            ? PortfolioEmptyState(
                                headerWidget: PortfolioDetailHeaderCard(
                                  portafolio: portafolio,
                                  totalCOP: 0.0,
                                  count: 0,
                                ),
                                icon: Icons.trending_up_rounded,
                                title: PortafolioStrings.emptyInversionTitle,
                                description:
                                    PortafolioStrings.emptyInversionDesc(portafolio.nombre),
                                buttonLabel: PortafolioStrings.emptyInversionBtn,
                                onButtonPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InvestmentFormScreen(
                                      userId: portafolio.userId,
                                      portafolioId: portafolio.id,
                                    ),
                                  ),
                                ),
                              )
                            : isDesktop
                                ? _buildDesktopLayout(
                                    context, ref, investmentsList, totalCOP)
                                : isTablet
                                    ? _buildTabletLayout(
                                        context, ref, investmentsList, totalCOP)
                                    : _buildMobileLayout(
                                        context, ref, investmentsList, totalCOP),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const InvestmentShimmerLoading(),
        error: (error, _) {
          final friendlyError = DbErrorHandler.handle(error);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: context.colors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    '${ErrorStrings.loadFailed}\n($friendlyError)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.error, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 📱 MOBILE LAYOUT (<650px)
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    List<InvestmentItemState> investments,
    double totalCOP,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortfolioDetailHeaderCard(
            portafolio: portafolio,
            totalCOP: totalCOP,
            count: investments.length,
          ),
          const SizedBox(height: 16),
          if (totalCOP > 0) ...[
            InvestmentChart(investments: investments),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              PortafolioStrings.inversionesCount(investments.length),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.titleColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: investments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return InvestmentItemCard(
                portafolio: portafolio,
                item: investments[index],
                totalCOP: totalCOP,
                onDelete: () => _confirmarEliminacionInversion(
                  context,
                  ref,
                  investments[index].investment.id,
                  investments[index].investment.descripcion,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 💻 TABLET LAYOUT (650px - 1050px)
  // ===========================================================================
  Widget _buildTabletLayout(
    BuildContext context,
    WidgetRef ref,
    List<InvestmentItemState> investments,
    double totalCOP,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortfolioDetailHeaderCard(
            portafolio: portafolio,
            totalCOP: totalCOP,
            count: investments.length,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (totalCOP > 0)
                Expanded(
                  flex: 5,
                  child: InvestmentChart(investments: investments),
                ),
              if (totalCOP > 0) const SizedBox(width: 16),
              Expanded(
                flex: totalCOP > 0 ? 5 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        PortafolioStrings.inversionesCount(investments.length),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: investments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return InvestmentItemCard(
                          portafolio: portafolio,
                          item: investments[index],
                          totalCOP: totalCOP,
                          onDelete: () => _confirmarEliminacionInversion(
                            context,
                            ref,
                            investments[index].investment.id,
                            investments[index].investment.descripcion,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🖥️ DESKTOP LAYOUT (>=1050px)
  // ===========================================================================
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    List<InvestmentItemState> investments,
    double totalCOP,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 28, right: 28, top: 24, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortfolioDetailHeaderCard(
            portafolio: portafolio,
            totalCOP: totalCOP,
            count: investments.length,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (totalCOP > 0)
                Expanded(
                  flex: 4,
                  child: InvestmentChart(investments: investments),
                ),
              if (totalCOP > 0) const SizedBox(width: 24),
              Expanded(
                flex: totalCOP > 0 ? 6 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        PortafolioStrings.inversionesPortafolioCount(investments.length),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 175,
                      ),
                      itemCount: investments.length,
                      itemBuilder: (context, index) {
                        return InvestmentItemCard(
                          portafolio: portafolio,
                          item: investments[index],
                          totalCOP: totalCOP,
                          onDelete: () => _confirmarEliminacionInversion(
                            context,
                            ref,
                            investments[index].investment.id,
                            investments[index].investment.descripcion,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminacionInversion(
    BuildContext context,
    WidgetRef ref,
    String investmentId,
    String descripcion,
  ) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: PortafolioStrings.eliminarInversionDialogTitle,
      message: PortafolioStrings.eliminarInversionDialogMsg(descripcion),
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(investmentServiceProvider).eliminarInvestment(
              portafolio.userId,
              portafolio.id,
              investmentId,
            );
        if (context.mounted) {
          UIHelpers.showSuccessSnackBar(
            context: context,
            message: PortafolioStrings.inversionEliminadaExito,
          );
        }
      } catch (error) {
        if (context.mounted) {
          final friendlyError = DbErrorHandler.handle(error);
          UIHelpers.showErrorSnackBar(
            context: context,
            message: friendlyError,
          );
        }
      }
    }
  }
}
