import 'package:flutter/material.dart';

//Estructura para los colores del diseño KUPI.
class Themes {
  static const Color primary = Color(0xFF003366);
  static const Color light = Color(0xFFd6eaf8);
  static const Color greyDisabled = Color(0xFFE0E0E0);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  //static const Color infoBlue = Color(0xFF1E88E5);
  static const iconColor = Color(0xFF808080);
  static const Color degradientDark = Color(0xFF003366);
  static const Color degradientLight = Color(0xFF006699);
  static const Color infoBlue = Color(0xFFEAF6FF);
  static const Color iconsButton = Color(0xFF2d2e87);
}

//Estructura para las fuentes del diseño KUPI.
class TextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Themes.black,
  );

  static const TextStyle subTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Themes.black,
  );

  static const TextStyle smallText = TextStyle(
    fontSize: 14,
    color: Themes.black,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  static const TextStyle info = TextStyle(
    fontSize: 14,
    color: Themes.infoBlue,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Themes.black,
  );

  static const TextStyle saldoText =
      TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold);

  static const TextStyle confirmSaldo = TextStyle(
      fontSize: 14, color: Themes.iconsButton, fontWeight: FontWeight.bold);
}
