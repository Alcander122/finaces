// 🎨 presentations/screens/Bancos/widgets/DialogoLlaves.dart
// ============================================================================
// DIÁLOGO: Formulario para vincular llaves bancarias con prevención de doble submit
// ============================================================================

import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/presentations/theme/themes.dart';

class DialogoLlaves extends StatefulWidget {
  final BancoModelo banco;
  final List<TextEditingController> controladores;
  final Future<void> Function() onGuardar; // Callback asíncrono seguro

  const DialogoLlaves({
    super.key,
    required this.banco,
    required this.controladores,
    required this.onGuardar,
  });

  @override
  State<DialogoLlaves> createState() => _DialogoLlavesState();
}

class _DialogoLlavesState extends State<DialogoLlaves> {
  final _formKey = GlobalKey<FormState>();
  List<String> _errores = List.filled(3, '');
  int _numeroLlaves = 1;
  bool _isSaving = false;

  static const int MAX_LLAVES = 3;
  static const int MIN_LLAVES = 1;
  static const int LONGITUD_MINIMA_LLAVE = 5;
  static const int? LONGITUD_MAXIMA_LLAVE = 25;

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _determinarNumeroInicialLlaves();
  }

  void _inicializarControladores() {
    for (int i = 0; i < 3; i++) {
      if (widget.controladores[i].text.isEmpty &&
          widget.banco.llaves != null &&
          i < widget.banco.llaves!.length) {
        widget.controladores[i].text = widget.banco.llaves![i];
      }
    }
  }

  void _determinarNumeroInicialLlaves() {
    if (widget.banco.llaves != null && widget.banco.llaves!.isNotEmpty) {
      setState(() {
        _numeroLlaves = widget.banco.llaves!.length.clamp(MIN_LLAVES, MAX_LLAVES);
      });
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_validarLlaves()) {
      setState(() => _isSaving = true);
      try {
        await widget.onGuardar();
      } catch (_) {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;
    final minHeight = 220.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AbsorbPointer(
          absorbing: _isSaving,
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
                    const Icon(Icons.key, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.banco.nombre.isNotEmpty
                            ? '${widget.banco.nombre} - Llaves'
                            : 'Llaves Bancarias',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                  ],
                ),
              ),

              // Info Requisitos
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: _buildInfoHeader(),
              ),

              // Cuerpo con Scroll
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight.clamp(minHeight, double.infinity),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLlavesFields(),
                          _buildAddRemoveButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Botones de acción
              Container(
                padding: const EdgeInsets.all(20),
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
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Themes.primary,
                        foregroundColor: Colors.white,
                        shadowColor: Themes.primary.withOpacity(0.3),
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildInfoHeader() {
    final String msg = LONGITUD_MAXIMA_LLAVE != null
        ? 'Cada llave debe tener entre $LONGITUD_MINIMA_LLAVE y $LONGITUD_MAXIMA_LLAVE caracteres.'
        : 'Cada llave debe tener al menos $LONGITUD_MINIMA_LLAVE caracteres.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          msg,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (_numeroLlaves == MAX_LLAVES
                ? Colors.green.shade50
                : _numeroLlaves >= 2
                    ? Colors.orange.shade50
                    : Colors.red.shade50),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (_numeroLlaves == MAX_LLAVES
                  ? Colors.green.shade200
                  : _numeroLlaves >= 2
                      ? Colors.orange.shade200
                      : Colors.red.shade200),
            ),
          ),
          child: Text(
            'Llaves habilitadas: $_numeroLlaves de $MAX_LLAVES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _numeroLlaves == MAX_LLAVES
                  ? Colors.green.shade800
                  : _numeroLlaves >= 2
                      ? Colors.orange.shade800
                      : Colors.red.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLlavesFields() {
    return Column(
      children: List.generate(_numeroLlaves, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildLlaveField(index),
        );
      }),
    );
  }

  Widget _buildLlaveField(int index) {
    return TextFormField(
      controller: widget.controladores[index],
      enabled: !_isSaving,
      decoration: InputDecoration(
        labelText: 'Llave ${index + 1}',
        hintText: 'Ingrese llave ${index + 1}',
        errorText: _errores[index].isNotEmpty ? _errores[index] : null,
        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: Themes.primary),
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
        suffixIcon: _numeroLlaves > MIN_LLAVES && !_isSaving
            ? IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onPressed: () => _eliminarLlave(index),
                tooltip: 'Eliminar esta llave',
              )
            : null,
      ),
    );
  }

  Widget _buildAddRemoveButtons() {
    return Column(
      children: [
        if (_numeroLlaves < MAX_LLAVES)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _agregarLlave,
              icon: const Icon(Icons.add, size: 16),
              label: Text('Agregar Llave ${_numeroLlaves + 1}'),
              style: TextButton.styleFrom(
                foregroundColor: Themes.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (_numeroLlaves > MIN_LLAVES)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextButton.icon(
              onPressed: _isSaving ? null : () => _eliminarLlave(_numeroLlaves - 1),
              icon: const Icon(Icons.remove, size: 16, color: Colors.red),
              label: Text('Quitar última llave', style: TextStyle(color: Colors.red.shade700)),
            ),
          ),
      ],
    );
  }

  void _agregarLlave() {
    if (_numeroLlaves < MAX_LLAVES) {
      setState(() {
        _numeroLlaves++;
      });
    }
  }

  void _eliminarLlave(int index) {
    if (_numeroLlaves > MIN_LLAVES) {
      widget.controladores[index].clear();

      for (int i = index; i < _numeroLlaves - 1; i++) {
        widget.controladores[i].text = widget.controladores[i + 1].text;
        widget.controladores[i + 1].clear();
      }

      setState(() {
        _numeroLlaves--;
      });
    }
  }

  bool _validarLlaves() {
    bool isValid = true;
    final newErrors = List.filled(MAX_LLAVES, '');

    for (int i = 0; i < _numeroLlaves; i++) {
      final value = widget.controladores[i].text.trim();
      if (value.isEmpty) {
        newErrors[i] = 'La llave es obligatoria';
        isValid = false;
      } else if (value.length < LONGITUD_MINIMA_LLAVE) {
        newErrors[i] = 'Debe tener al menos $LONGITUD_MINIMA_LLAVE caracteres';
        isValid = false;
      } else if (LONGITUD_MAXIMA_LLAVE != null && value.length > LONGITUD_MAXIMA_LLAVE!) {
        newErrors[i] = 'No puede exceder $LONGITUD_MAXIMA_LLAVE caracteres';
        isValid = false;
      }
    }

    setState(() {
      _errores = newErrors;
    });

    return isValid;
  }
}
