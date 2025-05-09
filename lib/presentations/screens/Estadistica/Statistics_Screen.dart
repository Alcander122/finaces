import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/summary_cards.dart';
import 'widgets/activity_chart.dart';
import 'widgets/category_summary.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarFinances(
        title: 'Estadísticas Financieras', // Título de la pantalla
        showBackButton: true, // Muestra el botón de regreso
        showProfileAction: false, // Oculta el botón de perfil
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la vista
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Estadísticas Financieras',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            
            // Tarjetas de resumen
            const SizedBox(height: 20),
            const SummaryCards(),
            
            // Gráfico de actividad financiera
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Actividad Financiera',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            const ActivityChart(),
            
            // Resumen por categoría
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Resumen por Categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            const CategorySummary(),
          ],
        ),
      ),
    );
  }
}