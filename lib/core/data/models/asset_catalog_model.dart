class AssetCatalogModel {
  final String id;
  final String nombre;
  final String categoria;
  final String riesgo;
  final bool activo;
  final int popularidad;

  AssetCatalogModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.riesgo,
    required this.activo,
    required this.popularidad,
  });

  factory AssetCatalogModel.fromJson(Map<String, dynamic> json) {
    return AssetCatalogModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Activo Desconocido',
      categoria: json['categoria'] as String? ?? 'Otros',
      riesgo: json['riesgo'] as String? ?? 'Variable',
      activo: json['activo'] as bool? ?? true,
      popularidad: json['popularidad'] as int? ?? 1,
    );
  }
}
