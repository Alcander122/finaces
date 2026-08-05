// tutorial_page_widget.dart (CORREGIDO Y COMENTADO)
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget reutilizable que representa una página del tutorial.
class TutorialPageWidget extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String description;
  final Color iconColor;

  const TutorialPageWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Círculo con ícono
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                  alpha: 0.2), // ✅ CORRECTO: usamos withOpacity
              shape: BoxShape.circle,
            ),
            child: icon is FaIconData
                ? Center(
                    child: FaIcon(
                      icon,
                      size: 60,
                      color: iconColor,
                    ),
                  )
                : Icon(
                    icon,
                    size: 60,
                    color: iconColor,
                  ),
          ),
          const SizedBox(height: 40),
          // Título
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Descripción
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
