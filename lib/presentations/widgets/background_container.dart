import 'package:flutter/material.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;
  final String backgroundImagePath;
  final Color overlayColor;

  const BackgroundContainer({
    super.key,
    required this.child,
    required this.backgroundImagePath,
    this.overlayColor = const Color(0xCCD6EAF8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImagePath),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Container(
        color: overlayColor,
        child: child,
      ),
    );
  }
}
