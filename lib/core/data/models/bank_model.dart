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

  // Crea un banco sin ID (útil para nuevos registros donde Firestore genera el ID)
  factory BancoModelo.sinId({
    required String nombre,
    required String numeroCuenta,
    required String userId,
  }) {
    return BancoModelo(
      id: '',
      nombre: nombre,
      numeroCuenta: numeroCuenta,
      userId: userId,
    );
  }

  // Convierte el objeto a formato JSON para almacenarlo en Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'numeroCuenta': numeroCuenta,
      'userId': userId,
    };
  }

  // Convierte datos desde JSON (Firestore) a un objeto BancoModelo
  // Maneja campos nulos con valores por defecto (evita errores de tipo Null)
  factory BancoModelo.fromJson(Map<String, dynamic> json) {
    return BancoModelo(
      id: json['id'] as String? ?? '',
      nombre: (json['nombre'] as String?)?.isNotEmpty == true ? json['nombre'] as String : '',
      numeroCuenta: (json['numeroCuenta'] as String?)?.isNotEmpty == true ? json['numeroCuenta'] as String : '',
      userId: (json['userId'] as String?)?.isNotEmpty == true ? json['userId'] as String : '',
    );
  }
}