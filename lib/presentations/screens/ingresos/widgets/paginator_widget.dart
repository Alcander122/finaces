// файл: paginator_widget.dart
import 'package:flutter/material.dart';

class PaginatorWidget extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final Function(int) onPageChanged;
  final Function(int) onItemsPerPageChanged;

  const PaginatorWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
  });

  @override
  State<PaginatorWidget> createState() => _PaginatorWidgetState();
}

class _PaginatorWidgetState extends State<PaginatorWidget> {
  late final List<int> _itemsPerPageOptions = [5, 10, 20, 50];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Mostrando ${widget.itemsPerPage} ...'),
        DropdownButton<int>(
          value: widget.itemsPerPage,
          items: _itemsPerPageOptions.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option.toString()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onItemsPerPageChanged(value);
            }
          },
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: widget.currentPage > 1
              ? () => widget.onPageChanged(widget.currentPage - 1)
              : null,
        ),
        Text('${widget.currentPage}/${widget.totalPages}'),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: widget.currentPage < widget.totalPages
              ? () => widget.onPageChanged(widget.currentPage + 1)
              : null,
        ),
      ],
    );
  }
}
