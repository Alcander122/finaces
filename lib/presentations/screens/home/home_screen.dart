import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/theme_provider.dart'; // Provider del tema claro/oscuro
import 'package:finances/presentations/screens/Pagos/providers/payment_providers.dart';
import 'package:finances/presentations/screens/Pagos/models/payment_enums.dart';
import 'package:finances/presentations/screens/Pagos/models/payment.dart';
import 'package:finances/presentations/screens/Pagos/services/notification_service.dart';
import 'package:finances/core/data/providers/ahorro_provider.dart';
import 'package:finances/core/data/providers/Bank_provider.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/Ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/Bancos/banks_screen.dart';
import 'package:finances/presentations/screens/Egreso/egresos_screen.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/Pagos/pagos_screen.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
import 'package:finances/presentations/screens/ingresos/ingresos_screen.dart';
import 'package:finances/presentations/theme/theme.dart'; // Extensión context.colors
import 'package:finances/presentations/widgets/smart_ad_banner.dart';

// Provider local para controlar la privacidad del saldo
final isBalancePrivateProvider = StateProvider<bool>((ref) => false);

// Provider local para controlar si ya se sincronizaron las notificaciones en la sesión actual
final hasSyncedNotificationsProvider = StateProvider<bool>((ref) => false);

// Provider local para controlar si ya se solicitaron los permisos de notificación en esta sesión
final hasRequestedPermissionsProvider = StateProvider<bool>((ref) => false);

