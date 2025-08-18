// bank_model.dart
/// Modelo que representa una cuenta bancaria en la aplicación
///
/// MEJORAS CRÍTICAS:
/// 1. Manejo estricto de valores null
/// 2. Validación de tipos en el método fromJson
/// 3. Valores por defecto seguros para campos críticos
///
/// IMPORTANTE:
/// Firestore permite campos null, pero nuestro modelo debe manejarlos
/// de forma segura para evitar errores como "type 'Null' is not a subtype of type 'String'"
class BancoModelo {
  final String id;
  final String nombre;
  final String tipoIdentificador; // 'cuenta' o 'llave'
  final String? numeroCuenta; // Solo para tipo 'cuenta'
  final List<String>?
      llaves; // Solo para tipo 'llave' (debe contener 3 elementos)
  final String userId;

  BancoModelo({
    required this.id,
    required this.nombre,
    this.tipoIdentificador = 'cuenta',
    this.numeroCuenta,
    this.llaves,
    required this.userId,
  })  : assert(nombre.isNotEmpty, 'El nombre del banco no puede estar vacío'),
        assert(userId.isNotEmpty, 'El userId no puede estar vacío');

  // Factory para crear banco sin ID (para nuevos registros)
  factory BancoModelo.sinId({
    required String nombre,
    String tipoIdentificador = 'cuenta',
    String? numeroCuenta,
    List<String>? llaves,
    required String userId,
  }) {
    return BancoModelo(
      id: '', // Firestore generará el ID
      nombre: nombre,
      tipoIdentificador: tipoIdentificador,
      numeroCuenta: numeroCuenta,
      llaves: llaves,
      userId: userId,
    );
  }

  // Conversión a mapa para Firestore (excluye el ID)
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipoIdentificador': tipoIdentificador,
      'numeroCuenta': numeroCuenta,
      'llaves': llaves,
      'userId': userId,
    };
  }

  // Factory para crear desde Firestore (incluye ID del documento)
  factory BancoModelo.fromJson(Map<String, dynamic> json,
      {String? documentId}) {
    // Manejo extremadamente seguro de los valores nulos
    String safeNombre = 'Banco desconocido';
    if (json['nombre'] is String && (json['nombre'] as String).isNotEmpty) {
      safeNombre = json['nombre'] as String;
    }

    String safeTipo = 'cuenta';
    if (json['tipoIdentificador'] is String &&
        (json['tipoIdentificador'] as String).isNotEmpty &&
        ['cuenta', 'llave'].contains(json['tipoIdentificador'])) {
      safeTipo = json['tipoIdentificador'] as String;
    }

    String? safeNumeroCuenta;
    if (json['numeroCuenta'] is String &&
        (json['numeroCuenta'] as String).isNotEmpty) {
      safeNumeroCuenta = json['numeroCuenta'] as String;
    }

    List<String>? safeLlaves;
    if (json['llaves'] is List) {
      safeLlaves = (json['llaves'] as List)
          .where((item) => item is String && (item as String).isNotEmpty)
          .map((item) => item as String)
          .toList();

      // Si no hay llaves válidas, establecemos null
      if (safeLlaves.isEmpty) safeLlaves = null;
    }

    String safeUserId = '';
    if (json['userId'] is String && (json['userId'] as String).isNotEmpty) {
      safeUserId = json['userId'] as String;
    }

    return BancoModelo(
      id: documentId ?? (json['id'] ?? ''),
      nombre: safeNombre,
      tipoIdentificador: safeTipo,
      numeroCuenta: safeNumeroCuenta,
      llaves: safeLlaves,
      userId: safeUserId,
    );
  }

  // Método para clonar con nuevos valores
  BancoModelo copyWith({
    String? id,
    String? nombre,
    String? tipoIdentificador,
    String? numeroCuenta,
    List<String>? llaves,
    String? userId,
  }) {
    return BancoModelo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoIdentificador: tipoIdentificador ?? this.tipoIdentificador,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      llaves: llaves ?? this.llaves,
      userId: userId ?? this.userId,
    );
  }
}
