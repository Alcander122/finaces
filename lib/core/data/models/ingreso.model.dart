import 'package:intl/intl.dart'; // Importa este paquete
import 'package:cloud_firestore/cloud_firestore.dart';
class Ingreso {
  String id;
  DateTime fecha;
  String mes;
  int anio;
  String quincena;
  String categoria;
  String concepto;
  int valor;

  Ingreso({
    required this.id,
    required this.fecha,
    required this.mes,
    required this.anio,
    required this.quincena,
    required this.categoria,
    required this.concepto,
    required this.valor,
  });

  // Método para formatear la fecha correctamente
  String get fechaFormateada => DateFormat('dd/MM/yyyy').format(fecha);

  // Conversión desde un Map (Firestore a objeto `Ingreso`)
  factory Ingreso.fromMap(Map<String, dynamic> map) {
    DateTime fecha;

    if (map['fecha'] is Timestamp) {
      // Convertir Timestamp a DateTime
      fecha = (map['fecha'] as Timestamp).toDate();
    } else if (map['fecha'] is String) {
      // Parsear String a DateTime
      fecha = DateFormat('dd/MM/yyyy').parse(map['fecha']);
    } else {
      fecha = DateTime.now();
    }

    return Ingreso(
      id: map['id'].toString(),
      fecha: fecha,
      mes: map['mes'] ?? '',
      anio: int.tryParse(map['anio'].toString()) ?? DateTime.now().year,
      quincena: map['quincena'] ?? '',
      categoria: map['categoria'] ?? '',
      concepto: map['concepto'] ?? '',
      valor: int.tryParse(map['valor'].toString()) ?? 0,
    );
  }

  // Conversión de objeto `Ingreso` a Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': Timestamp.fromDate(fecha), // Guardar como Timestamp
      'mes': mes,
      'anio': anio,
      'quincena': quincena,
      'categoria': categoria,
      'concepto': concepto,
      'valor': valor,
    };
  }

  // Método para obtener el mes en formato numérico
  int getMesNumero() {
    const meses = [
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
    return meses.indexOf(mes) + 1;
  }
}