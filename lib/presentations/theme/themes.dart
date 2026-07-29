import 'package:flutter/material.dart';

// ============================================================================
// COLORES ESTÁTICOS DE MARCA KUPI
// Úsalos solo para elementos que NO cambian con el tema (badges, chips, íconos).
// Para textos y fondos que sí cambian, usa context.colors (ver theme.dart).
// ============================================================================
class Themes {
  static const Color primary = Color(0xFF003366);
  static const Color light = Color(0xFFd6eaf8);
  static const Color greyDisabled = Color(0xFFE0E0E0);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const iconColor = Color(0xFF808080);
  static const Color degradientDark = Color(0xFF003366);
  static const Color degradientLight = Color(0xFF006699);
  static const Color infoBlue = Color(0xFFEAF6FF);
  static const Color iconsButton = Color(0xFF2d2e87);
  static const Color green = Colors.green;
  static const Color red = Colors.red;
  static const Color blue = Colors.blue;
}

// ============================================================================
// ESTILOS DE TEXTO BASE (SIN COLOR FIJO)
// Los colores se aplican dinámicamente en cada widget usando .copyWith(color: ...)
// Ejemplo: TextStyles.title.copyWith(color: context.colors.onSurface)
// ============================================================================
class TextStyles {
  // Título principal — bold, 20px
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    // Sin color fijo: se define en el widget usando context.colors
  );

  // Subtítulo — normal, 16px
  static const TextStyle subTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  // Texto pequeño — 14px
  static const TextStyle smallText = TextStyle(
    fontSize: 14,
  );

  // Placeholder de campos de texto — siempre gris, no cambia con el tema
  static const TextStyle hint = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  // Texto informativo — siempre azul claro, no cambia con el tema
  static const TextStyle info = TextStyle(
    fontSize: 14,
    color: Themes.infoBlue,
  );

  // Texto de botón — bold, 16px
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Saldo principal — siempre blanco (se usa sobre gradientes oscuros)
  static const TextStyle saldoText =
      TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold);

  // Confirmación de saldo — color de marca, no cambia con el tema
  static const TextStyle confirmSaldo = TextStyle(
      fontSize: 14, color: Themes.iconsButton, fontWeight: FontWeight.bold);
}
