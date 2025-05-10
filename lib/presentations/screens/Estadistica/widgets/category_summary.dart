import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Widget para el resumen por categoría
class CategorySummary extends StatelessWidget {
  const CategorySummary({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                // Removed 'const' from PieChart
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.red,
                        value: 30,
                        title: 'Comida',
                        radius: 30,
                      ),
                      PieChartSectionData(
                        color: Colors.green,
                        value: 20,
                        title: 'Transporte',
                        radius: 30,
                      ),
                      PieChartSectionData(
                        color: Colors.blue,
                        value: 50,
                        title: 'Ocio',
                        radius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.food_bank, color: Colors.red, size: 15),
                        const SizedBox(width: 5),
                        const Text('Comida: 30%', style: TextStyle(fontSize: 12),),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: Colors.green, size: 15),
                        const SizedBox(width: 5),
                        const Text('Transporte: 20%', style: TextStyle(fontSize: 12),),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.movie, color: Colors.blue, size: 15),
                        const SizedBox(width: 5),
                        const Text('Ocio: 50%', style: TextStyle(fontSize: 12),),
                      ],
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