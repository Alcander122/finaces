// core/data/models/objetivo_ahorro.dart
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
    DateTime? fecha,
    this.descripcion,
  }) : fecha = fecha ?? DateTime.now();

  /// Convierte la transacción en un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'monto': monto,
      'fecha': Timestamp.fromDate(fecha),
      'descripcion': descripcion,
    };
  }

  /// Crea una Transaccion desde un mapa (Firestore)
  factory Transaccion.fromMap(Map<String, dynamic> map) {
    return Transaccion(
      tipo: map['tipo'] as String,
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] != null
          ? (map['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      descripcion: map['descripcion'] as String?,
    );
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
    this.montoActual = 0.0,
    required this.montoObjetivo,
    required this.fechaObjetivo,
    List<Transaccion>? transacciones,
    required this.fechaCreacion,
    DateTime? fechaActualizacion,
  })  : transacciones = transacciones ?? [],
        fechaActualizacion = fechaActualizacion ?? DateTime.now();

  /// Progreso en porcentaje (0.0 a 100.0)
  double get progreso {
    if (montoObjetivo <= 0) return 0.0;
    final p = (montoActual / montoObjetivo) * 100;
    return p > 100 ? 100.0 : p;
  }

  /// Alias para compatibilidad con código viejo
  double get ahorroActual => montoActual;

  /// Monto restante para completar la meta
  double get montoRestante =>
      (montoObjetivo - montoActual).clamp(0.0, double.infinity);

  /// Convierte el objeto a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'nombre': nombre,
      'montoActual': montoActual,
      'montoObjetivo': montoObjetivo,
      'fechaObjetivo': Timestamp.fromDate(fechaObjetivo),
      'transacciones': transacciones.map((t) => t.toMap()).toList(),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
    };
  }

  /// Crea un ObjetivoAhorro desde un documento de Firestore
  factory ObjetivoAhorro.desdeFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Validación segura de campos
    final List<Transaccion> transacciones = [];
    if (data['transacciones'] != null) {
      for (var t in data['transacciones']) {
        if (t is Map<String, dynamic>) {
          transacciones.add(Transaccion.fromMap(t));
        }
      }
    }

    return ObjetivoAhorro(
      id: doc.id,
      usuarioId: data['usuarioId'] as String? ?? '',
      nombre: data['nombre'] as String? ?? 'Sin nombre',
      montoActual: (data['montoActual'] as num?)?.toDouble() ?? 0.0,
      montoObjetivo: (data['montoObjetivo'] as num?)?.toDouble() ?? 0.0,
      fechaObjetivo: data['fechaObjetivo'] != null
          ? (data['fechaObjetivo'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      transacciones: transacciones,
      fechaCreacion: data['fechaCreacion'] != null
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      fechaActualizacion: data['fechaActualizacion'] != null
          ? (data['fechaActualizacion'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Crea una copia con campos actualizados
  ObjetivoAhorro copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    double? montoActual,
    double? montoObjetivo,
    DateTime? fechaObjetivo,
    List<Transaccion>? transacciones,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ObjetivoAhorro(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      montoActual: montoActual ?? this.montoActual,
      montoObjetivo: montoObjetivo ?? this.montoObjetivo,
      fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
      transacciones: transacciones ?? this.transacciones,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
