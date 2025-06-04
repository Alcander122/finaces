import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:cloud_firestore/cloud_firestore.dart'; // Para integración con Firestore

class Ingreso {
  String id;
  DateTime fecha; // Fecha de creación del registro (legacy)
  DateTime fechaIngreso; // Nueva fecha de ingreso (reemplaza mes/anio)
  String quincena;
  String categoria;
  String concepto;
  int valor;

  Ingreso({
    required this.id,
    required this.fecha,
    required this.fechaIngreso,
    required this.quincena,
    required this.categoria,
    required this.concepto,
    required this.valor,
  });

  // Formatea fechaIngreso como "dd/MM/yyyy" para mostrar en UI
  String get fechaIngresoFormateada => DateFormat('dd/MM/yyyy').format(fechaIngreso);

  // Conversión desde Map (Firestore)
  factory Ingreso.fromMap(Map<String, dynamic> map) {
    DateTime fecha;
    DateTime fechaIngreso;

    // Maneja conversión de campo legacy 'fecha'
    if (map['fecha'] is Timestamp) {
      fecha = (map['fecha'] as Timestamp).toDate();
    } else if (map['fecha'] is String) {
      fecha = DateFormat('dd/MM/yyyy').parse(map['fecha']);
    } else {
      fecha = DateTime.now();
    }

    // Maneja conversión de nuevo campo 'fechaIngreso'
    if (map['fechaIngreso'] is Timestamp) {
      fechaIngreso = (map['fechaIngreso'] as Timestamp).toDate();
    } else if (map['fechaIngreso'] is String) {
      fechaIngreso = DateFormat('dd/MM/yyyy').parse(map['fechaIngreso']);
    } else {
      // Fallback para datos legacy (usa mes/anio si existen)
      final mesMap = map['mes'] ?? 'Enero';
      final anioMap = map['anio'] ?? DateTime.now().year;
      final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      int mesNumero = meses.indexOf(mesMap) + 1;
      fechaIngreso = DateTime(anioMap, mesNumero);
    }

    return Ingreso(
      id: map['id'] ?? '',
      fecha: fecha,
      fechaIngreso: fechaIngreso,
      quincena: map['quincena'] ?? '',
      categoria: map['categoria'] ?? '',
      concepto: map['concepto'] ?? '',
      valor: map['valor'] ?? 0,
    );
  }

  // Conversión a Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': Timestamp.fromDate(fecha), // Legacy
      'fechaIngreso': Timestamp.fromDate(fechaIngreso), // Nuevo campo
      'quincena': quincena,
      'categoria': categoria,
      'concepto': concepto,
      'valor': valor,
    };
  }
}