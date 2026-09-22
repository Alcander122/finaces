import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/Pagos/models/payment.dart';
import 'package:finances/presentations/screens/Pagos/models/payment_enums.dart';
import 'package:finances/presentations/screens/Pagos/providers/payment_providers.dart';
import 'package:finances/presentations/screens/Pagos/services/notification_service.dart';
import 'package:finances/presentations/screens/home/providers/home_providers.dart';
import 'package:finances/presentations/screens/home/widgets/bento/home_bento_grid.dart';
import 'package:finances/presentations/screens/home/widgets/home_balance_card.dart';
import 'package:finances/presentations/screens/home/widgets/home_header.dart';
import 'package:finances/presentations/screens/home/widgets/home_quick_actions.dart';
import 'package:finances/presentations/screens/home/widgets/home_smart_tip.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/smart_ad_banner.dart';

// Re-exportamos los providers de la pantalla de inicio por compatibilidad
export 'package:finances/presentations/screens/home/providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF26A69A)),
              const SizedBox(height: 20),
              Text(
                'Cargando...',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final userId = authState.user?.uid ?? '';

    // Autocargar y sincronizar notificaciones en segundo plano al iniciar la app o tras una actualización
    if (userId.isNotEmpty) {
      ref.listen<AsyncValue<List<Payment>>>(
        paymentsStreamProvider(userId),
        (previous, next) {
          if (ref.read(hasSyncedNotificationsProvider)) return;

          next.whenData((pagos) async {
            ref.read(hasSyncedNotificationsProvider.notifier).state = true;
            final scheduler = ref.read(paymentSchedulerProvider);
            for (final pago in pagos) {
              if (pago.status == PaymentStatus.pending) {
                await scheduler.syncPaymentNotifications(pago);
              }
            }
          });
        },
      );

      // Solicitar permisos de notificación de forma segura una vez que la pantalla y el contexto de la app estén listos
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!ref.read(hasRequestedPermissionsProvider)) {
          ref.read(hasRequestedPermissionsProvider.notifier).state = true;
          await NotificationService().requestPermissions();
        }
      });
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Stack(
        children: [
          // 1. Aurora Radial Superior Derecha (Azul profundo neón)
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF003366).withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006699).withValues(alpha: 0.2),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // 2. Aurora Radial Inferior Izquierda (Púrpura suave)
          Positioned(
            bottom: -200,
            left: -200,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5D3FD3).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A2BE2).withValues(alpha: 0.08),
                    blurRadius: 180,
                    spreadRadius: 70,
                  ),
                ],
              ),
            ),
          ),
          // 3. Contenido Principal Scrollable y Modular
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // A. Cabecera (Saludo, fecha, toggles de tema/saldo, notificaciones y perfil)
                const SliverToBoxAdapter(
                  child: HomeHeader(),
                ),

                // B. Tarjeta "Plata Disponible" y métricas interactivas
                const SliverToBoxAdapter(
                  child: HomeBalanceCard(),
                ),

                // C. Acciones Rápidas (Botón Unificado de Movimientos y Estadísticas)
                const SliverToBoxAdapter(
                  child: HomeQuickActions(),
                ),

                // D. Mosaico Bento Grid ("Mi Panel")
                SliverToBoxAdapter(
                  child: HomeBentoGrid(userId: userId),
                ),

                // E. Consejo Financiero Inteligente
                const SliverToBoxAdapter(
                  child: HomeSmartTip(),
                ),

                // F. Banner Publicitario Inteligente
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SmartAdBanner(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
