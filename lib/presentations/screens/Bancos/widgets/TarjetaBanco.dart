// TarjetaBanco.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:share_plus/share_plus.dart'; // Importa el paquete correcto
import 'package:finances/presentations/screens/Bancos/widgets/qr_screen.dart';

/// Función para enmascarar cualquier identificador sensible de forma segura
///
/// MÁSCARA PARA LLAVES:
/// - Muestra los últimos 4 caracteres y oculta el resto con asteriscos
/// - Si la llave tiene 4 o menos caracteres, no se enmascara
/// - Maneja adecuadamente los valores nulos
String maskIdentifier(String? identifier) {
  if (identifier == null || identifier.isEmpty) return 'No disponible';
  if (identifier.length <= 4) return identifier;
  return '*' * (identifier.length - 4) +
      identifier.substring(identifier.length - 4);
}

/// Función auxiliar para obtener solo las llaves válidas (no vacías)
List<String> _getValidLlaves(List<String>? llaves) {
  if (llaves == null) return [];
  return llaves.where((llave) => llave.isNotEmpty).toList();
}

/// Función para formatear las llaves para mostrar (máximo 3)
String formatLlavesForDisplay(List<String>? llaves) {
  final validLlaves = _getValidLlaves(llaves);
  if (validLlaves.isEmpty) return 'No disponibles';
  // Mostrar máximo 3 llaves con puntos suspensivos si hay más
  final displayLlaves =
      validLlaves.length > 3 ? validLlaves.sublist(0, 3) : validLlaves;
  return displayLlaves.join(", ") + (validLlaves.length > 3 ? "..." : "");
}

/// Función para formatear las llaves para compartir/QR (solo las válidas)
String formatLlavesForSharing(List<String>? llaves) {
  final validLlaves = _getValidLlaves(llaves);
  if (validLlaves.isEmpty) return 'No disponibles';
  return validLlaves.join(", ");
}

/// Widget que muestra una tarjeta con la información de una cuenta bancaria
///
/// Muestra el nombre del banco, el identificador (número de cuenta o llave)
/// y opciones para ver QR, compartir, eliminar y editar.
class TarjetaBanco extends ConsumerWidget {
  final BancoModelo banco;
  final VoidCallback onEliminar;
  final VoidCallback onEditar; // Callback para la acción de edición

  const TarjetaBanco({
    super.key,
    required this.banco,
    required this.onEliminar,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Themes.degradientLight, Themes.degradientDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nombre del banco (con manejo seguro de nulos)
                  Text(
                    banco.nombre.isNotEmpty
                        ? banco.nombre
                        : 'Banco desconocido',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Themes.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Identificador (número de cuenta o llave) - MANEJO SEGURO DE NULOS
                  Text(
                    _getDisplayIdentifier(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Información adicional sobre el tipo de identificador
                  _buildTipoIdentificadorInfo(),
                  const SizedBox(height: 15),
                  // Botones principales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botón Ver QR
                      ElevatedButton.icon(
                        onPressed: () => _mostrarQR(context),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Ver QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Themes.degradientDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Botón Compartir
                      ElevatedButton.icon(
                        onPressed: () => _compartirCuenta(),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Themes.degradientDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Botón de edición flotante (en la esquina superior derecha)
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEditar, // Llamamos al callback de edición
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.edit, // Icono de lápiz para edición
                  size: 20,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
        // Botón de eliminación flotante (en la esquina inferior izquierda)
        Positioned(
          bottom: 6,
          left: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEliminar,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.delete,
                  size: 20,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Muestra información sobre el tipo de identificador usado
  Widget _buildTipoIdentificadorInfo() {
    String mensaje;
    if (banco.tipoIdentificador == 'cuenta') {
      mensaje = 'Identificador: Número de cuenta';
    } else {
      mensaje = 'Identificador: Llave bancaria';
      // Información adicional sobre el formato de llaves
      final validLlaves = _getValidLlaves(banco.llaves);
      if (validLlaves.isNotEmpty) {
        mensaje += '\n(${validLlaves.length} partes)';
      }
    }
    return Text(
      mensaje,
      style: TextStyle(
        color: Colors.white60,
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Obtiene el identificador a mostrar según el tipo (cuenta o llave) - MANEJO SEGURO
  String _getDisplayIdentifier() {
    if (banco.tipoIdentificador == 'cuenta') {
      return maskIdentifier(banco.numeroCuenta);
    } else if (banco.tipoIdentificador == 'llave' &&
        banco.llaves != null &&
        banco.llaves!.isNotEmpty) {
      // Mostrar solo la primera llave válida
      final validLlaves = _getValidLlaves(banco.llaves);
      if (validLlaves.isNotEmpty) {
        return maskIdentifier(validLlaves[0]);
      }
    }
    return 'Información no disponible';
  }

  /// Comparte la información de la cuenta bancaria
  ///
  /// CORRECCIÓN IMPORTANTE:
  /// En lugar de Share.share(), ahora se usa directamente Share.share()
  /// El mensaje de error "Share is deprecated" se debe a que en versiones recientes
  /// de share_plus, Share es una librería con funciones, no una clase.
  /// La API ha cambiado pero el nombre sigue siendo el mismo.
  void _compartirCuenta() {
    String mensaje;
    if (banco.tipoIdentificador == 'cuenta') {
      mensaje =
          'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta ?? "No disponible"}';
    } else {
      // CORRECCIÓN PRINCIPAL: Usar solo llaves válidas para compartir
      final llavesFormateadas = formatLlavesForSharing(banco.llaves);
      mensaje = 'Banco: ${banco.nombre}\nLlaves: $llavesFormateadas';
    }

    // CORRECCIÓN DEL ERROR:
    // En lugar de Share.share(mensaje), usamos directamente Share.share(mensaje)
    // Esto resuelve el error "Share is deprecated"
    Share.share(mensaje, subject: 'Información bancaria');
  }

  /// Muestra el código QR con la información de la cuenta
  void _mostrarQR(BuildContext context) {
    String dataQR;
    if (banco.tipoIdentificador == 'cuenta') {
      dataQR =
          'Banco: ${banco.nombre}\nNúmero de cuenta: ${banco.numeroCuenta ?? "No disponible"}';
    } else {
      // CORRECCIÓN PRINCIPAL: Usar solo llaves válidas para el QR
      final llavesFormateadas = formatLlavesForSharing(banco.llaves);
      dataQR = 'Banco: ${banco.nombre}\nLlaves: $llavesFormateadas';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScreen(data: dataQR),
      ),
    );
  }

  /// Confirma la eliminación de la cuenta bancaria
  void confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuenta bancaria?'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar esta cuenta bancaria? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancelar
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              onEliminar(); // Ejecuta eliminación
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
