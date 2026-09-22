import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finances/core/data/providers/Bank_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/Bancos/banks_screen.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/theme/theme.dart';

class BentoBanksCard extends ConsumerWidget {
  final String userId;

  const BentoBanksCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBanksAsync = ref.watch(userBanksProvider(userId));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PantallaBancos()),
        );
      },
      child: HomeGlassmorphicCard(
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
                      const FaIcon(
                        FontAwesomeIcons.buildingColumns,
                        color: Color(0xFF64B5F6),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Datos para cobrar',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sin cuentas',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Toca para agregar',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.4),
                      fontSize: 8,
                    ),
                  ),
                ],
              );
            }

            final primerBanco = bancos.first;
            final identificador = primerBanco.tipoIdentificador == 'cuenta'
                ? (primerBanco.numeroCuenta ?? 'S/N')
                : (primerBanco.llaves != null && primerBanco.llaves!.isNotEmpty
                    ? primerBanco.llaves!.first
                    : 'S/N');

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
                    const FaIcon(
                      FontAwesomeIcons.buildingColumns,
                      color: Color(0xFF64B5F6),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Datos para cobrar',
                  style: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
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
                          message:
                              '¡Datos de ${primerBanco.nombre} ($identificador) copiados al portapapeles!',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              context.colors.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.copy_rounded,
                          color:
                              context.colors.onSurface.withValues(alpha: 0.7),
                          size: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        identificador,
                        style: TextStyle(
                          color: context.colors.onSurface
                              .withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF64B5F6),
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
                    'Mis Bancos',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const FaIcon(
                    FontAwesomeIcons.buildingColumns,
                    color: Color(0xFF64B5F6),
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Datos para cobrar',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                'Sin cuentas',
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
