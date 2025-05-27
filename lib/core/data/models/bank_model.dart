// bank_model.dart
class BancoModelo {
  final String id;
  final String nombre;
  final String numeroCuenta;
  final String userId;

  BancoModelo({
    required this.id,
    required this.nombre,
    required this.numeroCuenta,
    required this.userId,
  });

  // Factory para crear banco sin ID (para nuevos registros)
  factory BancoModelo.sinId({
    required String nombre,
    required String numeroCuenta,
    required String userId,
  }) {
    return BancoModelo(
      id: '', // Firestore generará el ID
      nombre: nombre,
      numeroCuenta: numeroCuenta,
      userId: userId,
    );
  }

  // Conversión a mapa para Firestore (excluye el ID)
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'numeroCuenta': numeroCuenta,
      'userId': userId,
    };
  }

  // Factory para crear desde Firestore (incluye ID del documento)
  factory BancoModelo.fromJson(Map<String, dynamic> json) {
    return BancoModelo(
      id: json['id'] ?? '', // ID ahora viene de Firestore
      nombre: json['nombre'] ?? '',
      numeroCuenta: json['numeroCuenta'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  // Método para clonar con nuevos valores
  BancoModelo copyWith({
    String? id,
    String? nombre,
    String? numeroCuenta,
    String? userId,
  }) {
    return BancoModelo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      userId: userId ?? this.userId,
    );
  }
}