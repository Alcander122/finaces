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

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quincena': quincena,
      'fecha': fecha.toIso8601String(),
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

  // Convertir desde Map (Firebase)
  factory Egreso.fromMap(Map<String, dynamic> map) {
    return Egreso(
      id: map['id'],
      quincena: map['quincena'],
      fecha: DateTime.parse(map['fecha']),
      mes: map['mes'],
      dia: map['dia'],
      anio: map['anio'],
      categoria: map['categoria'],
      concepto: map['concepto'],
      valor: map['valor'],
      descripcion: map['descripcion'],
      estado: map['estado'],
    );
  }

  // Método copyWith
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
