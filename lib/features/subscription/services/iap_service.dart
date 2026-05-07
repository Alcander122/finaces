import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/premium_provider.dart';

// ID del producto configurado en Google Play
const String _kProductId = 'premium_lifetime_ad_free';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;

  // Stream que escucha compras
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final Ref _ref;

  IAPService(this._ref);

  // Provider de productos disponibles
  final productsProvider = StateProvider<List<ProductDetails>>((ref) => []);

  // Indica si la tienda está disponible
  final isAvailableProvider = StateProvider<bool>((ref) => false);

  // Estado de compra en progreso
  final isPurchasingProvider = StateProvider<bool>((ref) => false);

  // Inicializa el servicio
  void initialize() {
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate);
    _loadProducts();
  }

  // Liberar recursos
  void dispose() {
    _subscription.cancel();
  }

  // Cargar productos desde Play Store
  Future<void> _loadProducts() async {
    final available = await _iap.isAvailable();

    _ref.read(isAvailableProvider.notifier).state = available;

    if (!available) return;

    final response = await _iap.queryProductDetails({_kProductId});

    _ref.read(productsProvider.notifier).state = response.productDetails;
  }

  // Comprar producto premium
  void buy(ProductDetails product) {
    _ref.read(isPurchasingProvider.notifier).state = true;

    final param = PurchaseParam(productDetails: product);

    _iap.buyNonConsumable(purchaseParam: param);
  }

  // Restaurar compras
  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  // Manejo de actualizaciones de compra
  void _onPurchaseUpdate(List<PurchaseDetails> list) {
    for (final purchase in list) {
      // Si la compra fue exitosa o restaurada
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _deliver(purchase);
      }

      // Confirmar compra con Google
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }

    _ref.read(isPurchasingProvider.notifier).state = false;
  }

  void buyPremium(ProductDetails productDetails) {
    _ref.read(isPurchasingProvider.notifier).state = true;
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    // Al ser un producto Lifetime, es un NonConsumable
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    _ref.read(isPurchasingProvider.notifier).state = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error restaurando compras: $e');
      _ref.read(isPurchasingProvider.notifier).state = false;
    }
  }

  // Entregar producto al usuario
  Future<void> _deliver(PurchaseDetails purchase) async {
    if (purchase.productID == _kProductId) {
      await _ref.read(premiumProvider.notifier).setPremiumStatus(true);
    }
  }
}

// Provider global del servicio
final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService(ref);

  service.initialize();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
