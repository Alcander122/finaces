import 'package:flutter/material.dart';

class MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const MenuOption({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 30),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold), // Reducido a 14
      ),
      onTap: onTap,
    );
  }
}
