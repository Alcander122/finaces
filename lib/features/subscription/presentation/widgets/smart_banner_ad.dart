import 'package:finances/core/data/providers/premium_provider.dart';
import 'package:finances/features/subscription/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Widget que muestra banner inteligente
class SmartBannerAd extends ConsumerStatefulWidget {
  const SmartBannerAd({super.key});

  @override
  ConsumerState<SmartBannerAd> createState() => _SmartBannerAdState();
}

class _SmartBannerAdState extends ConsumerState<SmartBannerAd> {
  BannerAd? _bannerAd; // instancia del banner
  bool _isLoaded = false; // indica si cargó

  // Método para cargar anuncio
  void _loadAd() {
    if (_bannerAd != null) return; // evitar duplicados

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),

      // Eventos del anuncio
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // liberar memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar estado premium
    final isPremium = ref.watch(premiumProvider);

    // Si es premium → no mostrar nada
    if (isPremium) {
      _bannerAd?.dispose();
      _bannerAd = null;
      return const SizedBox.shrink();
    }

    // Si no existe, cargar
    if (_bannerAd == null) {
      _loadAd();
    }

    // Si no está listo
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    // Mostrar anuncio
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
