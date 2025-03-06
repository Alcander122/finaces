// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class Portafolio {
  final String id;
  final String userId;
  final String nombre;
  final String? descripcion;
  final DateTime fechaCreacion;
  final String nota;

  Portafolio({
    required this.id,
    required this.userId,
    required this.nombre,
    this.descripcion,
    required this.fechaCreacion,
    required this.nota,
  });

  factory Portafolio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Portafolio(
      id: doc.id,
      userId: data['userId'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'],
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      nota: data['nota'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'nombre': nombre,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion,
      'nota': nota,
    };
  }
}
