import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DialogoSeleccionarBanco extends StatefulWidget {
  final Function(BancoModelo) onSeleccionar;

  const DialogoSeleccionarBanco({
    super.key,
    required this.onSeleccionar,
  });

  @override
  State<DialogoSeleccionarBanco> createState() => _DialogoSeleccionarBancoState();
}

class _DialogoSeleccionarBancoState extends State<DialogoSeleccionarBanco> {
  List<BancoModelo> bancosDisponibles = [];
  final TextEditingController _searchController = TextEditingController();
  List<BancoModelo> filteredBancos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanksFromJson();
  }

  Future<void> _loadBanksFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/bancos_colombia.json');
      final List<dynamic> jsonResponse = json.decode(response);
      
      setState(() {
        bancosDisponibles = jsonResponse.asMap().entries.map((entry) {
          return BancoModelo(
            id: (entry.key + 1).toString(),
            nombre: entry.value.toString(),
            numeroCuenta: '',
            userId: '',
          );
        }).toList();
        
        filteredBancos = bancosDisponibles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        filteredBancos = [];
      });
      // Manejo de errores en la carga de datos
    }
  }

  void _filterBanks(String query) {
    setState(() {
      filteredBancos = bancosDisponibles.where((banco) {
        return banco.nombre.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona tu banco'),
      content: SizedBox(
        width: double.maxFinite, // Ancho máximo para evitar restricciones ambiguas
        height: 300, // Altura fija para evitar cálculos de dimensiones intrínsecas
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            // Vista condicional para resultados vacíos
            if (!_isLoading && filteredBancos.isEmpty)
              const Text('No se encontraron bancos'),
            // Lista de resultados con scroll manual
            if (!_isLoading && filteredBancos.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: filteredBancos.map((banco) {
                      return ListTile(
                        title: Text(banco.nombre),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSeleccionar(banco);
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