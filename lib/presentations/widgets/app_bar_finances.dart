import 'package:flutter/material.dart';

class AppBarFinances extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileAction; // Nuevo parámetro para controlar la acción
  final bool showBackButton;

  const AppBarFinances({ 
    super.key,
    required this.title,
    this.showBackButton = false, // Valor predeterminado: no mostrar
    this.showProfileAction = false, // Por defecto no se muestra
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0B0D39),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            )
          : null, // Aquí implementamos el botón de regreso
      actions: showProfileAction
          ? [
              IconButton(
                icon: const Icon(Icons.account_circle),
                color: Colors.white,
                iconSize: 28,
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ]
          : null,
      elevation: 4,
      shadowColor: Colors.black,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}