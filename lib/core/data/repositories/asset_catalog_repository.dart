import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:finances/core/data/models/asset_catalog_model.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

class AssetCatalogRepository {
  static const String _assetPath = 'assets/tipos_activos.json';

  Future<List<AssetCatalogModel>> getCatalog() async {
    try {
      final String assetData = await rootBundle.loadString(_assetPath);
      final List<dynamic> decodedAsset = json.decode(assetData);
      return decodedAsset.map((item) => AssetCatalogModel.fromJson(item)).toList();
    } catch (e) {
      throw DbErrorHandler.handle(e);
    }
  }
}
