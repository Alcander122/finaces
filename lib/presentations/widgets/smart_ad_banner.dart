import 'package:flutter/foundation.dart'; // 🚀 Necesario para kReleaseMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/data/providers/premium_provider.dart';

class SmartAdBanner extends ConsumerStatefulWidget {
  const SmartAdBanner({super.key});

  @override
  ConsumerState<SmartAdBanner> createState() => _SmartAdBannerState();
}

class _SmartAdBannerState extends ConsumerState<SmartAdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 🛡️ Lógica de selección de ID automática
  // Si la app está en modo "Release" (Play Store), usa tu ID real.
  // Si estás programando (Debug), usa el ID de prueba de Google.
  final String adUnitId = kReleaseMode
      ? 'ca-app-pub-6536574784899409/6209842510' // ID REAL (BillNance)
      : 'ca-app-pub-3940256099942544/6300978111'; // ID DE PRUEBA

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPremium = ref.watch(premiumProvider);

    if (!isPremium && _bannerAd == null) {
      _loadAd();
    } else if (isPremium && _bannerAd != null) {
      _disposeAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob Error ($adUnitId): $error');
          _disposeAd();
        },
      ),
    )..load();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) setState(() => _isLoaded = false);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(premiumProvider) || _bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }
}
