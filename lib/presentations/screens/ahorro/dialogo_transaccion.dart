// 🎨 presentations/screens/ahorro/dialogo_transaccion.dart
// ============================================================================
// DIÁLOGO: Depósito / Retiro de Ahorros con prevención de doble submit y loading
// ============================================================================

import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/core/data/utils/thousands_formatter.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/data/providers/ahorro_provider.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DialogoTransaccion extends ConsumerStatefulWidget {
  final String metaId;
  final String tipo; // 'deposito' o 'retiro'
  final double? maxMonto;

  const DialogoTransaccion({
    super.key,
    required this.metaId,
    required this.tipo,
    this.maxMonto,
  });

  @override
  ConsumerState<DialogoTransaccion> createState() => _DialogoTransaccionState();
}

class _DialogoTransaccionState extends ConsumerState<DialogoTransaccion> {
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AhorroValidator _validator = AhorroValidator();

  final FocusNode _montoFocusNode = FocusNode();
  final FocusNode _descripcionFocusNode = FocusNode();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _montoFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _montoFocusNode.dispose();
    _descripcionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _guardarTransaccion() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    final montoLimpio = _montoController.text.replaceAll('.', '');
    final monto = double.tryParse(montoLimpio);

    if (monto == null || monto <= 0) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'El monto debe ser válido y mayor que cero.',
      );
      return;
    }

    if (widget.tipo == 'retiro' && widget.maxMonto != null && monto > widget.maxMonto!) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'No puedes retirar más de ${UIHelpers.formatCurrency(widget.maxMonto!)}.',
      );
      return;
    }

    if (widget.tipo == 'deposito' && widget.maxMonto != null && monto > widget.maxMonto!) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'No puedes depositar más de lo restante: ${UIHelpers.formatCurrency(widget.maxMonto!)}.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(ahorroControllerProvider.notifier).agregarTransaccion(
            metaId: widget.metaId,
            tipo: widget.tipo,
            monto: monto,
            descripcion: _descripcionController.text.trim().isNotEmpty
                ? _descripcionController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: widget.tipo == 'deposito'
              ? '¡Depósito realizado exitosamente!'
              : '¡Retiro realizado exitosamente!',
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        UIHelpers.showErrorSnackBar(
          context: context,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esRetiro = widget.tipo == 'retiro';
    final String tituloText = esRetiro ? 'Realizar Retiro' : 'Realizar Depósito';
    final Color colorTematico = esRetiro ? Themes.red : Colors.green;

    return Dialog(
      elevation: 10,
      backgroundColor: context.dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado Premium
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: colorTematico,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      esRetiro ? Icons.remove_circle : Icons.add_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tituloText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                      ),
                    ),
                    if (_isSaving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                  ],
                ),
              ),

              // Cuerpo
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Mostrar información del límite
                      if (widget.maxMonto != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? context.colors.surfaceContainerLow
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: context.isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                esRetiro ? 'Monto disponible:' : 'Monto restante:',
                                style: TextStyle(
                                  color: context.isDarkMode
                                      ? context.colors.onSurfaceVariant
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                UIHelpers.formatCurrency(widget.maxMonto!),
                                style: TextStyle(
                                  color: context.isDarkMode
                                      ? context.colors.primary
                                      : Themes.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Input Monto
                      TextFormField(
                        controller: _montoController,
                        focusNode: _montoFocusNode,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsFormatter()],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Monto a transferir',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.attach_money, color: Themes.primary),
                          filled: true,
                          fillColor: context.isDarkMode
                              ? context.colors.surfaceContainerLow
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: context.isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: context.isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Themes.primary, width: 2),
                          ),
                        ),
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_descripcionFocusNode);
                        },
                        validator: (value) =>
                            _validator.validateMonto(value, widget.maxMonto),
                      ),
                      const SizedBox(height: 16),

                      // Input Descripción
                      TextFormField(
                        controller: _descripcionController,
                        focusNode: _descripcionFocusNode,
                        enabled: !_isSaving,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Descripción / Nota (Opcional)',
                          hintText: 'Ej. Ahorro de la semana',
                          prefixIcon: const Icon(Icons.description_outlined, color: Themes.primary),
                          filled: true,
                          fillColor: context.isDarkMode
                              ? context.colors.surfaceContainerLow
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: context.isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: context.isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Themes.primary, width: 2),
                          ),
                        ),
                        onFieldSubmitted: (_) => _descripcionFocusNode.unfocus(),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? context.colors.surfaceContainer
                      : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                        color: context.isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: context.isDarkMode
                              ? context.colors.onSurfaceVariant
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _guardarTransaccion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorTematico,
                        foregroundColor: Colors.white,
                        shadowColor: colorTematico.withOpacity(0.4),
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              esRetiro ? 'Retirar' : 'Depositar',
                              style: const TextStyle(
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
      ),
    );
  }
}
