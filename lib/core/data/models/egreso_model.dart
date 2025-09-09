import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Egreso {
  final String id;
  final String quincena;
  final DateTime fecha;
  final DateTime fechaPago;
  final String categoria;
  final String concepto;
  final int valor;
  final String descripcion;
  final String estado;

  Egreso({
    required this.id,
    required this.quincena,
    required this.fecha,
    required this.fechaPago,
    required this.categoria,
    required this.concepto,
    required this.valor,
    required this.descripcion,
    required this.estado,
  });

  // Convertir objeto Egreso a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quincena': quincena,
      'fecha': Timestamp.fromDate(fecha),
      'fechaPago': Timestamp.fromDate(fechaPago),
      'categoria': categoria,
      'concepto': concepto,
      'valor': valor,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  // Crear una instancia de Egreso a partir de un Map (Firestore)
  static Egreso fromMap(Map<String, dynamic> map) {
    // ✅ Aseguramos que las fechas nunca sean nulas usando valores por defecto
    DateTime fecha;
    DateTime fechaPago;

    // Procesar fecha
    if (map['fecha'] is Timestamp) {
      fecha = (map['fecha'] as Timestamp).toDate();
    } else if (map['fecha'] is String) {
      fecha = DateFormat('dd/MM/yyyy').parse(map['fecha']);
    } else {
      fecha = DateTime.now(); // Valor por defecto si es nulo
    }

    // Procesar fechaPago
    if (map['fechaPago'] is Timestamp) {
      fechaPago = (map['fechaPago'] as Timestamp).toDate();
    } else if (map['fechaPago'] is String) {
      fechaPago = DateFormat('dd/MM/yyyy').parse(map['fechaPago']);
    } else {
      // Fallback para datos legacy
      final mesMap = map['mes'] ?? 'Enero';
      final anioMap = map['anio'] ?? DateTime.now().year;
      final meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre'
      ];
      int mesNumero = meses.indexOf(mesMap) + 1;
      fechaPago = DateTime(anioMap, mesNumero);
    }

    return Egreso(
      id: map['id'] ?? '',
      quincena: map['quincena'] ?? '',
      fecha: fecha,
      fechaPago: fechaPago,
      categoria: map['categoria'] ?? '',
      concepto: map['concepto'] ?? '',
      valor: map['valor'] is int ? map['valor'] : 0,
      descripcion: map['descripcion'] ?? '',
      estado: map['estado'] ?? '',
    );
  }

  // Método copyWith para copiar un objeto con algunos campos modificados
  Egreso copyWith({
    String? id,
    String? quincena,
    DateTime? fecha,
    DateTime? fechaPago,
    String? categoria,
    String? concepto,
    int? valor,
    String? descripcion,
    String? estado,
  }) {
    return Egreso(
      id: id ?? this.id,
      quincena: quincena ?? this.quincena,
      fecha: fecha ?? this.fecha,
      fechaPago: fechaPago ?? this.fechaPago,
      categoria: categoria ?? this.categoria,
      concepto: concepto ?? this.concepto,
      valor: valor ?? this.valor,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
    );
  }
}
