import 'package:cloud_firestore/cloud_firestore.dart';

/// Clase que representa una transacción (depósito o retiro)
class Transaccion {
  final String tipo; // 'deposito' o 'retiro'
  final double monto;
  final DateTime fecha;
  final String? descripcion;

  Transaccion({
    required this.tipo,
    required this.monto,
    DateTime? fecha, // Permite que la fecha sea opcional
    this.descripcion,
  }) : fecha = fecha ??
            DateTime
                .now(); // Si no se pasa fecha, se asigna la fecha y hora actual

  /// Convierte la transacción en un mapa para guardarla en Firestore
  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'monto': monto,
      'fecha': Timestamp.fromDate(fecha), // Se guarda como Timestamp
      'descripcion': descripcion,
    };
  }
}

/// Clase que representa un objetivo de ahorro del usuario
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

  /// Getter que devuelve el progreso en porcentaje
  double get progreso => (montoActual / montoObjetivo) * 100;

  /// Getter alternativo para compatibilidad con el código que usa `ahorroActual`
  /// Básicamente es un alias de `montoActual`
  double get ahorroActual => montoActual;

  /// Crea un objeto ObjetivoAhorro a partir de un documento de Firestore
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
