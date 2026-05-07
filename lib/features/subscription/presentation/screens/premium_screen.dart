import 'package:finances/core/data/providers/premium_provider.dart';
import 'package:finances/features/subscription/services/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instanciamos el servicio (esto inicializa la tienda si no lo estaba)
    final iapService = ref.watch(iapServiceProvider);

    // Escuchamos estados
    final isPremium = ref.watch(premiumProvider);
    final isAvailable = ref.watch(iapService.isAvailableProvider);
    final isPurchasing = ref.watch(iapService.isPurchasingProvider);
    final products = ref.watch(iapService.productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Versión Premium'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isPremium
              ? _buildAlreadyPremiumUI()
              : _buildSalesUI(
                  context, isAvailable, isPurchasing, products, iapService),
        ),
      ),
    );
  }

  Widget _buildAlreadyPremiumUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 100, color: Colors.amber),
          SizedBox(height: 24),
          Text(
            '¡Ya eres Premium!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Disfruta de la experiencia sin anuncios para siempre.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesUI(BuildContext context, bool isAvailable,
      bool isPurchasing, List products, IAPService iapService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.workspace_premium, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 24),
        const Text(
          'Elimina los anuncios',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Adquiere la versión Premium y disfruta de una experiencia limpia, rápida y sin interrupciones con un único pago de por vida.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 48),

        // Lista de Ventajas
        _buildAdvantageRow(
            Icons.block, 'Cero Anuncios', 'Ni banners ni videos sorpresa.'),
        const SizedBox(height: 16),
        _buildAdvantageRow(Icons.all_inclusive, 'Pago Único',
            'Para siempre, sin suscripciones.'),
        const Spacer(),

        // Controles de Compra
        if (isPurchasing)
          const Center(child: CircularProgressIndicator())
        else if (!isAvailable)
          const Center(
            child: Text(
              'La tienda no está disponible en este momento.',
              style: TextStyle(color: Colors.red),
            ),
          )
        else if (products.isEmpty)
          const Center(
            child: Text('Cargando productos de la tienda...'),
          )
        else
          ...products.map((product) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => iapService.buyPremium(product),
              child: Text(
                'Comprar Premium por ${product.price}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }),

        const SizedBox(height: 16),

        // Botón para restaurar compras
        if (!isPurchasing)
          TextButton(
            onPressed: () => iapService.restorePurchases(),
            child: const Text('Restaurar Compras Existentes'),
          )
      ],
    );
  }

  Widget _buildAdvantageRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
