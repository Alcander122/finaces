// 🎨 presentations/screens/Bancos/widgets/DialogoTipoIdentificador.dart
// ============================================================================
// DIÁLOGO: Selección del tipo de cuenta bancaria (Número de cuenta o Llaves)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/theme/theme.dart';

class DialogoTipoIdentificador extends StatelessWidget {
  final BancoModelo banco;
  final Function(String) onTipoSeleccionado;

  const DialogoTipoIdentificador({
    super.key,
    required this.banco,
    required this.onTipoSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: context.dialogBgColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado Premium
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                color: Themes.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tipo de Identificador',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido descriptivo
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Selecciona el formato de vinculación para tu cuenta de "${banco.nombre}":',
                style: TextStyle(
                  color: context.isDarkMode
                      ? context.colors.onSurfaceVariant
                      : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Opciones táctiles premium
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Opción 1: Número de Cuenta
                  Card(
                    elevation: 0,
                    color: context.isDarkMode
                        ? context.colors.surfaceContainerLow
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: context.isDarkMode
                              ? Colors.white12
                              : Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Themes.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tag, color: Themes.primary, size: 20),
                      ),
                      title: Text(
                        'Número de Cuenta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.isDarkMode
                              ? context.colors.onSurface
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Ej: 10-20 dígitos numéricos tradicionales.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.isDarkMode
                              ? context.colors.onSurfaceVariant
                              : Colors.grey.shade600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onTipoSeleccionado('cuenta');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Opción 2: Llave Bancaria
                  Card(
                    elevation: 0,
                    color: context.isDarkMode
                        ? context.colors.surfaceContainerLow
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: context.isDarkMode
                              ? Colors.white12
                              : Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Themes.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.vpn_key_outlined,
                            color: Themes.primary, size: 20),
                      ),
                      title: Text(
                        'Llave Bancaria',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.isDarkMode
                              ? context.colors.onSurface
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Entre 1 y 3 llaves seguras de caracteres alfanuméricos.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.isDarkMode
                              ? context.colors.onSurfaceVariant
                              : Colors.grey.shade600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onTipoSeleccionado('llave');
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botón Cancelar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.colors.surfaceContainer
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                      color: context.isDarkMode
                          ? Colors.white10
                          : Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: context.isDarkMode
                            ? context.colors.onSurfaceVariant
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
