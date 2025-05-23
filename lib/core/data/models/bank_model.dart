// Modelo para representar un banco en la aplicación
class BancoModelo {
  final String id; // Identificador único del banco
  final String nombre; // Nombre del banco
  final double tasaInteres; // Tasa de interés del banco
  final double comisionMensual; // Comisión mensual del banco
  final int beneficios; // Número de beneficios asociados
  final String numeroCuenta; // Número de cuenta del usuario

  BancoModelo({
    required this.id,
    required this.nombre,
    this.tasaInteres = 0.0,
    this.comisionMensual = 0.0,
    this.beneficios = 0,
    required this.numeroCuenta, // Campo obligatorio
  });

  // Devuelve el número de cuenta enmascarado (ej: ********7890)
  String get numeroCuentaEnmascarado {
    if (numeroCuenta.length <= 4) return numeroCuenta;
    final int visibleDigits = 4;
    final int maskedLength = numeroCuenta.length - visibleDigits;
    return '*' * maskedLength + numeroCuenta.substring(maskedLength);
  }

  // Convertir JSON a objeto BancoModelo
  factory BancoModelo.fromJson(Map<String, dynamic> json) => BancoModelo(
        id: json['id'],
        nombre: json['nombre'],
        tasaInteres: json['tasa_interes']?.toDouble() ?? 0.0,
        comisionMensual: json['comision_mensual']?.toDouble() ?? 0.0,
        beneficios: json['beneficios'] ?? 0,
        numeroCuenta: json['numero_cuenta'] ?? '',
      );

  // Convertir objeto BancoModelo a JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tasa_interes': tasaInteres,
        'comision_mensual': comisionMensual,
        'beneficios': beneficios,
        'numero_cuenta': numeroCuenta,
      };
}
