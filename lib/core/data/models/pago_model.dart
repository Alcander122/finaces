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
      frecuenciaRecurrencia:
          frecuenciaRecurrencia ?? this.frecuenciaRecurrencia,
    );
  }

  // Convierte un Map en un objeto Pago
  factory Pago.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pago(
      id: doc.id, // ← Correcto
      descripcion: data['descripcion'] ?? '',
      monto: (data['monto'] as num?)?.toDouble() ?? 0.0,
      fechaVencimiento:
          (data['fechaVencimiento'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estaProgramado: data['estaProgramado'] ?? false,
      notificacionAntes: data['notificacionAntes'] ?? 1,
      frecuenciaRecurrencia: data['frecuenciaRecurrencia'] ?? 'mensual',
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
