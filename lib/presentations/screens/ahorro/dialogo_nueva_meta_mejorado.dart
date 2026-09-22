// 🎨 presentations/screens/ahorro/dialogo_nueva_meta_mejorado.dart
// ============================================================================
// DIÁLOGO: Crear nueva meta con vista previa del plan y prevención de doble submit
// ============================================================================

import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/utils/ahorro_calculator.dart';
import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/core/data/utils/thousands_formatter.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/data/providers/ahorro_provider.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DialogoNuevaMetaMejorado extends ConsumerStatefulWidget {
  final ObjetivoAhorro? metaExistente;

  const DialogoNuevaMetaMejorado({this.metaExistente, super.key});

  @override
  ConsumerState<DialogoNuevaMetaMejorado> createState() =>
      _DialogoNuevaMetaMejoradoState();
}

class _DialogoNuevaMetaMejoradoState extends ConsumerState<DialogoNuevaMetaMejorado> {
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _validator = AhorroValidator();

  DateTime? _fechaObjetivo;
  AhorroDesglose? _desglose;
  bool _isSaving = false;

  final _nombreFocusNode = FocusNode();
  final _montoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.metaExistente != null) {
      _nombreController.text = widget.metaExistente!.nombre;
      _montoController.text = NumberFormat.decimalPattern('es_CO')
          .format(widget.metaExistente!.montoObjetivo.toInt());
      _fechaObjetivo = widget.metaExistente!.fechaObjetivo;
      _desglose = AhorroCalculator.calcularDesglose(
        montoObjetivo: widget.metaExistente!.montoObjetivo,
        fechaObjetivo: widget.metaExistente!.fechaObjetivo,
        montoActual: widget.metaExistente!.montoActual,
      );
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nombreFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _nombreFocusNode.dispose();
    _montoFocusNode.dispose();
    super.dispose();
  }

  void _actualizarDesglose() {
    final montoLimpio = _montoController.text.replaceAll('.', '');
    final monto = double.tryParse(montoLimpio);
    if (monto != null && monto > 0 && _fechaObjetivo != null) {
      setState(() {
        _desglose = AhorroCalculator.calcularDesglose(
          montoObjetivo: monto,
          fechaObjetivo: _fechaObjetivo!,
          montoActual: widget.metaExistente?.montoActual ?? 0.0,
        );
      });
    } else {
      setState(() => _desglose = null);
    }
  }

  Future<void> _seleccionarFecha() async {
    if (_isSaving) return;

    final ahora = DateTime.now();
    final fechaBase = (_fechaObjetivo != null && _fechaObjetivo!.isAfter(ahora))
        ? _fechaObjetivo!
        : ahora.add(const Duration(days: 30));
    
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaBase,
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 3650)),
      builder: (dialogCtx, child) {
        return Theme(
          data: Theme.of(dialogCtx).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.isDarkMode ? context.colors.primary : Themes.primary,
              onPrimary: Colors.white,
              onSurface: context.colors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (fecha != null) {
      setState(() => _fechaObjetivo = fecha);
      _actualizarDesglose();
    }
  }

  Future<void> _guardarMeta() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate() || _fechaObjetivo == null) {
      if (_fechaObjetivo == null) {
        UIHelpers.showErrorSnackBar(
          context: context,
          message: 'Por favor, selecciona una fecha objetivo.',
        );
      }
      return;
    }

    final monto = double.tryParse(_montoController.text.replaceAll('.', ''));
    if (monto == null || monto <= 0) return;

    final esEdicion = widget.metaExistente != null;

    // Validación UX: no permitir meta menor a lo ya ahorrado
    if (esEdicion && monto < widget.metaExistente!.montoActual) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message:
            'El monto objetivo no puede ser menor a lo ya ahorrado (${UIHelpers.formatCurrency(widget.metaExistente!.montoActual)}).',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (esEdicion) {
        await ref.read(ahorroControllerProvider.notifier).actualizarMeta(
              metaId: widget.metaExistente!.id!,
              nombre: _nombreController.text.trim(),
              montoObjetivo: monto,
              fechaObjetivo: _fechaObjetivo!,
            );
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          UIHelpers.showSuccessSnackBar(
            context: context,
            message: 'Meta "${_nombreController.text.trim()}" actualizada exitosamente.',
          );
        }
      } else {
        await ref.read(ahorroControllerProvider.notifier).crearMeta(
              nombre: _nombreController.text.trim(),
              montoObjetivo: monto,
              fechaObjetivo: _fechaObjetivo!,
            );
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          UIHelpers.showSuccessSnackBar(
            context: context,
            message: 'Meta "${_nombreController.text.trim()}" creada exitosamente.',
          );
        }
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
    final esEdicion = widget.metaExistente != null;
    final primaryColor = context.isDarkMode ? context.colors.primary : Themes.primary;

    return Dialog(
      elevation: 10,
      backgroundColor: context.dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 420),
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
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      esEdicion ? Icons.edit_note_rounded : Icons.savings,
                      color: context.isDarkMode ? const Color(0xFF003366) : Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        esEdicion ? 'Editar Meta de Ahorro' : 'Nueva Meta de Ahorro',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: context.isDarkMode ? const Color(0xFF003366) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                      ),
                    ),
                    if (_isSaving)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.isDarkMode ? const Color(0xFF003366) : Colors.white,
                        ),
                      )
                  ],
                ),
              ),

              // Cuerpo
              Flexible(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.opaque,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nombre
                        TextFormField(
                          controller: _nombreController,
                          focusNode: _nombreFocusNode,
                          enabled: !_isSaving,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Nombre de la Meta',
                            hintText: 'Ej. Fondo de Emergencias',
                            prefixIcon: Icon(Icons.flag_outlined, color: primaryColor),
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
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          onChanged: (_) => _actualizarDesglose(),
                          validator: _validator.validateNombre,
                        ),
                        const SizedBox(height: 16),

                        // Monto
                        TextFormField(
                          controller: _montoController,
                          focusNode: _montoFocusNode,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsFormatter()],
                          decoration: InputDecoration(
                            labelText: 'Monto Objetivo',
                            hintText: '0',
                            prefixIcon: Icon(Icons.attach_money, color: primaryColor),
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
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          onChanged: (_) => _actualizarDesglose(),
                          validator: (v) => _validator.validateMonto(v, null),
                        ),
                        const SizedBox(height: 16),

                        // Fecha Selector
                        InkWell(
                          onTap: _isSaving ? null : _seleccionarFecha,
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? context.colors.surfaceContainerLow
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: context.isDarkMode
                                      ? Colors.white12
                                      : Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha Objetivo',
                                      style: TextStyle(
                                        color: context.isDarkMode
                                            ? context.colors.onSurfaceVariant
                                            : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fechaObjetivo != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_fechaObjetivo!)
                                          : 'Seleccionar fecha objetivo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _fechaObjetivo != null
                                            ? primaryColor
                                            : (context.isDarkMode
                                                ? Colors.white38
                                                : Colors.grey.shade500),
                                        fontWeight: _fechaObjetivo != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.calendar_month, color: primaryColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Vista previa del plan
                        AnimatedCrossFade(
                          firstChild: _desglose != null
                              ? _desgloseCompacto(_desglose!)
                              : const SizedBox.shrink(),
                          secondChild: _montoController.text.isNotEmpty &&
                                  _fechaObjetivo != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Ingresa un monto válido para ver el plan',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: context.isDarkMode
                                            ? context.colors.onSurfaceVariant
                                            : Colors.grey,
                                        fontSize: 12),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          crossFadeState: _desglose != null && _desglose!.esValido
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ),

              // Botones de Acción
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
                      onPressed: _isSaving ? null : _guardarMeta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: context.isDarkMode ? const Color(0xFF003366) : Colors.white,
                        shadowColor: primaryColor.withValues(alpha: 0.4),
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.isDarkMode ? const Color(0xFF003366) : Colors.white,
                              ),
                            )
                          : Text(
                              esEdicion ? 'Guardar Cambios' : 'Crear Meta',
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

  Widget _desgloseCompacto(AhorroDesglose d) {
    final primaryColor = context.isDarkMode ? context.colors.primary : Themes.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.colors.surfaceContainerHigh
            : Themes.infoBlue.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white12
              : Themes.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plan de Ahorro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  d.mensajeTiempoRestante,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fila('Diario', d.ahorrosDiarios, Icons.calendar_today),
          const SizedBox(height: 6),
          _fila('Semanal', d.ahorrosSemanal, Icons.date_range),
          const SizedBox(height: 6),
          _fila('Quincenal', d.ahorrosQuincenal, Icons.event_note),
          const SizedBox(height: 6),
          _fila('Mensual', d.ahorrosMensual, Icons.calendar_month),
          const SizedBox(height: 12),
          
          // Insight de recomendación premium
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: context.isDarkMode
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.green.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.stars,
                    color: context.isDarkMode ? Colors.greenAccent : Colors.green.shade700,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recomendado: ${_periodoTexto(d.periodoRecomendado)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.isDarkMode ? Colors.greenAccent : Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String periodo, double monto, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.colors.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Themes.primary.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                periodo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode ? context.colors.onSurface : Colors.black87,
                ),
              )
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              UIHelpers.formatCurrency(monto),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode ? Colors.greenAccent : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodoTexto(String p) => switch (p) {
        'diario' => 'Ahorrar diariamente',
        'semanal' => 'Ahorrar semanalmente',
        'quincenal' => 'Ahorrar quincenalmente',
        'mensual' => 'Ahorrar mensualmente',
        _ => 'Período personalizado',
      };
}
