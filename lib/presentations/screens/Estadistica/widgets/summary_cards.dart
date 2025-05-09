import 'package:flutter/material.dart';

// Widget para las tarjetas de resumen
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryCard(
            title: 'Ingresos',
            value: '\$222.222',
            icon: Icons.arrow_upward,
            color: Colors.green,
          ),
          _buildSummaryCard(
            title: 'Gastos',
            value: '\$10.000',
            icon: Icons.arrow_downward,
            color: Colors.red,
          ),
          _buildSummaryCard(
            title: 'Balance',
            value: '\$212.222',
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  // Método para construir una tarjeta de resumen individual
  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}