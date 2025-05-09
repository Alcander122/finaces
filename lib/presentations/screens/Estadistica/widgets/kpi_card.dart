import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final IconData icon;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: progress > 0.5 ? Colors.green : Colors.red),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}