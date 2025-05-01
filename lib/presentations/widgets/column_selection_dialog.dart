import 'package:flutter/material.dart';

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
      title: const Text('Seleccionar Columnas'),
      content: SingleChildScrollView(
        child: Column(
          children: widget.allColumns.map((column) {
            return CheckboxListTile(
              title: Text(column),
              value: tempSelectedColumns.contains(column),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    tempSelectedColumns.add(column);
                  } else {
                    tempSelectedColumns.remove(column);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, tempSelectedColumns);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
