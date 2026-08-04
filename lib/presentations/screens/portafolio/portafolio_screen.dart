import 'package:finances/presentations/screens/portafolio/portafolio_detail_screen.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/widgets/portafolio_chart.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

class PortafolioScreen extends ConsumerWidget {
  const PortafolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Debe iniciar sesión primero")),
      );
    }

    final dashboardAsync = ref.watch(portfolioDashboardProvider(user.uid));

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: const AppBarFinances(
        title: 'Mis Portafolios',
        showProfileIcon: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PortafolioFormScreen(userId: user.uid),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: dashboardAsync.when(
        data: (dashboardState) {
          final items = dashboardState.portfolioItems;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No tienes portafolios registrados.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          Widget buildPortfolioList(bool isTablet) {
            return ListView.separated(
              shrinkWrap: isTablet,
              physics: isTablet ? const ClampingScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 80,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final portafolio = item.portafolio;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PortafolioDetailScreen(
                          portafolio: portafolio,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.folder,
                              color: Colors.blueGrey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  portafolio.nombre,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: context.isDarkMode ? context.colors.onSurface : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total: ${UIHelpers.formatCurrency(item.totalValueCOP)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.isDarkMode ? context.colors.onSurfaceVariant : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirm =
                                  await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    AlertDialog(
                                  title: const Text(
                                      "Eliminar Portafolio"),
                                  content: const Text(
                                      "¿Deseas eliminar este portafolio y todas sus inversiones asociadas?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, false),
                                      child: const Text(
                                          "Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, true),
                                      child: const Text(
                                          "Eliminar"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                try {
                                  await ref
                                      .read(portafolioServiceProvider)
                                      .eliminarPortafolio(
                                          user.uid,
                                          portafolio.id);
                                  if (context.mounted) {
                                    UIHelpers.showSuccessSnackBar(
                                      context: context,
                                      message: 'Portafolio eliminado con éxito',
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
                // Split horizontal layout para tablets y landscape
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: PortafolioChart(
                          totalValueCOP: dashboardState.totalPortfolioValueCOP,
                          portfolioItems: items,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 0.5, thickness: 0.5, color: Colors.grey),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: buildPortfolioList(true),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Layout vertical móvil estándar
                return Column(
                  children: [
                    PortafolioChart(
                      totalValueCOP: dashboardState.totalPortfolioValueCOP,
                      portfolioItems: items,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: buildPortfolioList(false),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          );
        },
        loading: () => const PortafolioShimmerLoading(),
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
    );
  }
}

class PortafolioShimmerLoading extends StatelessWidget {
  const PortafolioShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // Importación implícita de shimmer.dart
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
              4,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  height: 64,
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


