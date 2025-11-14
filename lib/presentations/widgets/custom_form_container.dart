import 'package:flutter/material.dart';
import 'package:finances/presentations/theme/themes.dart';

class CustomFormContainer extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String? saveButtonText;
  final String? cancelButtonText;
  final GlobalKey<FormState> formKey;

  const CustomFormContainer({
    super.key,
    required this.children,
    required this.formKey,
    this.onCancel,
    this.onSave,
    this.saveButtonText = "Guardar",
    this.cancelButtonText = "Cancelar",
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Themes.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...children,
              const SizedBox(height: 20),
              _buildButtonsRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(cancelButtonText!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Themes.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              saveButtonText!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
