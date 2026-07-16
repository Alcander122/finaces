import 'package:flutter/foundation.dart';
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

  bool _isCreatingAd = false;

  @override
  void initState() {
    super.initState();
    _loadAdIfNeeded();
  }

  void _loadAdIfNeeded() {
    final isPremium = ref.read(premiumProvider);
    if (isPremium) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
      return;
    }

    if (_bannerAd != null || _isCreatingAd) return;

    _isCreatingAd = true;
    _bannerAd = BannerAd(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111' // ID de prueba de Google
          : 'ca-app-pub-6536574784899409/5087872422', // ID de producción real (Banner_Home)
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
            _isCreatingAd = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('SmartAdBanner: Error al cargar anuncio: $error (Código: ${error.code}, Mensaje: ${error.message})');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _isCreatingAd = false;
          });
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);

    if (isPremium || _bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 15),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
