import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/payment_provider.dart';
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
import 'package:finances/presentations/widgets/smart_ad_banner.dart';

// Provider local para controlar la privacidad del saldo
final isBalancePrivateProvider = StateProvider<bool>((ref) => false);

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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E14),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF26A69A)),
              SizedBox(height: 20),
              Text('Cargando...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final totalIngresosAsync = ref.watch(totalIngresosMesActualProvider);
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);
    final saldoAsync = ref.watch(saldoDisponibleProvider);
    final isPrivate = ref.watch(isBalancePrivateProvider);
    final userId = authState.user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
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
                                style: const TextStyle(
                                  color: Colors.white,
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
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isPrivate
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white70,
                                size: 22,
                              ),
                              onPressed: () {
                                ref.read(isBalancePrivateProvider.notifier).state =
                                    !isPrivate;
                              },
                              tooltip: isPrivate ? 'Mostrar saldo' : 'Ocultar saldo',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                UIHelpers.showInfoSnackBar(
                                    context: context,
                                    message: 'No tienes nuevas alertas financieras');
                              },
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white10,
                                  child: Icon(Icons.person_outline_rounded,
                                      color: Colors.white70, size: 20),
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
                            children: const [
                              Text(
                                'PLATA DISPONIBLE',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Icon(Icons.account_balance_wallet_outlined,
                                  color: Colors.white38, size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          saldoAsync.when(
                            data: (saldo) => Text(
                              isPrivate ? '••••••••' : UIHelpers.formatCurrency(saldo),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            loading: () => const SizedBox(
                              height: 40,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Color(0xFF26A69A))),
                            ),
                            error: (e, _) => Text(
                              r'$-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '↑ +12% respecto al mes anterior',
                            style: TextStyle(
                              color: Color(0xFF26A69A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(
                                  label: 'Ingresos',
                                  amountAsync: totalIngresosAsync,
                                  isIncome: true,
                                  isPrivate: isPrivate,
                                ),
                              ),
                              Container(width: 1, height: 35, color: Colors.white10),
                              Expanded(
                                child: _buildMiniStat(
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
                        const Text(
                          'Mi Panel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

                        if (gastos == 0) {
                          consejoText = '¡Bienvenido a tu panel de control! Registra tus primeros movimientos con los botones de arriba para activar tus métricas y consejos personalizados.';
                          bulbColor = const Color(0xFFFFB74D);
                        } else if (ingresos == 0) {
                          consejoText = 'Has registrado ${UIHelpers.formatCurrency(gastos)} en gastos, pero aún no tienes ingresos este mes. ¡Agrega un ingreso para ver tu balance real!';
                          bulbColor = const Color(0xFFEF5350);
                        } else {
                          final ratio = (gastos / ingresos) * 100;
                          if (ratio > 80) {
                            consejoText = 'Alerta: Has consumido el ${ratio.toStringAsFixed(0)}% de tus ingresos este mes. Te recomendamos pausar gastos no esenciales.';
                            bulbColor = const Color(0xFFEF5350);
                          } else if (ratio > 50) {
                            consejoText = 'Atención: Has consumido el ${ratio.toStringAsFixed(0)}% de tus ingresos este mes. Procura vigilar tus egresos diarios.';
                            bulbColor = const Color(0xFFFFB74D);
                          } else {
                            consejoText = '¡Excelente ritmo! Has consumido solo el ${ratio.toStringAsFixed(0)}% de tus ingresos. Mantienes un control financiero impecable.';
                            bulbColor = const Color(0xFF26A69A);
                          }
                        }

                        return _GlassmorphicCard(
                          padding: const EdgeInsets.all(16.0),
                          borderRadius: 16.0,
                          backgroundColor: const Color(0x06FFFFFF),
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
                                  style: const TextStyle(
                                    color: Color(0xB2FFFFFF),
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

  Widget _buildMiniStat({
    required String label,
    required AsyncValue<double> amountAsync,
    required bool isIncome,
    required bool isPrivate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isIncome ? const Color(0xFF26A69A) : const Color(0xFFEF5350),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          amountAsync.when(
            data: (amount) => Text(
              isPrivate ? '••••' : UIHelpers.formatCurrency(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30),
            ),
            error: (_, __) => const Text(r'$-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
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
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xE2FFFFFF),
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
                    children: const [
                      Text(
                        'Ahorros y Bolsillos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(FontAwesomeIcons.piggyBank, color: Color(0xFFFFB74D), size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Organiza tus metas y cajitas',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No tienes metas activas aún',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toca aquí para separar tu primer ahorro.',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
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
                  children: const [
                    Text(
                      'Ahorros y Bolsillos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(FontAwesomeIcons.piggyBank, color: Color(0xFFFFB74D), size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Progreso de tu meta activa principal',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      principalMeta.nombre,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
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
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${UIHelpers.formatCurrency(principalMeta.montoActual)} de ${UIHelpers.formatCurrency(principalMeta.montoObjetivo)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            );
          },
          loading: () => const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB74D)))),
          error: (err, _) => const Text(
            'Error al cargar metas',
            style: TextStyle(color: Colors.white38, fontSize: 11),
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
                    children: const [
                      Text(
                        'Mis Bancos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(FontAwesomeIcons.buildingColumns, color: Color(0xFF64B5F6), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Datos para cobrar',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const Spacer(),
                  const Text(
                    'Sin cuentas',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Toca para agregar',
                    style: TextStyle(color: Colors.white30, fontSize: 8),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(FontAwesomeIcons.buildingColumns, color: Color(0xFF64B5F6), size: 14),
                  ],
                ),
                const SizedBox(height: 25),
                const Text(
                  'Datos para cobrar',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
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
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 10),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        identificador,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
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
          error: (_, __) => const Text(
            'Error',
            style: TextStyle(color: Colors.white30, fontSize: 10),
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
                    children: const [
                      Text(
                        'Portafolio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(FontAwesomeIcons.chartLine, color: Color(0xFF66BB6A), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tus inversiones',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const Spacer(),
                  const Text(
                    'Sin inversiones',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Toca para agregar',
                    style: TextStyle(color: Colors.white30, fontSize: 8),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Portafolio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(FontAwesomeIcons.chartLine, color: Color(0xFF66BB6A), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total valorizado',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  UIHelpers.formatCurrency(dashboardState.totalPortfolioValueCOP),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${dashboardState.numberOfAssets} activos',
                  style: const TextStyle(color: Colors.white60, fontSize: 9),
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
          error: (_, __) => const Text(
            'Error',
            style: TextStyle(color: Colors.white30, fontSize: 10),
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
                    children: const [
                      Text(
                        '¿En qué gasté?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(FontAwesomeIcons.chartPie, color: Color(0xFFAB47BC), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Categorías del mes',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const Spacer(),
                  const Text(
                    'Sin gastos aún',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Toca para registrar',
                    style: TextStyle(color: Colors.white30, fontSize: 8),
                  ),
                ],
              );
            }

            final totalGastos = egresosMesActual.fold(0.0, (sum, e) => sum + e.valor);
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
                  children: const [
                    Text(
                      '¿En qué gasté?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(FontAwesomeIcons.chartPie, color: Color(0xFFAB47BC), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Categorías del mes',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
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
                            style: const TextStyle(color: Colors.white60, fontSize: 9),
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
          error: (_, __) => const Text(
            'Error',
            style: TextStyle(color: Colors.white30, fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoPayments(BuildContext context, WidgetRef ref, String userId) {
    final paymentsAsync = ref.watch(paymentProvider(userId));

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
            final activePagos = pagos.where((p) => p.estaProgramado).toList();

            if (activePagos.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Pagos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(FontAwesomeIcons.calendarCheck, color: Color(0xFFE57373), size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Próximos cobros',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const Spacer(),
                  const Text(
                    'Sin cobros',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Toca para agregar',
                    style: TextStyle(color: Colors.white30, fontSize: 8),
                  ),
                ],
              );
            }

            activePagos.sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));
            final proximoPago = activePagos.first;
            final diasFaltantes = proximoPago.fechaVencimiento.difference(DateTime.now()).inDays;
            final vencimientoText = diasFaltantes == 0
                ? 'Vence hoy'
                : (diasFaltantes == 1 ? 'Vence mañana' : 'Vence en $diasFaltantes días');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Pagos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(FontAwesomeIcons.calendarCheck, color: Color(0xFFE57373), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Próximo vencimiento',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  proximoPago.descripcion,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  UIHelpers.formatCurrency(proximoPago.monto),
                  style: const TextStyle(color: Color(0xFFE57373), fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  vencimientoText,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
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
          error: (_, __) => const Text(
            'Error al cargar',
            style: TextStyle(color: Colors.white38, fontSize: 10),
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
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double? height;

  const _GlassmorphicCard({
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.borderOpacity = 0.1,
    this.backgroundColor = const Color(0x0DFFFFFF),
    this.padding = const EdgeInsets.all(20.0),
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: borderOpacity),
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
