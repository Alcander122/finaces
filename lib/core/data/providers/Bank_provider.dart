// bank_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_catalog_model.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/core/data/repositories/bank_catalog_repository.dart';
import 'package:finances/core/data/utils/banks_repository.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

// ============================================================================
// 1. REPOSITORIOS
// ============================================================================

/// Proveedor para el repositorio de cuentas bancarias vinculadas (Firebase Firestore)
final banksRepositoryProvider = Provider<BanksRepository>((ref) => BanksRepository());

/// Proveedor para el repositorio del catálogo de bancos (JSON + Cache Local)
final bankCatalogRepositoryProvider = Provider<BankCatalogRepository>((ref) => BankCatalogRepository());

// ============================================================================
// 2. PROVIDERS DEL CATÁLOGO BANCARIO
// ============================================================================

/// Proveedor que expone el catálogo completo de bancos disponibles
final bankCatalogProvider = FutureProvider<List<BankCatalogModel>>((ref) async {
  final repository = ref.watch(bankCatalogRepositoryProvider);
  return repository.getCatalog();
});

/// Proveedor del término de búsqueda ingresado por el usuario
final bankSearchQueryProvider = StateProvider<String>((ref) => '');

/// Proveedor que filtra y ordena inteligentemente el catálogo de bancos
/// Soporta: búsqueda por nombre, búsqueda difusa por 'aliases' y ordenamiento por popularidad.
final filteredCatalogProvider = Provider<AsyncValue<List<BankCatalogModel>>>((ref) {
  final catalogAsync = ref.watch(bankCatalogProvider);
  final searchQuery = ref.watch(bankSearchQueryProvider).trim().toLowerCase();

  return catalogAsync.whenData((catalog) {
    // 1. Filtrar los bancos inactivos
    final activos = catalog.where((b) => b.activo).toList();

    if (searchQuery.isEmpty) {
      // Ordenar por popularidad de mayor a menor por defecto
      activos.sort((a, b) => b.popularidad.compareTo(a.popularidad));
      return activos;
    }

    // 2. Búsqueda inteligente por nombre exacto o aliases de búsqueda
    final resultados = activos.where((banco) {
      final coincideNombre = banco.nombre.toLowerCase().contains(searchQuery);
      final coincideAlias = banco.aliases.any((alias) => alias.toLowerCase().contains(searchQuery));
      return coincideNombre || coincideAlias;
    }).toList();

    // Ordenar resultados por popularidad
    resultados.sort((a, b) => b.popularidad.compareTo(a.popularidad));
    return resultados;
  });
});

// ============================================================================
// 3. STREAM EN TIEMPO REAL CON ENRIQUECIMIENTO DINÁMICO DE MARCA
// ============================================================================

/// Observa las cuentas bancarias configuradas por el usuario en tiempo real
/// y les inyecta automáticamente los metadatos de marca (colores, logos)
/// correspondientes del catálogo de bancos local.
final userBanksProvider = StreamProvider.family<List<BancoModelo>, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(banksRepositoryProvider);
  final catalogAsync = ref.watch(bankCatalogProvider);

  return repository.getBanksByUserId(userId).map((bancosUsuario) {
    final catalog = catalogAsync.value ?? [];

    return bancosUsuario.map((banco) {
      // Intentar mapear por coincidencia de nombre en catálogo
      final catalogMatch = catalog.firstWhere(
        (c) => c.nombre.toLowerCase() == banco.nombre.toLowerCase(),
        orElse: () => BankCatalogModel(
          id: '',
          nombre: banco.nombre,
          aliases: [],
          pais: 'CO',
          logoUrl: '',
          colorPrincipal: '#003366', // Azul por defecto si no se encuentra
          colorSecundario: '#FFFFFF',
          categoria: 'banco',
          activo: true,
          soporteTransferencia: true,
          soportePse: true,
          tipoCuentaSoportada: ['ahorros'],
          popularidad: 1,
        ),
      );

      // Retornar clon enriquecido reactivamente
      return banco.copyWith(
        colorPrincipal: catalogMatch.colorPrincipal,
        colorSecundario: catalogMatch.colorSecundario,
        logoUrl: catalogMatch.logoUrl,
        categoria: catalogMatch.categoria,
        aliases: catalogMatch.aliases,
        soporteTransferencia: catalogMatch.soporteTransferencia,
        soportePse: catalogMatch.soportePse,
      );
    }).toList();
  });
});

// ============================================================================
// 4. CONTROLADOR DE MUTACIONES (AsyncNotifier)
// ============================================================================

/// Controlador inmutable para realizar operaciones de escritura, edición y eliminación de bancos.
/// Centraliza la prevención del doble submit y el control de excepciones con DbErrorHandler.
class BancoController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Estado inicial pasivo
  }

  /// Vincula una nueva cuenta de banco
  Future<void> crearBanco(BancoModelo banco) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(banksRepositoryProvider);
      await repository.crearBanco(banco);
    });
    state = result;
    if (result.hasError) {
      throw DbErrorHandler.handle(result.error);
    }
  }

  /// Actualiza los detalles de una cuenta vinculada
  Future<void> actualizarBanco(BancoModelo banco) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(banksRepositoryProvider);
      await repository.actualizarBanco(banco);
    });
    state = result;
    if (result.hasError) {
      throw DbErrorHandler.handle(result.error);
    }
  }

  /// Desvincula una cuenta bancaria
  Future<void> eliminarBanco(String bancoId, String userId) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(banksRepositoryProvider);
      await repository.eliminarBanco(bancoId, userId);
    });
    state = result;
    if (result.hasError) {
      throw DbErrorHandler.handle(result.error);
    }
  }
}

/// Proveedor global para el controlador de bancos
final bancoControllerProvider = AsyncNotifierProvider<BancoController, void>(() {
  return BancoController();
});
