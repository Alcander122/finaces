class Egreso {
  final String id;
  final String quincena;
  final DateTime fecha;
  final String mes;
  final int dia;
  final int anio;
  final String categoria;
  final String concepto;
  final int valor;
  final String descripcion;
  final String estado;

  Egreso({
    required this.id,
    required this.quincena,
    required this.fecha,
    required this.mes,
    required this.dia,
    required this.anio,
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
      'fecha': fecha.toIso8601String(), // Convertir DateTime a String
      'mes': mes,
      'dia': dia,
      'anio': anio,
      'categoria': categoria,
      'concepto': concepto,
      'valor': valor,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  // Crear una instancia de Egreso a partir de un Map (Firestore)
  static Egreso fromMap(Map<String, dynamic> map) {
    return Egreso(
      id: map['id'] ?? '', // Valor predeterminado si no existe
      quincena: map['quincena'] ?? '',
      fecha: DateTime.parse(map['fecha']), // Convertir String a DateTime
      mes: map['mes'] ?? '',
      dia: map['dia'] is int ? map['dia'] : 0,
      anio: map['anio'] is int ? map['anio'] : 0,
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
    String? mes,
    int? dia,
    int? anio,
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
      mes: mes ?? this.mes,
      dia: dia ?? this.dia,
      anio: anio ?? this.anio,
      categoria: categoria ?? this.categoria,
      concepto: concepto ?? this.concepto,
      valor: valor ?? this.valor,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
    );
  }
}
