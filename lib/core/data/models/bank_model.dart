// bank_model.dart
/// Modelo que representa una cuenta bancaria vinculada por el usuario,
/// enriquecida con metadatos del catálogo bancario.
class BancoModelo {
  final String id;
  final String nombre;
  final String tipoIdentificador; // 'cuenta' o 'llave'
  final String? numeroCuenta; // Solo para tipo 'cuenta'
  final List<String>? llaves; // Solo para tipo 'llave' (debe contener 3 elementos)
  final String userId;

  // 🎨 Metadatos de catálogo (opcionales para retrocompatibilidad)
  final String? colorPrincipal;
  final String? colorSecundario;
  final String? logoUrl;
  final String? categoria;
  final List<String>? aliases;
  final bool? soporteTransferencia;
  final bool? soportePse;

  BancoModelo({
    required this.id,
    required this.nombre,
    this.tipoIdentificador = 'cuenta',
    this.numeroCuenta,
    this.llaves,
    required this.userId,
    this.colorPrincipal,
    this.colorSecundario,
    this.logoUrl,
    this.categoria,
    this.aliases,
    this.soporteTransferencia,
    this.soportePse,
  })  : assert(nombre.isNotEmpty, 'El nombre del banco no puede estar vacío'),
        assert(userId.isNotEmpty, 'El userId no puede estar vacío');

  // Factory para crear banco sin ID (para nuevos registros)
  factory BancoModelo.sinId({
    required String nombre,
    String tipoIdentificador = 'cuenta',
    String? numeroCuenta,
    List<String>? llaves,
    required String userId,
    String? colorPrincipal,
    String? colorSecundario,
    String? logoUrl,
    String? categoria,
    List<String>? aliases,
    bool? soporteTransferencia,
    bool? soportePse,
  }) {
    return BancoModelo(
      id: '', // Firestore generará el ID
      nombre: nombre,
      tipoIdentificador: tipoIdentificador,
      numeroCuenta: numeroCuenta,
      llaves: llaves,
      userId: userId,
      colorPrincipal: colorPrincipal,
      colorSecundario: colorSecundario,
      logoUrl: logoUrl,
      categoria: categoria,
      aliases: aliases,
      soporteTransferencia: soporteTransferencia,
      soportePse: soportePse,
    );
  }

  // Conversión a mapa para Firestore (excluye el ID y los metadatos de catálogo)
  // Nota: Los metadatos se resuelven dinámicamente desde el catálogo local,
  // por lo que no es necesario saturar la base de datos Firestore del usuario con ellos.
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
  factory BancoModelo.fromJson(Map<String, dynamic> json, {String? documentId}) {
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
          .where((item) => item is String && item.isNotEmpty)
          .map((item) => item as String)
          .toList();

      if (safeLlaves.isEmpty) safeLlaves = null;
    }

    String safeUserId = '';
    if (json['userId'] is String && (json['userId'] as String).isNotEmpty) {
      safeUserId = json['userId'] as String;
    }

    // Carga segura de metadatos si vienen en el JSON (útil para mapeos híbridos)
    final String? colorPrincipal = json['colorPrincipal'] as String?;
    final String? colorSecundario = json['colorSecundario'] as String?;
    final String? logoUrl = json['logoUrl'] as String?;
    final String? categoria = json['categoria'] as String?;
    
    List<String>? aliases;
    if (json['aliases'] is List) {
      aliases = (json['aliases'] as List).map((e) => e.toString()).toList();
    }

    final bool? soporteTransferencia = json['soporteTransferencia'] as bool?;
    final bool? soportePse = json['soportePse'] as bool?;

    return BancoModelo(
      id: documentId ?? (json['id'] ?? ''),
      nombre: safeNombre,
      tipoIdentificador: safeTipo,
      numeroCuenta: safeNumeroCuenta,
      llaves: safeLlaves,
      userId: safeUserId,
      colorPrincipal: colorPrincipal,
      colorSecundario: colorSecundario,
      logoUrl: logoUrl,
      categoria: categoria,
      aliases: aliases,
      soporteTransferencia: soporteTransferencia,
      soportePse: soportePse,
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
    String? colorPrincipal,
    String? colorSecundario,
    String? logoUrl,
    String? categoria,
    List<String>? aliases,
    bool? soporteTransferencia,
    bool? soportePse,
  }) {
    return BancoModelo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoIdentificador: tipoIdentificador ?? this.tipoIdentificador,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      llaves: llaves ?? this.llaves,
      userId: userId ?? this.userId,
      colorPrincipal: colorPrincipal ?? this.colorPrincipal,
      colorSecundario: colorSecundario ?? this.colorSecundario,
      logoUrl: logoUrl ?? this.logoUrl,
      categoria: categoria ?? this.categoria,
      aliases: aliases ?? this.aliases,
      soporteTransferencia: soporteTransferencia ?? this.soporteTransferencia,
      soportePse: soportePse ?? this.soportePse,
    );
  }
}
