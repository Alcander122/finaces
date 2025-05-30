import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRScreen extends StatelessWidget {
  final String data;

  const QRScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Código QR")),
      body: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 280.0,
          gapless: false,
        ),
      ),
    );
  }
}
