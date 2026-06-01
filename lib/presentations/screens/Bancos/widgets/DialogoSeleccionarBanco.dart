// 🎨 presentations/screens/Bancos/widgets/DialogoSeleccionarBanco.dart
// ============================================================================
// DIÁLOGO: Selección de bancos premium con buscador reactivo e insights populares
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/bank_catalog_model.dart';
import 'package:finances/core/data/providers/bank_provider.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/presentations/theme/themes.dart';

class DialogoSeleccionarBanco extends ConsumerStatefulWidget {
  final Function(String) onSeleccionar; // Devuelve el nombre del banco
  const DialogoSeleccionarBanco({
    super.key,
    required this.onSeleccionar,
  });

  @override
  ConsumerState<DialogoSeleccionarBanco> createState() =>
      _DialogoSeleccionarBancoState();
}

class _DialogoSeleccionarBancoState extends ConsumerState<DialogoSeleccionarBanco> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos'; // 'Todos', 'banco', 'wallet', 'cooperativa'

  @override
  void initState() {
    super.initState();
    // Limpiamos el query de búsqueda al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bankSearchQueryProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hexString, {Color fallback = Themes.primary}) {
    try {
      final String formatted = hexString.replaceAll('#', '');
      if (formatted.length == 6) {
        return Color(int.parse('FF$formatted', radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(filteredCatalogProvider);
    final String query = ref.watch(bankSearchQueryProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 420,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado Premium
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                color: Themes.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Selecciona tu Banco',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
            ),

            // Buscador e Inputs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o alias...',
                  prefixIcon: const Icon(Icons.search, color: Themes.primary),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(bankSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Themes.primary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  ref.read(bankSearchQueryProvider.notifier).state = val;
                },
              ),
            ),

            // Contenido Principal
            Flexible(
              child: catalogAsync.when(
                data: (bancos) {
                  // Filtrar por categoría localmente para rendimiento fluido
                  final filtrados = _selectedCategory == 'Todos'
                      ? bancos
                      : bancos.where((b) => b.categoria == _selectedCategory).toList();

                  // Separar bancos populares (popularidad >= 6) solo si no hay búsqueda activa
                  final populares = query.isEmpty
                      ? filtrados.where((b) => b.popularidad >= 6).toList()
                      : <BankCatalogModel>[];

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Fila de Chips de Categorías
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryChip('Todos', 'Todos'),
                                const SizedBox(width: 8),
                                _buildCategoryChip('Bancos', 'banco'),
                                const SizedBox(width: 8),
                                _buildCategoryChip('Billeteras', 'wallet'),
                                const SizedBox(width: 8),
                                _buildCategoryChip('Cooperativas', 'cooperativa'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. Bancos Populares (Solo si el buscador está vacío)
                        if (populares.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Más utilizados',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 82,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: populares.length,
                              itemBuilder: (context, index) {
                                final b = populares[index];
                                final Color brandColor = _parseHexColor(b.colorPrincipal);
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onSeleccionar(b.nombre);
                                  },
                                  child: Container(
                                    width: 72,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: brandColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: brandColor.withOpacity(0.2),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              )
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              b.nombre.substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          b.nombre,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 24, indent: 20, endIndent: 20),
                        ],

                        // 3. Catálogo Principal
                        if (filtrados.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No se encontraron entidades.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final b = filtrados[index];
                              final Color brandColor = _parseHexColor(b.colorPrincipal);
                              final String tagText = b.categoria == 'wallet'
                                  ? 'Billetera'
                                  : b.categoria == 'cooperativa'
                                      ? 'Cooperativa'
                                      : 'Banco';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: brandColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      b.nombre.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  b.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  tagText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onSeleccionar(b.nombre);
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator(color: Themes.primary)),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '${ErrorStrings.loadFailed}\n$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),

            // Cancelar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final bool isSelected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
      selectedColor: Themes.primary.withOpacity(0.15),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Themes.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}
