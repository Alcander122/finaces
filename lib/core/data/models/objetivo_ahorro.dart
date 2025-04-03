import 'package:cloud_firestore/cloud_firestore.dart';

class Transaccion {
  final String tipo; // 'deposito' o 'retiro'
  final double monto;
  final DateTime fecha;
  final String? descripcion;

  Transaccion({
    required this.tipo,
    required this.monto,
    DateTime? fecha, // Permite que fecha sea opcional
    this.descripcion,
  }) : fecha = fecha ?? DateTime.now(); // Si fecha es null, usa la fecha actual

  Map<String, dynamic> toMap() {
    final fechaValida = fecha ?? DateTime.now();
    return {
      'tipo': tipo,
      'monto': monto,
      'fecha': Timestamp.fromDate(fechaValida),
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
      fechaObjetivo: data['fechaObjetivo'] == null
          ? DateTime.now()
          : (data['fechaObjetivo'] as Timestamp).toDate(),
      transacciones: data['transacciones'] != null
          ? List<Transaccion>.from(
              data['transacciones'].map(
                (t) => Transaccion(
                  tipo: t['tipo'],
                  monto: t['monto'].toDouble(),
                  fecha: t['fecha'] != null
                      ? (t['fecha'] as Timestamp).toDate()
                      : DateTime.now(),
                  descripcion: t['descripcion'],
                ),
              ),
            )
          : [],
      fechaCreacion: data['fechaCreacion'] == null
          ? DateTime.now()
          : (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: data['fechaActualizacion'] == null
          ? DateTime.now()
          : (data['fechaActualizacion'] as Timestamp).toDate(),
    );
  }
}
