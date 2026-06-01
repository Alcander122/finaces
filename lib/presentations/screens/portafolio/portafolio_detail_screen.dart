import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/presentations/screens/portafolio/investment_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/widgets/investment_chart.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tuple/tuple.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

class PortafolioDetailScreen extends ConsumerWidget {
  final Portafolio portafolio;

  const PortafolioDetailScreen({super.key, required this.portafolio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(
      portfolioDetailProvider(Tuple2(portafolio.userId, portafolio.id)),
    );

    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        title: portafolio.nombre,
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            color: Colors.white,
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
        ],
      ),
      body: investmentsAsync.when(
        data: (investmentsList) {
          if (investmentsList.isEmpty) {
            return const Center(
              child: Text(
                'No hay inversiones registradas.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          Widget buildInvestmentList(bool isTablet) {
            return ListView.builder(
              shrinkWrap: isTablet,
              physics: isTablet ? const ClampingScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              itemCount: investmentsList.length,
              itemBuilder: (context, index) {
                final item = investmentsList[index];
                final investment = item.investment;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        investment.descripcion,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${UIHelpers.formatCurrency(investment.invMensual)} ${investment.moneda}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (investment.moneda.toUpperCase() != 'COP') ...[
                            const SizedBox(height: 2),
                            Text(
                              '≈ ${UIHelpers.formatCurrency(item.convertedValueCOP)} COP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvestmentFormScreen(
                                  userId: portafolio.userId,
                                  portafolioId: portafolio.id,
                                  investment: investment,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:
                                      const Text("Eliminar Inversión"),
                                  content: const Text(
                                      "¿Estás seguro de que deseas eliminar esta inversión?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Eliminar"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                try {
                                  await ref
                                      .read(investmentServiceProvider)
                                      .eliminarInvestment(
                                        portafolio.userId,
                                        portafolio.id,
                                        investment.id,
                                      );
                                  if (context.mounted) {
                                    UIHelpers.showSuccessSnackBar(
                                      context: context,
                                      message: 'Inversión eliminada con éxito',
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
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                // Splitview para tablet
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: InvestmentChart(investments: investmentsList),
                      ),
                    ),
                    const VerticalDivider(width: 0.5, thickness: 0.5, color: Colors.grey),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Inversiones",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ),
                          Expanded(child: buildInvestmentList(true)),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Vertical layout para móvil
                return Column(
                  children: [
                    InvestmentChart(investments: investmentsList),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Inversiones",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: buildInvestmentList(false)),
                  ],
                );
              }
            },
          );
        },
        loading: () => const InvestmentShimmerLoading(),
        error: (error, _) {
          final friendlyError = DbErrorHandler.handle(error);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                '${ErrorStrings.loadFailed}\n($friendlyError)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvestmentFormScreen(
              userId: portafolio.userId,
              portafolioId: portafolio.id,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class InvestmentShimmerLoading extends StatelessWidget {
  const InvestmentShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const SizedBox(height: 220, width: double.infinity),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


