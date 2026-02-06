import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider global que expone el estado Premium (true/false) a toda la aplicación.
final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  // Suscripción al flujo de compras para reaccionar a los pagos en tiempo real.
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Instancia del plugin de compras de Flutter.
  final InAppPurchase _iap = InAppPurchase.instance;

  PremiumNotifier() : super(false) {
    // Al inicializar el provider, verificamos si el usuario ya es premium en la base de datos.
    _checkFirestoreStatus();
    // Empezamos a escuchar cualquier intento de compra o restauración.
    _listenToPurchases();
  }

  // ===========================================================================
  // 1. VERIFICACIÓN INICIAL
  // ===========================================================================

  /// Consulta Firestore para ver si el usuario actual tiene el campo 'isPremium' en true.
  Future<void> _checkFirestoreStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Si el documento existe, actualizamos el estado con el valor de la DB.
        if (doc.exists) {
          state = doc.data()?['isPremium'] ?? false;
        }
      } catch (e) {
        debugPrint('Error al verificar estado premium en Firestore: $e');
      }
    }
  }

  // ===========================================================================
  // 2. ESCUCHA DE LA PASARELA DE PAGOS
  // ===========================================================================

  /// Se conecta al flujo de Google Play/App Store para procesar transacciones.
  void _listenToPurchases() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;

    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      for (var purchase in purchaseDetailsList) {
        // Si la compra fue exitosa o se restauró una compra previa:
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          // Activamos los beneficios premium en nuestra app y base de datos.
          _activatePremium();

          // Es vital completar la compra para que la tienda no reembolse el dinero automáticamente.
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        }

        // Manejo de errores en la transacción
        if (purchase.status == PurchaseStatus.error) {
          debugPrint('Error en la transacción: ${purchase.error}');
        }
      }
    }, onError: (error) {
      debugPrint('Error en el Stream de compras: $error');
    });
  }

  // ===========================================================================
  // 3. ACTIVACIÓN DE BENEFICIOS
  // ===========================================================================

  /// Actualiza Firestore y el estado local de Riverpod para eliminar los anuncios.
  Future<void> _activatePremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Guardamos el estado de forma permanente en la nube.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isPremium': true});

        // Cambiamos el estado local para que los anuncios desaparezcan instantáneamente.
        state = true;
        debugPrint('✨ Usuario activado como Premium correctamente.');
      } catch (e) {
        debugPrint('Error al activar premium en Firestore: $e');
      }
    }
  }

  // ===========================================================================
  // 4. INICIO DEL PROCESO DE COMPRA
  // ===========================================================================

  /// Dispara el modal de pago de la tienda (Google Play).
  Future<void> buyPremium() async {
    // Verificamos si la tienda está disponible en el dispositivo.
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('La tienda de aplicaciones no está disponible.');
      return;
    }

    // El ID debe coincidir exactamente con el que creaste en Google Play Console.
    const Set<String> kIds = {'remove_ads_premium'};

    // Obtenemos los detalles del producto (precio, moneda, etc.) desde la tienda.
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(kIds);

    if (response.productDetails.isNotEmpty) {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);

      // Iniciamos la compra de un producto "no consumible" (se compra una sola vez).
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      debugPrint(
          'No se encontró el producto "remove_ads_premium" en la tienda.');
    }
  }

  /// Permite a usuarios que ya pagaron recuperar su suscripción (útil al cambiar de móvil).
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error al restaurar compras: $e');
    }
  }

  @override
  void dispose() {
    // Cerramos la suscripción al Stream para evitar fugas de memoria (memory leaks).
    _subscription?.cancel();
    super.dispose();
  }
}
