import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Diálogo que permite al usuario seleccionar un banco de la lista disponible
///
/// IMPORTANTE: Este diálogo NO DEBE usar BancoModelo para la selección inicial
/// porque los bancos disponibles son datos genéricos SIN RELACIÓN CON USUARIOS
///
/// PROBLEMA ORIGINAL:
/// Se intentaba crear instancias de BancoModelo con userId vacío, violando
/// la aserción del modelo que exige userId no vacío
///
/// SOLUCIÓN CORRECTA:
/// 1. Usar solo strings para representar los nombres de bancos disponibles
/// 2. Solo crear BancoModelo completo cuando el usuario haya seleccionado
///    un banco y tengamos el userId real
class DialogoSeleccionarBanco extends StatefulWidget {
  final Function(String) onSeleccionar; // Solo devuelve el NOMBRE del banco
  const DialogoSeleccionarBanco({
    super.key,
    required this.onSeleccionar,
  });
  @override
  State<DialogoSeleccionarBanco> createState() =>
      _DialogoSeleccionarBancoState();
}

class _DialogoSeleccionarBancoState extends State<DialogoSeleccionarBanco> {
  // CAMBIO FUNDAMENTAL: Usamos strings, no BancoModelo
  List<String> bancosDisponibles = [];
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredBancos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanksFromJson();
  }

  /// Carga la lista de bancos desde un archivo JSON local
  ///
  /// IMPORTANTE:
  /// 1. Solo cargamos los nombres de los bancos como strings
  /// 2. NO intentamos crear BancoModelo aquí porque no hay userId
  /// 3. El JSON debe contener un array de strings: ["Banco A", "Banco B", ...]
  Future<void> _loadBanksFromJson() async {
    try {
      final String response =
          await rootBundle.loadString('assets/bancos_colombia.json');
      final List<dynamic> jsonResponse = json.decode(response);

      setState(() {
        // Validamos que el JSON contenga solo strings
        bancosDisponibles = jsonResponse
            .where((item) => item is String && item.isNotEmpty)
            .map((item) => item.toString())
            .toList();

        filteredBancos = bancosDisponibles;
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR CARGANDO BANCOS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error cargando lista de bancos: $e")));

      setState(() {
        _isLoading = false;
        filteredBancos = [];
      });
    }
  }

  /// Filtra los bancos según el texto de búsqueda
  void _filterBanks(String query) {
    setState(() {
      filteredBancos = bancosDisponibles.where((banco) {
        return banco.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona tu banco'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar banco',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterBanks,
            ),
            const SizedBox(height: 10),
            // Estado de carga
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            // Vista para resultados vacíos
            if (!_isLoading && filteredBancos.isEmpty)
              const Text('No se encontraron bancos'),
            // Lista de resultados con scroll
            if (!_isLoading && filteredBancos.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: filteredBancos.map((nombreBanco) {
                      return ListTile(
                        title: Text(nombreBanco),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSeleccionar(
                              nombreBanco); // Solo enviamos el nombre
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
      insetPadding: const EdgeInsets.all(20.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
