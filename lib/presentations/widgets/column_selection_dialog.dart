import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/themes.dart';

class ColumnSelectionDialog extends StatefulWidget {
  final Set<String> selectedColumns;
  final List<String> allColumns;

  const ColumnSelectionDialog({
    super.key,
    required this.selectedColumns,
    required this.allColumns,
  });

  @override
  ColumnSelectionDialogState createState() => ColumnSelectionDialogState();
}

class ColumnSelectionDialogState extends State<ColumnSelectionDialog> {
  late Set<String> tempSelectedColumns;

  @override
  void initState() {
    super.initState();
    tempSelectedColumns = Set.from(widget.selectedColumns);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Themes.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      title: Column(
        children: [
          const Icon(Icons.view_column_rounded, color: Themes.primary, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Filtro de Gastos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona las columnas visibles',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.allColumns.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
          itemBuilder: (context, index) {
            final column = widget.allColumns[index];
            final isSelected = tempSelectedColumns.contains(column);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                column,
                style: TextStyle(
                  color: isSelected ? Themes.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              activeColor: Themes.primary,
              checkColor: Colors.white,
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    tempSelectedColumns.add(column);
                  } else {
                    tempSelectedColumns.remove(column);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, tempSelectedColumns),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Themes.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
