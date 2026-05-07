import 'dart:io'; // Detectar plataforma (Android/iOS)
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:google_mobile_ads/google_mobile_ads.dart'; // SDK de anuncios

class AdService {
  // Singleton (una sola instancia en toda la app)
  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;

  AdService._internal();

  // Control para usar anuncios de prueba o reales
  static const bool isTestMode = true;

  // Variable que guarda el anuncio interstitial
  InterstitialAd? _interstitialAd;

  // ID del banner
  static String get bannerAdUnitId {
    // Si estamos en modo prueba
    if (isTestMode) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }

    // ID real de producción Android
    if (Platform.isAndroid) {
      return 'ca-app-pub-6536574784899409/5087872422';
    }

    throw UnsupportedError('Plataforma no soportada');
  }

  // ID del interstitial
  static String get interstitialAdUnitId {
    if (isTestMode) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }

    if (Platform.isAndroid) {
      return 'TU_ID_REAL_INTERSTITIAL';
    }

    throw UnsupportedError('Plataforma no soportada');
  }

  // Cargar anuncio interstitial en background
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(), // solicitud básica
      adLoadCallback: InterstitialAdLoadCallback(
        // Si carga correctamente
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },

        // Si falla
        onAdFailedToLoad: (error) {
          debugPrint('Error cargando interstitial: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  // Mostrar anuncio interstitial
  void showInterstitialAd({required bool isPremium}) {
    // Si es premium, no mostrar anuncios
    if (isPremium) return;

    // Si no está cargado
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return;
    }

    // Configurar eventos del anuncio
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      // Cuando se cierra el anuncio
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose(); // liberar memoria
        loadInterstitialAd(); // cargar nuevo
      },

      // Si falla al mostrar
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
      },
    );

    // Mostrar anuncio
    _interstitialAd!.show();

    // Limpiar referencia
    _interstitialAd = null;
  }
}
