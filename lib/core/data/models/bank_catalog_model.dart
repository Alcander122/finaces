// bank_catalog_model.dart
/// DTO (Data Transfer Object) que representa un banco disponible en el catálogo de la app.
class BankCatalogModel {
  final String id;
  final String nombre;
  final List<String> aliases;
  final String pais;
  final String logoUrl;
  final String colorPrincipal;
  final String colorSecundario;
  final String categoria;
  final bool activo;
  final bool soporteTransferencia;
  final bool soportePse;
  final List<String> tipoCuentaSoportada;
  final int popularidad;

  BankCatalogModel({
    required this.id,
    required this.nombre,
    required this.aliases,
    required this.pais,
    required this.logoUrl,
    required this.colorPrincipal,
    required this.colorSecundario,
    required this.categoria,
    required this.activo,
    required this.soporteTransferencia,
    required this.soportePse,
    required this.tipoCuentaSoportada,
    required this.popularidad,
  });

  factory BankCatalogModel.fromJson(Map<String, dynamic> json) {
    return BankCatalogModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Banco desconocido',
      aliases: (json['aliases'] as List?)?.map((e) => e.toString()).toList() ?? [],
      pais: json['pais'] as String? ?? 'CO',
      logoUrl: json['logoUrl'] as String? ?? '',
      colorPrincipal: json['colorPrincipal'] as String? ?? '#003366',
      colorSecundario: json['colorSecundario'] as String? ?? '#FFFFFF',
      categoria: json['categoria'] as String? ?? 'banco',
      activo: json['activo'] as bool? ?? true,
      soporteTransferencia: json['soporteTransferencia'] as bool? ?? true,
      soportePse: json['soportePse'] as bool? ?? true,
      tipoCuentaSoportada: (json['tipoCuentaSoportada'] as List?)?.map((e) => e.toString()).toList() ?? ['ahorros'],
      popularidad: json['popularidad'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'aliases': aliases,
      'pais': pais,
      'logoUrl': logoUrl,
      'colorPrincipal': colorPrincipal,
      'colorSecundario': colorSecundario,
      'categoria': categoria,
      'activo': activo,
      'soporteTransferencia': soporteTransferencia,
      'soportePse': soportePse,
      'tipoCuentaSoportada': tipoCuentaSoportada,
      'popularidad': popularidad,
    };
  }
}
