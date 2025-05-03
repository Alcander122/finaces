import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';




class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarFinances(
        title: 'Estadísticas Financieras', // Título de la pantalla
        showBackButton: true, // Muestra el botón de regreso
        showProfileAction: false, // Oculta el botón de perfil
      ),
      body: Center(
        child: Text('Statistics Screen Content'),
      ),
    );
  }
}