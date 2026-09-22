import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/theme_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/home/providers/home_providers.dart';
import 'package:finances/presentations/theme/theme.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${weekdays[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isPrivate = ref.watch(isBalancePrivateProvider);
    final themeMode = ref.watch(themeProvider);

    return Padding(
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
                    color: context.colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Sol/Luna: alterna entre modo claro y oscuro
              IconButton(
                tooltip: themeMode == ThemeMode.dark
                    ? 'Cambiar a modo claro'
                    : 'Cambiar a modo oscuro',
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: context.colors.onSurface.withValues(alpha: 0.8),
                  size: 21,
                ),
                onPressed: () {
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
                  ref.read(isBalancePrivateProvider.notifier).state = !isPrivate;
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
                    message: 'No tienes nuevas alertas financieras',
                  );
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
                    backgroundColor:
                        context.colors.onSurface.withValues(alpha: 0.08),
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
    );
  }
}
