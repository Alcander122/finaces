import 'package:flutter/material.dart';

class AppBarFinances extends StatelessWidget implements PreferredSizeWidget {
  const AppBarFinances({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0B0D39),
      centerTitle: true,
      title: const Text(
        'Finanzas Personales',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          color: Colors.white, // Ícono en blanco
          iconSize: 28,
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ],
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
