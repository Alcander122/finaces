import 'package:cloud_firestore/cloud_firestore.dart';

class Investment {
  final String id;
  final String userId;
  final String portafolioId;
  final DateTime fecha;
  final String mes;
  final String origen;
  final double invMensual;
  final String moneda;
  final String activo;
  final String descripcion;
  final String estado;
  final DateTime fechaInversion;

  Investment({
    required this.id,
    required this.userId,
    required this.portafolioId,
    required this.fecha,
    required this.mes,
    required this.origen,
    required this.invMensual,
    required this.moneda,
    required this.activo,
    required this.descripcion,
    required this.estado,
    required this.fechaInversion,
  });

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Investment(
      id: doc.id, // ✅ Corrección: usar doc.id
      userId: data['userId'],
      portafolioId: data['portafolioId'],
      fecha: (data['fecha'] as Timestamp).toDate(),
      mes: data['mes'],
      origen: data['origen'],
      invMensual: (data['invMensual'] as num).toDouble(),
      moneda: data['moneda'],
      activo: data['activo'],
      descripcion: data['descripcion'],
      estado: data['estado'],
      fechaInversion: (data['fechaInversion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'portafolioId': portafolioId,
      'fecha': fecha,
      'mes': mes,
      'origen': origen,
      'invMensual': invMensual,
      'moneda': moneda,
      'activo': activo,
      'descripcion': descripcion,
      'estado': estado,
      'fechaInversion': fechaInversion,
    };
  }
}
