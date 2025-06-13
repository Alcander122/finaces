// pago_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pago {
  final String id;
  final String descripcion;
  final double monto;
  final DateTime fechaVencimiento;
  final bool estaProgramado;
  final int notificacionAntes; // Días antes del vencimiento para notificar
  final String frecuenciaRecurrencia; // Ej: "mensual", "semanal"

  const Pago({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.fechaVencimiento,
    required this.estaProgramado,
    required this.notificacionAntes,
    required this.frecuenciaRecurrencia,
  });

  // Crea una copia modificada del pago
  Pago copyWith({
    String? id,
    String? descripcion,
    double? monto,
    DateTime? fechaVencimiento,
    bool? estaProgramado,
    int? notificacionAntes,
    String? frecuenciaRecurrencia,
  }) {
    return Pago(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estaProgramado: estaProgramado ?? this.estaProgramado,
      notificacionAntes: notificacionAntes ?? this.notificacionAntes,
      frecuenciaRecurrencia: frecuenciaRecurrencia ?? this.frecuenciaRecurrencia,
    );
  }

  // Convierte un Map en un objeto Pago
  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id: map['id'] ?? '',
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] as num).toDouble(),
      fechaVencimiento: (map['fechaVencimiento'] as Timestamp).toDate(),
      estaProgramado: map['estaProgramado'] ?? false,
      notificacionAntes: map['notificacionAntes'] ?? 1, // Por defecto 1 día
      frecuenciaRecurrencia: map['frecuenciaRecurrencia'] ?? 'mensual', // Por defecto mensual
    );
  }

  // Convierte el objeto Pago en un Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'monto': monto,
      'fechaVencimiento': fechaVencimiento,
      'estaProgramado': estaProgramado,
      'notificacionAntes': notificacionAntes,
      'frecuenciaRecurrencia': frecuenciaRecurrencia,
    };
  }
}