import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';
import 'package:finances/presentations/screens/portafolio/investment_simulator_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/widgets/currency_trm_indicator.dart';
import 'package:finances/presentations/screens/portafolio/widgets/delete_confirmation_dialog.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portafolio_chart.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portafolio_shimmer_loading.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portfolio_empty_state.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portfolio_item_card.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portfolio_kpi_header.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';

class PortafolioScreen extends ConsumerWidget {
  const PortafolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: context.scaffoldBgColor,
        body: const Center(
          child: Text(
            PortafolioStrings.iniciarSesionRequerido,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final dashboardAsync = ref.watch(portfolioDashboardProvider(user.uid));

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBarFinances(
        title: PortafolioStrings.misPortafoliosTitle,
        showProfileIcon: false,
        actions: [
          Semantics(
            label: PortafolioStrings.simuladorTooltip,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.calculate_outlined, color: Colors.white),
              tooltip: PortafolioStrings.simuladorTooltip,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InvestmentSimulatorScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Semantics(
        label: PortafolioStrings.nuevoPortafolioBtn,
        button: true,
        child: FloatingActionButton.extended(
          elevation: 4,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PortafolioFormScreen(userId: user.uid),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            PortafolioStrings.nuevoPortafolioBtn,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: dashboardAsync.when(
        data: (dashboardState) {
          final items = dashboardState.portfolioItems;

          if (items.isEmpty) {
            return Column(
              children: [
                const CurrencyTrmIndicator(),
                Expanded(
                  child: PortfolioEmptyState(
                    icon: Icons.pie_chart_outline_rounded,
                    title: PortafolioStrings.emptyPortafolioTitle,
                    description: PortafolioStrings.emptyPortafolioDesc,
                    buttonLabel: PortafolioStrings.emptyPortafolioBtn,
                    onButtonPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PortafolioFormScreen(userId: user.uid),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              const CurrencyTrmIndicator(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 1050;
                    final isTablet =
                        constraints.maxWidth >= 650 && constraints.maxWidth < 1050;

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: isDesktop
                            ? _buildDesktopLayout(context, ref, dashboardState, user.uid)
                            : isTablet
                                ? _buildTabletLayout(context, ref, dashboardState, user.uid)
                                : _buildMobileLayout(
                                    context,
                                    ref,
                                    dashboardState,
                                    user.uid,
                                    constraints.maxWidth,
                                  ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const PortafolioShimmerLoading(),
        error: (error, _) {
          final friendlyError = DbErrorHandler.handle(error);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: context.colors.error, size: 48),
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
    PortfolioDashboardState dashboardState,
    String userId,
    double screenWidth,
  ) {
    final items = dashboardState.portfolioItems;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortfolioKpiHeader(
            dashboardState: dashboardState,
            isSmallScreen: screenWidth < 360,
          ),
          const SizedBox(height: 16),
          if (dashboardState.totalPortfolioValueCOP > 0) ...[
            PortafolioChart(
              totalValueCOP: dashboardState.totalPortfolioValueCOP,
              portfolioItems: items,
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              PortafolioStrings.tusPortafoliosCount(items.length),
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
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return PortfolioItemCard(
                item: items[index],
                totalPortfolioValueCOP: dashboardState.totalPortfolioValueCOP,
                onDelete: () => _confirmarEliminacion(
                  context,
                  ref,
                  userId,
                  items[index].portafolio.id,
                  items[index].portafolio.nombre,
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
    PortfolioDashboardState dashboardState,
    String userId,
  ) {
    final items = dashboardState.portfolioItems;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortfolioKpiHeader(dashboardState: dashboardState),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dashboardState.totalPortfolioValueCOP > 0)
                Expanded(
                  flex: 5,
                  child: PortafolioChart(
                    totalValueCOP: dashboardState.totalPortfolioValueCOP,
                    portfolioItems: items,
                  ),
                ),
              if (dashboardState.totalPortfolioValueCOP > 0) const SizedBox(width: 16),
              Expanded(
                flex: dashboardState.totalPortfolioValueCOP > 0 ? 5 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        PortafolioStrings.portafoliosRegistradosCount(items.length),
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
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return PortfolioItemCard(
                          item: items[index],
                          totalPortfolioValueCOP: dashboardState.totalPortfolioValueCOP,
                          onDelete: () => _confirmarEliminacion(
                            context,
                            ref,
                            userId,
                            items[index].portafolio.id,
                            items[index].portafolio.nombre,
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
  // 🖥️ DESKTOP LAYOUT (>= 1050px)
  // ===========================================================================
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    PortfolioDashboardState dashboardState,
    String userId,
  ) {
    final items = dashboardState.portfolioItems;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 28, right: 28, top: 24, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortfolioKpiHeader(dashboardState: dashboardState),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dashboardState.totalPortfolioValueCOP > 0)
                Expanded(
                  flex: 4,
                  child: PortafolioChart(
                    totalValueCOP: dashboardState.totalPortfolioValueCOP,
                    portfolioItems: items,
                  ),
                ),
              if (dashboardState.totalPortfolioValueCOP > 0) const SizedBox(width: 24),
              Expanded(
                flex: dashboardState.totalPortfolioValueCOP > 0 ? 6 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        PortafolioStrings.portafoliosRegistradosCount(items.length),
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 160,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return PortfolioItemCard(
                          item: items[index],
                          totalPortfolioValueCOP: dashboardState.totalPortfolioValueCOP,
                          onDelete: () => _confirmarEliminacion(
                            context,
                            ref,
                            userId,
                            items[index].portafolio.id,
                            items[index].portafolio.nombre,
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

  Future<void> _confirmarEliminacion(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String portafolioId,
    String nombre,
  ) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: PortafolioStrings.eliminarPortafolioDialogTitle,
      message: PortafolioStrings.eliminarPortafolioDialogMsg(nombre),
    );

    if (confirmed && context.mounted) {
      try {
        await ref
            .read(portafolioServiceProvider)
            .eliminarPortafolio(userId, portafolioId);
        if (context.mounted) {
          UIHelpers.showSuccessSnackBar(
            context: context,
            message: PortafolioStrings.portafolioEliminadoExito,
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
