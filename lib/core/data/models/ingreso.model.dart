// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class Ingreso {
  int id; // Consecutivo único
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

  // Conversión desde un Map (Firestore o similar) a un objeto `Ingreso`
  factory Ingreso.fromMap(Map<String, dynamic> map) {
    return Ingreso(
      id: map['id'],
      fecha: (map['fecha'] as Timestamp).toDate(),
      mes: map['mes'],
      anio: map['anio'],
      quincena: map['quincena'],
      categoria: map['categoria'],
      concepto: map['concepto'],
      valor: map['valor'].toInt(), // Asegura que se convierta a un valor entero
    );
  }

  // Conversión desde un objeto `Ingreso` a un Map (para Firestore o similar)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'mes': mes,
      'anio': anio,
      'quincena': quincena,
      'categoria': categoria,
      'concepto': concepto,
      'valor': valor, // Guardamos el valor como entero
    };
  }
}
