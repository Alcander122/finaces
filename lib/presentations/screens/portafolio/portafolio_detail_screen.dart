import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/data/models/portafolio_model.dart';
import '../../../core/data/services/portafolio_service.dart';
import 'portafolio_form_screen.dart';

class PortafolioDetailScreen extends StatefulWidget {
  final Portafolio portafolio;

  const PortafolioDetailScreen({super.key, required this.portafolio});

  @override
  _PortafolioDetailScreenState createState() => _PortafolioDetailScreenState();
}

class _PortafolioDetailScreenState extends State<PortafolioDetailScreen> {
  final PortafolioService _service = PortafolioService();
  List<FlSpot> _puntos = [];

  @override
  void initState() {
    super.initState();
    // _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

  /* Future<void> _cargarDatos() async {
    List<Map<String, dynamic>> datos =
        await _service.obtenerInversionesHistoricas(widget.portafolio.id);

    List<FlSpot> puntos = datos.asMap().entries.map((entry) {
      int index = entry.key;
      double inversion = entry.value['monto'].toDouble();
      return FlSpot(index.toDouble(), inversion);
    }).toList();

    setState(() {
      _puntos = puntos;
    });
  }

  void _eliminarPortafolio(BuildContext context) {
    //_service.eliminarPortafolio(widget.portafolio.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalles de la Inversión")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Activo: ${widget.portafolio.activo}",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
                "Inversión Mensual: ${widget.portafolio.invMensual} ${widget.portafolio.moneda}"),
            Text("Estado: ${widget.portafolio.estado}"),
            Text(
                "Fecha de Inversión: ${widget.portafolio.fechaInversion.toLocal()}"),
            const SizedBox(height: 16),

            // 📊 Gráfico de inversión
            const Text("Evolución de la Inversión",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _puntos.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _puntos,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.3)),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 16),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PortafolioFormScreen(
                              portafolio: widget.portafolio)),
                    );
                  },
                  child: const Text("Editar"),
                ),
                ElevatedButton(
                  onPressed: () => _eliminarPortafolio(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Eliminar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }*/
}
