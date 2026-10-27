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

  // Nuevos campos opcionales para proyecciones y simulaciones financieras
  final double? rendimientoEstimadoEA; // Tasa Efectiva Anual estimada (%)
  final bool esAporteRecurrente; // Si la inversión contempla aporte periódico recurrente
  final int? plazoMeses; // Plazo proyectado en meses

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
    this.rendimientoEstimadoEA,
    this.esAporteRecurrente = false,
    this.plazoMeses,
  });

  /// Constructor factory a partir de DocumentSnapshot con compatibilidad total hacia atrás
  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Investment.fromMap(data, id: doc.id);
  }

  /// Deserializador flexible que maneja de forma segura valores nulos y tipos mixtos
  factory Investment.fromMap(Map<String, dynamic> data, {String id = ''}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Investment(
      id: id.isNotEmpty ? id : (data['id'] as String? ?? ''),
      userId: data['userId'] as String? ?? '',
      portafolioId: data['portafolioId'] as String? ?? '',
      fecha: parseDate(data['fecha']),
      mes: data['mes'] as String? ?? '',
      origen: data['origen'] as String? ?? '',
      invMensual: (data['invMensual'] as num?)?.toDouble() ?? 0.0,
      moneda: data['moneda'] as String? ?? 'COP',
      activo: data['activo'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      estado: data['estado'] as String? ?? 'Activo',
      fechaInversion: parseDate(data['fechaInversion']),
      rendimientoEstimadoEA: (data['rendimientoEstimadoEA'] as num?)?.toDouble(),
      esAporteRecurrente: (data['esAporteRecurrente'] as bool?) ?? false,
      plazoMeses: (data['plazoMeses'] as num?)?.toInt(),
    );
  }

  /// Serializador a Firestore
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
      if (rendimientoEstimadoEA != null) 'rendimientoEstimadoEA': rendimientoEstimadoEA,
      'esAporteRecurrente': esAporteRecurrente,
      if (plazoMeses != null) 'plazoMeses': plazoMeses,
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

  Investment copyWith({
    String? id,
    String? userId,
    String? portafolioId,
    DateTime? fecha,
    String? mes,
    String? origen,
    double? invMensual,
    String? moneda,
    String? activo,
    String? descripcion,
    String? estado,
    DateTime? fechaInversion,
    double? rendimientoEstimadoEA,
    bool? esAporteRecurrente,
    int? plazoMeses,
  }) {
    return Investment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      portafolioId: portafolioId ?? this.portafolioId,
      fecha: fecha ?? this.fecha,
      mes: mes ?? this.mes,
      origen: origen ?? this.origen,
      invMensual: invMensual ?? this.invMensual,
      moneda: moneda ?? this.moneda,
      activo: activo ?? this.activo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      fechaInversion: fechaInversion ?? this.fechaInversion,
      rendimientoEstimadoEA: rendimientoEstimadoEA ?? this.rendimientoEstimadoEA,
      esAporteRecurrente: esAporteRecurrente ?? this.esAporteRecurrente,
      plazoMeses: plazoMeses ?? this.plazoMeses,
    );
  }
}
