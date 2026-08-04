import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/theme.dart';

class ReusableCardTable extends StatelessWidget {
  final Widget child;
  final double topBandHeight;
  final Color topColorStart;
  final Color topColorEnd;

  const ReusableCardTable({
    super.key,
    required this.child,
    this.topBandHeight = 72,
    required this.topColorStart,
    required this.topColorEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: context.cardBgColor,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: topBandHeight,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        topColorStart,
                        topColorEnd,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
