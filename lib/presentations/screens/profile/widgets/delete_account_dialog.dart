import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:finances/core/data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DeleteAccountDialog extends StatefulWidget {
  final AuthProviderType authProvider;
  final Future<void> Function(String? password) onDelete;

  const DeleteAccountDialog({
    super.key,
    required this.authProvider,
    required this.onDelete,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _passwordError;
  int _step = 1;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'La contraseña es requerida');
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Contraseña muy corta');
    } else {
      setState(() => _passwordError = null);
    }
  }

  Future<void> _onConfirmDelete() async {
    if (widget.authProvider == AuthProviderType.email) {
      _validatePassword();
      if (_passwordError != null) return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onDelete(
        widget.authProvider == AuthProviderType.email
            ? _passwordController.text
            : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        final errorMessage = e is FirebaseAuthException
            ? AuthErrorHandler.handle(e)
            : e is String
                ? e
                : ErrorStrings.unexpectedError;

        if (widget.authProvider == AuthProviderType.email) {
          setState(() => _passwordError = errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              _step == 1 ? _buildConfirmationStep() : _buildVerificationStep(),
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¿Eliminar cuenta?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Esta acción borrará todos tus datos financieros y no se puede deshacer.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() => _step = 2),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.authProvider == AuthProviderType.email
              ? 'Confirma tu identidad'
              : 'Confirmar la eliminación',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (widget.authProvider == AuthProviderType.email)
          _buildPasswordField()
        else
          _buildOAuthNotice(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isLoading ? null : () => setState(() => _step = 1),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isLoading ? null : _onConfirmDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Eliminar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      children: [
        Text(
          'Ingresa tu contraseña actual para continuar.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          enabled: !_isLoading,
          onChanged: (_) {
            if (_passwordError != null) _validatePassword();
          },
          decoration: InputDecoration(
            labelText: 'Contraseña',
            errorText: _passwordError,
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildOAuthNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu sesión ya está verificada. Presiona Eliminar para confirmar.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
