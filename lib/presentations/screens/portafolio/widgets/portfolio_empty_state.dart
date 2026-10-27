import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/theme.dart';

/// Widget reutilizable y accesible para estados vacíos en el módulo de portafolios.
class PortfolioEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final Widget? headerWidget;

  const PortfolioEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onButtonPressed,
    this.headerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (headerWidget != null) ...[
                headerWidget!,
                const SizedBox(height: 24),
              ],
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(context.isDarkMode ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: context.colors.primary,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: context.titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: context.isDarkMode
                            ? context.colors.onSurfaceVariant
                            : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onButtonPressed,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          buttonLabel,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
