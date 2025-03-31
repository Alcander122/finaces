// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Ingreso {
  String id; // Consecutivo único
  DateTime fecha; // Fecha del registro
  String mes; // Mes seleccionado desde lista desplegable
  int anio; // Año seleccionado de los 3 años futuros
  String quincena; // Selector de quincena (Primera o Segunda)
  String categoria; // Categoría del ingreso (selector)
  String concepto; // Concepto descriptivo
  int valor; // Monto del ingreso, almacenado como INT

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
      // ✅ Si la fecha es un Timestamp, convertirla a DateTime
      fecha = (map['fecha'] as Timestamp).toDate();
    } else if (map['fecha'] is String) {
      // ✅ Si es un String, intentamos detectar su formato
      try {
        if (map['fecha'].contains('/')) {
          // Si tiene "/", asumimos formato `dd/MM/yyyy`
          fecha = DateFormat('dd/MM/yyyy').parse(map['fecha']);
        } else if (map['fecha'].contains('-')) {
          // Si tiene "-", asumimos formato `yyyy-MM-dd`
          fecha = DateFormat('yyyy-MM-dd').parse(map['fecha']);
        } else {
          throw FormatException('Formato de fecha desconocido');
        }
      } catch (e) {
        fecha = DateTime.now(); // Evita errores si la fecha no es válida
      }
    } else {
      fecha = DateTime.now();
    }

    return Ingreso(
      id: map['id'].toString(), // Convertir a String directamente
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
      'fecha': fechaFormateada, // ✅ Guardar siempre en formato `dd/MM/yyyy`
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