// Provider combinado para el cálculo automático y determinístico del Saldo Disponible
final saldoDisponibleProvider = Provider<AsyncValue<double>>((ref) {
  final ingresosAsync = ref.watch(totalIngresosMesActualProvider);
  final egresosAsync = ref.watch(totalEgresoMesActualProvider);

  return ingresosAsync.when(
    data: (ingresos) => egresosAsync.when(
      data: (egresos) => AsyncValue.data(ingresos - egresos),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// Provider que calcula la variación porcentual con respecto al mes anterior
final variacionSaldoMesAnteriorProvider = Provider<AsyncValue<double?>>((ref) {
  final ingresosActualAsync = ref.watch(totalIngresosMesActualProvider);
  final egresosActualAsync = ref.watch(totalEgresoMesActualProvider);
  final ingresosAnteriorAsync = ref.watch(totalIngresosMesAnteriorProvider);
  final egresosAnteriorAsync = ref.watch(totalEgresoMesAnteriorProvider);

  if (ingresosActualAsync.isLoading ||
      egresosActualAsync.isLoading ||
      ingresosAnteriorAsync.isLoading ||
      egresosAnteriorAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final ingresosActual = ingresosActualAsync.value ?? 0.0;
  final egresosActual = egresosActualAsync.value ?? 0.0;
  final saldoActual = ingresosActual - egresosActual;

  final ingresosAnterior = ingresosAnteriorAsync.value ?? 0.0;
  final egresosAnterior = egresosAnteriorAsync.value ?? 0.0;
  final saldoAnterior = ingresosAnterior - egresosAnterior;

  // Si en el mes actual no hay movimientos registrados (0 ingresos y 0 gastos),
  // o si no hubo saldo en el mes anterior, no aplica porcentaje de variación.
  if ((ingresosActual == 0.0 && egresosActual == 0.0) || saldoAnterior == 0.0) {
    return const AsyncValue.data(null);
  }

  final variacion =
      ((saldoActual - saldoAnterior) / saldoAnterior.abs()) * 100.0;
  return AsyncValue.data(variacion);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      // Fondo adaptativo: usa el color 'surface' del tema activo
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF26A69A)),
              const SizedBox(height: 20),
              // Texto adaptativo según el tema
              Text('Cargando...', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        ),
      );
    }

    final totalIngresosAsync = ref.watch(totalIngresosMesActualProvider);
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);
    final saldoAsync = ref.watch(saldoDisponibleProvider);
    final variacionAsync = ref.watch(variacionSaldoMesAnteriorProvider);
    final isPrivate = ref.watch(isBalancePrivateProvider);
    final userId = authState.user?.uid ?? '';
    // Lee el modo de tema activo (claro u oscuro)
    final themeMode = ref.watch(themeProvider);

    // Autocargar y sincronizar notificaciones en segundo plano al iniciar la app o tras una actualización
    if (userId.isNotEmpty) {
      ref.listen<AsyncValue<List<Payment>>>(paymentsStreamProvider(userId), (previous, next) {
        if (ref.read(hasSyncedNotificationsProvider)) return;

        next.whenData((pagos) async {
          // Marcar como sincronizado para evitar ciclos infinitos en esta sesión
          ref.read(hasSyncedNotificationsProvider.notifier).state = true;
          
          final scheduler = ref.read(paymentSchedulerProvider);
          for (final pago in pagos) {
            if (pago.status == PaymentStatus.pending) {
              await scheduler.syncPaymentNotifications(pago);
            }
          }
        });
      });

      // Solicitar permisos de notificación de forma segura una vez que la pantalla y el contexto de la app estén listos
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!ref.read(hasRequestedPermissionsProvider)) {
          ref.read(hasRequestedPermissionsProvider.notifier).state = true;
          await NotificationService().requestPermissions();
        }
      });
    }

    return Scaffold(
      // El fondo toma el color 'surface' del tema activo (claro o  oscuro)
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
          // 3. Contenido Principal Scrollable
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // A. Premium Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola, ${authState.user?.displayName ?? 'Usuario'}! 👋',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  // Color adaptativo: blanco en oscuro, oscuro en claro
                                  color: context.colors.onSurface,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getFormattedDate(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  // Color secundario adaptativo al 60% de opacidad
                                  color: context.colors.onSurface.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Fila de acciones del header
                        // Se usan constraints reducidos (36x36) para que los 4 botones
                        // quepan cómodamente en pantallas pequeñas (ej. iPhone SE, 320px)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón Sol/Luna: alterna entre modo claro y oscuro
                            IconButton(
                              tooltip: themeMode == ThemeMode.dark
                                  ? 'Cambiar a modo claro'
                                  : 'Cambiar a modo oscuro',
                              // Reduce el área de toque de 48x48 (default) a 36x36
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                themeMode == ThemeMode.dark
                                    ? Icons.light_mode_outlined  // Sol → pasar a claro
                                    : Icons.dark_mode_outlined,  // Luna → pasar a oscuro
                                color: context.colors.onSurface.withValues(alpha: 0.8),
                                size: 21,
                              ),
                              onPressed: () {
                                // Alterna y guarda la preferencia del usuario
                                ref.read(themeProvider.notifier).toggleTheme();
                              },
                            ),
                            // Botón visibilidad del saldo
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPrivate
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.colors.onSurface.withValues(alpha: 0.8),
                                size: 21,
                              ),
                              onPressed: () {
                                ref.read(isBalancePrivateProvider.notifier).state =
                                    !isPrivate;
                              },
                              tooltip: isPrivate ? 'Mostrar saldo' : 'Ocultar saldo',
                            ),
                            // Botón notificaciones
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.notifications_none_rounded,
                                color: context.colors.onSurface.withValues(alpha: 0.8),
                                size: 22,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                UIHelpers.showInfoSnackBar(
                                    context: context,
                                    message: 'No tienes nuevas alertas financieras');
                              },
                            ),
                            const SizedBox(width: 2),
                            // Avatar → perfil
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.colors.onSurface.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: context.colors.onSurface.withValues(alpha: 0.08),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: context.colors.onSurface.withValues(alpha: 0.7),
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // B. Tarjeta "Resumen Financiero"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: _GlassmorphicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: context.colors.onSurface.withValues(alpha: 0.5),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PLATA DISPONIBLE',
                                    style: TextStyle(
                                      color: context.colors.onSurface.withValues(alpha: 0.65),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              // Botón de privacidad interactivo integrado en la tarjeta
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(isBalancePrivateProvider.notifier).state = !isPrivate;
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    isPrivate
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: context.colors.onSurface.withValues(alpha: 0.5),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          saldoAsync.when(
                            data: (saldo) => Text(
                              isPrivate ? '••••••••' : UIHelpers.formatCurrency(saldo),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: (saldo < 0 && !isPrivate)
                                    ? const Color(0xFFEF5350)
                                    : context.colors.onSurface,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            loading: () => const SizedBox(
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF26A69A),
                                ),
                              ),
                            ),
                            error: (e, _) => Text(
                              r'$-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.onSurface,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildVariationBadge(context, variacionAsync, saldoAsync),
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: context.colors.onSurface.withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(
                                  context: context,
                                  label: 'Ingresos',
                                  amountAsync: totalIngresosAsync,
                                  isIncome: true,
                                  isPrivate: isPrivate,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 38,
                                color: context.colors.onSurface.withValues(alpha: 0.08),
                              ),
                              Expanded(
                                child: _buildMiniStat(
                                  context: context,
                                  label: 'Gastos',
                                  amountAsync: totalGastosAsync,
                                  isIncome: false,
                                  isPrivate: isPrivate,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // C. Acciones Rápidas
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _actionButton(
                            context: context,
                            label: '💸 Mis Gastos',
                            icon: FontAwesomeIcons.minus,
                            color: const Color(0xFFEF5350),
                            screen: const EgresosScreen(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            context: context,
                            label: '💰 Mis Ingresos',
                            icon: FontAwesomeIcons.plus,
                            color: const Color(0xFF26A69A),
                            screen: const IngresosScreen(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            context: context,
                            label: '📊 Estadísticas',
                            icon: FontAwesomeIcons.chartPie,
                            color: const Color(0xFFAB47BC),
                            screen: const StatisticScreen(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // D. Mosaico Bento Grid
                SliverToBoxAdapter(
                  child: Padding(
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

                        _buildBentoGoals(context, ref),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: SizedBox(height: 125, child: _buildBentoBanks(context, ref, userId))),
                            const SizedBox(width: 16),
                            Expanded(child: SizedBox(height: 125, child: _buildBentoPortfolio(context, ref, userId))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: SizedBox(height: 125, child: _buildBentoStatsVisual(context, ref))),
                            const SizedBox(width: 16),
                            Expanded(child: SizedBox(height: 125, child: _buildBentoPayments(context, ref, userId))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // E. Consejo Inteligente
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: totalGastosAsync.when(
                      data: (gastos) {
                        final ingresos = totalIngresosAsync.value ?? 0.0;
                        final String consejoText;
                        final Color bulbColor;

                        if (gastos == 0 && ingresos == 0) {
                          consejoText = '¡Bienvenido a tu panel de control! Registra tus primeros movimientos con los botones de arriba para activar tus métricas y consejos personalizados.';
                          bulbColor = const Color(0xFFFFB74D);
                        } else if (gastos == 0 && ingresos > 0) {
                          consejoText = '¡Excelente inicio! Has registrado ${UIHelpers.formatCurrency(ingresos)} en ingresos y aún no tienes gastos este mes. ¡Sigue así!';
                          bulbColor = const Color(0xFF26A69A);
                        } else if (ingresos == 0 && gastos > 0) {
                          consejoText = 'Has registrado ${UIHelpers.formatCurrency(gastos)} en gastos, pero aún no registras ingresos este mes. ¡Agrega tus ingresos para ver tu balance real!';
                          bulbColor = const Color(0xFFEF5350);
                        } else {
                          final ratio = (gastos / ingresos) * 100;
                          if (ratio > 100) {
                            consejoText = 'Alerta de déficit: Tus gastos superan tus ingresos en un ${ratio.toStringAsFixed(0)}% este mes. Te sugerimos moderar egresos no esenciales.';
                            bulbColor = const Color(0xFFEF5350);
                          } else if (ratio > 80) {
                            consejoText = 'Atención: Has consumido el ${ratio.toStringAsFixed(0)}% de tus ingresos este mes. Te recomendamos pausar gastos no esenciales.';
                            bulbColor = const Color(0xFFFF7043);
                          } else if (ratio > 50) {
                            consejoText = 'Moderado: Has consumido el ${ratio.toStringAsFixed(0)}% de tus ingresos este mes. Procura vigilar tus egresos diarios.';
                            bulbColor = const Color(0xFFFFB74D);
                          } else {
                            consejoText = '¡Excelente ritmo! Has consumido solo el ${ratio.toStringAsFixed(0)}% de tus ingresos. Mantienes un control financiero impecable.';
                            bulbColor = const Color(0xFF26A69A);
                          }
                        }

                        return _GlassmorphicCard(
                          padding: const EdgeInsets.all(16.0),
                          borderRadius: 16.0,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: bulbColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: bulbColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  consejoText,
                                  style: TextStyle(
                                    color: context.colors.onSurface.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),

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

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${weekdays[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]}';
  }

  Widget _buildVariationBadge(
    BuildContext context,
    AsyncValue<double?> variacionAsync,
    AsyncValue<double> saldoAsync,
  ) {
    return saldoAsync.when(
      data: (saldo) {
        return variacionAsync.when(
          data: (variacion) {
            if (variacion != null) {
              final isPositive = variacion >= 0;
              final color = isPositive
                  ? const Color(0xFF26A69A)
                  : const Color(0xFFEF5350);
              final icon = isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded;
              final sign = isPositive ? '+' : '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withValues(alpha: 0.25), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$sign${variacion.toStringAsFixed(1)}% respecto al mes anterior',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Si no hay variación calculable o es mes inicial
            final isZero = saldo == 0;
            final badgeColor = isZero
                ? context.colors.onSurface.withValues(alpha: 0.45)
                : const Color(0xFF26A69A);
            final badgeText = isZero
                ? '● Sin movimientos este mes'
                : '● Balance del mes activo';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: badgeColor.withValues(alpha: 0.2), width: 1),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniStat({
    required BuildContext context,
    required String label,
    required AsyncValue<double> amountAsync,
    required bool isIncome,
    required bool isPrivate,
  }) {
    final themeColor =
        isIncome ? const Color(0xFF26A69A) : const Color(0xFFEF5350);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Micro-contenedor circular translúcido
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: themeColor,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                amountAsync.when(
                  data: (amount) => Text(
                    isPrivate ? '••••' : UIHelpers.formatCurrency(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  error: (_, __) => Text(
                    r'$-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required dynamic icon,
    required Color color,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: _GlassmorphicCard(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        borderRadius: 16.0,
        backgroundColor: context.isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.8),
        child: Column(
          children: [
            icon is FaIconData
                ? FaIcon(icon, color: color, size: 18)
                : Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGoals(BuildContext context, WidgetRef ref) {
    final metasAsync = ref.watch(metasAhorroProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AhorroScreen()));
      },
      child: _GlassmorphicCard(
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: metasAsync.when(
          data: (metas) {
            if (metas.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ahorros y Bolsillos',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const FaIcon(FontAwesomeIcons.piggyBank, color: Color(0xFFFFB74D), size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Organiza tus metas y cajitas',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tienes metas activas aún',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca aquí para separar tu primer ahorro.',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.45), fontSize: 10),
                  ),
                ],
              );
            }

            final principalMeta = metas.first;
            final progresoPercent = principalMeta.progreso / 100.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ahorros y Bolsillos',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const FaIcon(FontAwesomeIcons.piggyBank, color: Color(0xFFFFB74D), size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Progreso de tu meta activa principal',
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      principalMeta.nombre,
                      style: TextStyle(
                          color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${principalMeta.progreso.toStringAsFixed(0)}% completado',
                      style: const TextStyle(
                          color: Color(0xFFFFB74D), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresoPercent,
                    minHeight: 5,
                    backgroundColor: context.colors.onSurface.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${UIHelpers.formatCurrency(principalMeta.montoActual)} de ${UIHelpers.formatCurrency(principalMeta.montoObjetivo)}',
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 10),
                ),
              ],
            );
          },
          loading: () => const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB74D)))),
          error: (err, _) => Text(
            'Error al cargar metas',
            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.45), fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoBanks(BuildContext context, WidgetRef ref, String userId) {
    final userBanksAsync = ref.watch(userBanksProvider(userId));

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaBancos()));
      },
      child: _GlassmorphicCard(
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: userBanksAsync.when(
          data: (bancos) {
            if (bancos.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mis Bancos',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const FaIcon(FontAwesomeIcons.buildingColumns, color: Color(0xFF64B5F6), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Datos para cobrar',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    'Sin cuentas',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Toca para agregar',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.4), fontSize: 8),
                  ),
                ],
              );
            }

            final primerBanco = bancos.first;
            final identificador = primerBanco.tipoIdentificador == 'cuenta'
                ? (primerBanco.numeroCuenta ?? 'S/N')
                : (primerBanco.llaves != null && primerBanco.llaves!.isNotEmpty ? primerBanco.llaves!.first : 'S/N');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        primerBanco.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const FaIcon(FontAwesomeIcons.buildingColumns, color: Color(0xFF64B5F6), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Datos para cobrar',
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
                ),
                const Spacer(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: identificador));
                        ScaffoldMessenger.of(context).clearSnackBars();
                        UIHelpers.showSuccessSnackBar(
                            context: context,
                            message: '¡Datos de ${primerBanco.nombre} ($identificador) copiados al portapapeles!');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.colors.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.copy_rounded, color: context.colors.onSurface.withValues(alpha: 0.7), size: 10),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        identificador,
                        style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF64B5F6)))),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Bancos',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const FaIcon(FontAwesomeIcons.buildingColumns, color: Color(0xFF64B5F6), size: 14),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Datos para cobrar',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
              ),
              const Spacer(),
              Text(
                'Sin cuentas',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                'Toca para agregar',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6), fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoPortfolio(BuildContext context, WidgetRef ref, String userId) {
    final portfolioAsync = ref.watch(portfolioDashboardProvider(userId));

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PortafolioScreen()));
      },
      child: _GlassmorphicCard(
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
                      const FaIcon(FontAwesomeIcons.chartLine, color: Color(0xFF66BB6A), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tus inversiones',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    'Sin inversiones',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Toca para agregar',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6), fontSize: 8),
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
                    const FaIcon(FontAwesomeIcons.chartLine, color: Color(0xFF66BB6A), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Total valorizado',
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
                ),
                const Spacer(),
                Text(
                  UIHelpers.formatCurrency(dashboardState.totalPortfolioValueCOP),
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
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 9.5),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF66BB6A)),
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
                  const FaIcon(FontAwesomeIcons.chartLine, color: Color(0xFF66BB6A), size: 14),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Tus inversiones',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
              ),
              const Spacer(),
              Text(
                'Sin inversiones',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                'Toca para agregar',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6), fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoStatsVisual(BuildContext context, WidgetRef ref) {
    final egresosAsync = ref.watch(egresosProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticScreen()));
      },
      child: _GlassmorphicCard(
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: egresosAsync.when(
          data: (egresos) {
            final now = DateTime.now();
            final egresosMesActual = egresos.where((e) => e.fecha.month == now.month && e.fecha.year == now.year).toList();

            if (egresosMesActual.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '¿En qué gasté?',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const FaIcon(FontAwesomeIcons.chartPie, color: Color(0xFFAB47BC), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Categorías del mes',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    'Sin gastos aún',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Toca para registrar',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6), fontSize: 8),
                  ),
                ],
              );
            }

            final totalGastos = egresosMesActual.fold(0.0, (total, e) => total + e.valor);
            final Map<String, double> gastosPorCategoria = {};
            for (var e in egresosMesActual) {
              gastosPorCategoria[e.categoria] = (gastosPorCategoria[e.categoria] ?? 0.0) + e.valor;
            }

            final sortedCategories = gastosPorCategoria.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final topCategories = sortedCategories.take(2).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¿En qué gasté?',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const FaIcon(FontAwesomeIcons.chartPie, color: Color(0xFFAB47BC), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Categorías del mes',
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
                ),
                const Spacer(),
                ...List.generate(topCategories.length, (index) {
                  final cat = topCategories[index];
                  final percent = (cat.value / totalGastos) * 100;
                  final Color circleColor = index == 0 ? const Color(0xFFEF5350) : const Color(0xFF64B5F6);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${cat.key} ${percent.toStringAsFixed(0)}%',
                            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 9.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFAB47BC)),
            ),
          ),
          error: (_, __) => Text(
            'Error',
            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.4), fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoPayments(BuildContext context, WidgetRef ref, String userId) {
    final paymentsAsync = ref.watch(paymentsStreamProvider(userId));

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PagosScreen()));
      },
      child: _GlassmorphicCard(
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20.0,
        child: paymentsAsync.when(
          data: (pagos) {
            final activePagos = pagos
                .where((p) => p.recurrence.unit != FrequencyUnit.none && p.nextDueDate != null)
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
                      const FaIcon(FontAwesomeIcons.calendarCheck, color: Color(0xFFE57373), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Próximos cobros',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    'Sin cobros',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Toca para agregar',
                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.4), fontSize: 8),
                  ),
                ],
              );
            }

            activePagos.sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
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
                    : (diasFaltantes == 1 ? 'Vence mañana' : 'Vence en $diasFaltantes días');

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
                    const FaIcon(FontAwesomeIcons.calendarCheck, color: Color(0xFFE57373), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Próximo vencimiento',
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
                ),
                const Spacer(),
                Text(
                  proximoPago.title.isNotEmpty ? proximoPago.title : proximoPago.description,
                  style: TextStyle(color: context.colors.onSurface, fontSize: 12.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  UIHelpers.formatCurrency(proximoPago.totalAmount),
                  style: const TextStyle(color: Color(0xFFE57373), fontSize: 12, fontWeight: FontWeight.bold),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE57373)))),
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
                  const FaIcon(FontAwesomeIcons.calendarCheck, color: Color(0xFFE57373), size: 14),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Próximos cobros',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 10),
              ),
              const Spacer(),
              Text(
                'Sin cobros',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                'Toca para agregar',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6), fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CONTENEDOR GLASSMORPHIC AUXILIAR ---
class _GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double borderOpacity;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double? height;

  const _GlassmorphicCard({
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.borderOpacity = 0.1,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(20.0),
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final defaultBg = isDark
        ? const Color(0x0DFFFFFF)
        : Colors.white.withValues(alpha: 0.9);
    final cardBg = backgroundColor ?? defaultBg;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: borderOpacity)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isDark ? 30 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
