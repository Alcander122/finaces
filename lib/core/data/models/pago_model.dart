import 'package:cloud_firestore/cloud_firestore.dart';

// Clase que representa un pago, incluye ID, descripción, monto, fecha de vencimiento y si está programado
class Pago {
  final String id;
  final String descripcion;
  final double monto;
  final DateTime fechaVencimiento;
  final bool estaProgramado;

  // Constructor
  const Pago({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.fechaVencimiento,
    required this.estaProgramado,
  });

  // Método para copiar el objeto y modificarlo
  Pago copyWith({
    String? id,
    String? descripcion,
    double? monto,
    DateTime? fechaVencimiento,
    bool? estaProgramado,
  }) {
    return Pago(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estaProgramado: estaProgramado ?? this.estaProgramado,
    );
  }

  // Factory para crear un Pago a partir de un Map
  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id: map['id'] ?? '',
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] as num).toDouble(),
      fechaVencimiento: (map['fechaVencimiento'] as Timestamp).toDate(),
      estaProgramado: map['estaProgramado'] ?? false,
    );
  }

  // Método para convertir el objeto en un Map
  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'monto': monto,
      'fechaVencimiento': fechaVencimiento,
      'estaProgramado': estaProgramado,
    };
  }
}