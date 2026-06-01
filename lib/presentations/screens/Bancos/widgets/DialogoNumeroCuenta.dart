// 🎨 presentations/screens/Bancos/widgets/DialogoNumeroCuenta.dart
// ============================================================================
// DIÁLOGO: Formulario para vincular número de cuenta con prevención de doble submit
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finances/core/data/models/bank_model.dart';
import 'package:finances/presentations/theme/themes.dart';

class DialogoNumeroCuenta extends StatefulWidget {
  final BancoModelo banco;
  final TextEditingController controladorCuenta;
  final Future<void> Function() onGuardar; // Callback asíncrono para prevenir dobles clics

  const DialogoNumeroCuenta({
    super.key,
    required this.banco,
    required this.controladorCuenta,
    required this.onGuardar,
  });

  @override
  State<DialogoNumeroCuenta> createState() => _DialogoNumeroCuentaState();
}

class _DialogoNumeroCuentaState extends State<DialogoNumeroCuenta> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      try {
        await widget.onGuardar();
      } catch (_) {
        // En caso de error, volvemos a habilitar la UI para permitir reintentos
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
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
                decoration: const BoxDecoration(
                  color: Themes.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.banco.nombre,
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

              // Cuerpo del Formulario
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: widget.controladorCuenta,
                    keyboardType: TextInputType.number,
                    enabled: !_isSaving,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Solo números
                    ],
                    decoration: InputDecoration(
                      labelText: 'Número de cuenta',
                      hintText: 'Ej. 1234567890',
                      prefixIcon: const Icon(Icons.tag, color: Themes.primary),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El número de cuenta es obligatorio';
                      }
                      if (value.trim().length < 5) {
                        return 'Debe tener al menos 5 dígitos';
                      }
                      return null;
                    },
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
}
