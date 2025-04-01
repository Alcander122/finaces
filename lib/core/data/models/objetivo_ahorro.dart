import 'package:cloud_firestore/cloud_firestore.dart';

class Transaccion {
  final String tipo; // 'deposito' o 'retiro'
  final double monto;
  final DateTime fecha;
  final String? descripcion;

  Transaccion({
    required this.tipo,
    required this.monto,
    required this.fecha,
    this.descripcion,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'monto': monto,
      'fecha': Timestamp.fromDate(fecha),
      'descripcion': descripcion,
    };
  }
}

class ObjetivoAhorro {
  final String? id;
  final String usuarioId;
  final String nombre;
  final double montoActual;
  final double montoObjetivo;
  final DateTime fechaObjetivo;
  final List<Transaccion> transacciones;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  ObjetivoAhorro({
    this.id,
    required this.usuarioId,
    required this.nombre,
    required this.montoActual,
    required this.montoObjetivo,
    required this.fechaObjetivo,
    required this.transacciones,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  double get progreso => (montoActual / montoObjetivo) * 100;

  factory ObjetivoAhorro.desdeFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ObjetivoAhorro(
      id: doc.id,
      usuarioId: data['usuarioId'],
      nombre: data['nombre'],
      montoActual: data['montoActual'].toDouble(),
      montoObjetivo: data['montoObjetivo'].toDouble(),
      fechaObjetivo: (data['fechaObjetivo'] as Timestamp).toDate(),
      transacciones: List<Transaccion>.from(
        data['transacciones'].map(
          (t) => Transaccion(
            tipo: t['tipo'],
            monto: t['monto'].toDouble(),
            fecha: (t['fecha'] as Timestamp).toDate(),
            descripcion: t['descripcion'],
          ),
        ),
      ),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
    );
  }
}
