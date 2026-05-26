// 🎨 presentations/screens/Bancos/widgets/TarjetaBanco.dart
// ============================================================================
// WIDGET: Tarjeta de Banco de aspecto Fintech Premium con marca dinámica y acciones
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finances/presentations/screens/Bancos/widgets/qr_screen.dart';

/// Función para enmascarar cualquier identificador sensible de forma segura
String maskIdentifier(String? identifier) {
  if (identifier == null || identifier.isEmpty) return 'No disponible';
  if (identifier.length <= 4) return identifier;
  return '••••  ••••  ••••  ${identifier.substring(identifier.length - 4)}';
}

/// Función auxiliar para obtener sólo las llaves válidas
List<String> _getValidLlaves(List<String>? llaves) {
  if (llaves == null) return [];
  return llaves.where((llave) => llave.isNotEmpty).toList();
}

/// Formatear llaves para compartir/QR
String formatLlavesForSharing(List<String>? llaves) {
  final validLlaves = _getValidLlaves(llaves);
  if (validLlaves.isEmpty) return 'No disponibles';
  return validLlaves.join(", ");
}

class TarjetaBanco extends ConsumerWidget {
  final BancoModelo banco;
  final VoidCallback onEliminar;
  final VoidCallback onEditar;

  const TarjetaBanco({
    super.key,
    required this.banco,
    required this.onEliminar,
    required this.onEditar,
  });

  Color _parseHexColor(String? hexString, {Color fallback = Themes.primary}) {
    if (hexString == null) return fallback;
    try {
      final String formatted = hexString.replaceAll('#', '');
      if (formatted.length == 6) {
        return Color(int.parse('FF$formatted', radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color brandColorPrimary = _parseHexColor(banco.colorPrincipal);
    final Color brandColorSecondary = _parseHexColor(
      banco.colorSecundario,
      fallback: brandColorPrimary.withOpacity(0.85),
    );

    final String displayId = _getDisplayIdentifier();
    final String actualId = _getActualIdentifier();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [brandColorPrimary, brandColorSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: brandColorPrimary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Diseño estético de fondo (Líneas curvas fintech sutiles)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: -80,
              bottom: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // 2. Información y Contenido de la Tarjeta
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fila Superior: Marca del banco, chip y contactless
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Logo dinámico basado en letra inicial (avatares limpios)
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  banco.nombre.isNotEmpty
                                      ? banco.nombre.substring(0, 1).toUpperCase()
                                      : 'B',
                                  style: TextStyle(
                                    color: brandColorPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                banco.nombre.isNotEmpty ? banco.nombre : 'Banco desconocido',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Contactless Icon
                      Icon(
                        Icons.contactless,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chip dorado de tarjeta
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade300,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade200, Colors.amber.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 10,
                            top: 6,
                            bottom: 6,
                            child: VerticalDivider(color: Colors.black.withOpacity(0.15), width: 1),
                          ),
                          Positioned(
                            left: 22,
                            top: 6,
                            bottom: 6,
                            child: VerticalDivider(color: Colors.black.withOpacity(0.15), width: 1),
                          ),
                          Positioned(
                            left: 34,
                            top: 6,
                            bottom: 6,
                            child: VerticalDivider(color: Colors.black.withOpacity(0.15), width: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Número de Cuenta o Llave Principal
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      
                      // Copiar al Portapapeles
                      if (actualId.isNotEmpty && actualId != 'No disponible')
                        IconButton(
                          tooltip: 'Copiar número',
                          icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: actualId));
                            UIHelpers.showSuccessSnackBar(
                              context: context,
                              message: '¡Número copiado al portapapeles!',
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tipo de cuenta e indicador
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        banco.tipoIdentificador == 'cuenta'
                            ? 'NÚMERO DE CUENTA'
                            : 'LLAVE BANCARIA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (banco.tipoIdentificador == 'llave')
                        Text(
                          '${_getValidLlaves(banco.llaves).length} llaves',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 32),

                  // Fila Inferior: Botones de Acción Estilizados
                  Row(
                    children: [
                      // QR
                      _buildMiniBtn(
                        icon: Icons.qr_code_scanner,
                        label: 'QR',
                        onPressed: () => _mostrarQR(context),
                      ),
                      const SizedBox(width: 8),

                      // Compartir
                      _buildMiniBtn(
                        icon: Icons.share,
                        label: 'Compartir',
                        onPressed: () => _compartirCuenta(),
                      ),
                      
                      const Spacer(),

                      // Editar
                      _buildMiniCircleBtn(
                        icon: Icons.edit_outlined,
                        tooltip: 'Editar cuenta',
                        onPressed: onEditar,
                      ),
                      const SizedBox(width: 8),

                      // Eliminar
                      _buildMiniCircleBtn(
                        icon: Icons.delete_outline,
                        tooltip: 'Desvincular banco',
                        onPressed: () => confirmarEliminacion(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBtn({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }

  Widget _buildMiniCircleBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  String _getDisplayIdentifier() {
    if (banco.tipoIdentificador == 'cuenta') {
      return maskIdentifier(banco.numeroCuenta);
    } else {
      final valid = _getValidLlaves(banco.llaves);
      if (valid.isNotEmpty) {
        return maskIdentifier(valid[0]);
      }
    }
    return '••••  ••••  ••••  ••••';
  }

  String _getActualIdentifier() {
    if (banco.tipoIdentificador == 'cuenta') {
      return banco.numeroCuenta ?? 'No disponible';
    } else {
      final valid = _getValidLlaves(banco.llaves);
      if (valid.isNotEmpty) {
        return valid.join(", ");
      }
    }
    return 'No disponible';
  }

  void _compartirCuenta() {
    String mensaje;
    if (banco.tipoIdentificador == 'cuenta') {
      mensaje = 'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta ?? "No disponible"}';
    } else {
      final llavesFormateadas = formatLlavesForSharing(banco.llaves);
      mensaje = 'Banco: ${banco.nombre}\nLlaves: $llavesFormateadas';
    }
    Share.share(mensaje, subject: 'Información bancaria');
  }

  void _mostrarQR(BuildContext context) {
    String dataQR;
    if (banco.tipoIdentificador == 'cuenta') {
      dataQR = 'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta ?? "No disponible"}';
    } else {
      final llavesFormateadas = formatLlavesForSharing(banco.llaves);
      dataQR = 'Banco: ${banco.nombre}\nLlaves: $llavesFormateadas';
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QRScreen(data: dataQR)),
    );
  }

  void confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Desvincular Cuenta'),
          ],
        ),
        content: Text('¿Estás seguro de que deseas desvincular tu cuenta de "${banco.nombre}"? Esta acción removerá el registro localmente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onEliminar();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
  }
}
