import 'package:flutter/material.dart';
import 'package:finances/core/data/models/bank_model.dart';

/// Diálogo para ingresar llaves bancarias con soporte flexible (1-3 llaves)
///
/// CARACTERÍSTICAS PRINCIPALES:
/// 1. Diseño completamente adaptativo que evita desbordamientos en cualquier dispositivo
/// 2. Soporte flexible para 1, 2 o 3 llaves según necesidad del usuario
/// 3. Interfaz intuitiva con botones para agregar/eliminar llaves
/// 4. Validación mejorada con mensajes específicos para cada llave
///
/// SOLUCIONA LOS PROBLEMAS REPORTADOS:
/// - "Desbordamiento cuando selecciona el filtro de la llave 2 y 3"
/// - "El usuario quiere poder agregar una sola llave o las 3 llaves"
class DialogoLlaves extends StatefulWidget {
  final BancoModelo banco;
  final List<TextEditingController> controladores;
  final VoidCallback onGuardar;
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
  int _numeroLlaves = 1; // Por defecto, empezamos con 1 llave
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

  /// Inicializa los controladores con valores existentes si están disponibles
  void _inicializarControladores() {
    for (int i = 0; i < 3; i++) {
      if (widget.controladores[i].text.isEmpty &&
          widget.banco.llaves != null &&
          i < widget.banco.llaves!.length) {
        widget.controladores[i].text = widget.banco.llaves![i];
      }
    }
  }

  /// Determina cuántas llaves mostrar inicialmente basado en los datos existentes
  void _determinarNumeroInicialLlaves() {
    if (widget.banco.llaves != null && widget.banco.llaves!.isNotEmpty) {
      // Si hay datos existentes, mostramos el número de llaves que ya tiene
      setState(() {
        _numeroLlaves =
            widget.banco.llaves!.length.clamp(MIN_LLAVES, MAX_LLAVES);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular la altura máxima basada en el tamaño de pantalla
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final minHeight = 200.0; // Altura mínima para mantener legibilidad

    return AlertDialog(
      title: Text(widget.banco.nombre.isNotEmpty
          ? '${widget.banco.nombre} - Llaves'
          : 'Llaves'),
      // Solución 1: Usar SizedBox con altura proporcional para evitar desbordamiento
      content: SizedBox(
        width: double.maxFinite,
        height: maxHeight.clamp(minHeight, double.infinity),
        child: _buildDialogContent(),
      ),
      actions: _buildActions(),
      // Solución 2: Ajustar padding según tamaño de pantalla
      insetPadding: _calculateInsetPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
    );
  }

  /// Construye el contenido principal del diálogo con soporte flexible de llaves
  Widget _buildDialogContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoHeader(),
          const SizedBox(height: 10),
          // Solución 3: Usar Expanded + SingleChildScrollView para contenido desbordado
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLlavesFields(),
                  _buildAddRemoveButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Encabezado con información y estado de las llaves
  Widget _buildInfoHeader() {
    String mensajeRequisitos;
    if (LONGITUD_MAXIMA_LLAVE != null) {
      mensajeRequisitos =
          'Cada llave debe tener entre $LONGITUD_MINIMA_LLAVE y $LONGITUD_MAXIMA_LLAVE caracteres.';
    } else {
      mensajeRequisitos =
          'Cada llave debe tener al menos $LONGITUD_MINIMA_LLAVE caracteres.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mensajeRequisitos,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Llaves actuales: $_numeroLlaves de $MAX_LLAVES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _numeroLlaves == MAX_LLAVES
                ? Colors.green
                : _numeroLlaves >= 2
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  /// Construye los campos de texto para las llaves según el número seleccionado
  Widget _buildLlavesFields() {
    return Column(
      children: List.generate(_numeroLlaves, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: _buildLlaveField(index),
        );
      }),
    );
  }

  /// Campo de texto para una llave específica
  Widget _buildLlaveField(int index) {
    return TextFormField(
      controller: widget.controladores[index],
      decoration: InputDecoration(
        labelText: 'Llave ${index + 1}',
        hintText: 'Ingrese llave ${index + 1}',
        errorText: _errores[index].isNotEmpty ? _errores[index] : null,
        suffixIcon: _numeroLlaves > MIN_LLAVES
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _eliminarLlave(index),
                tooltip: 'Eliminar esta llave',
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'La llave es obligatoria';
        }
        if (value.length < LONGITUD_MINIMA_LLAVE) {
          return 'La llave debe tener al menos $LONGITUD_MINIMA_LLAVE caracteres';
        }
        if (LONGITUD_MAXIMA_LLAVE != null &&
            value.length > LONGITUD_MAXIMA_LLAVE!) {
          return 'La llave no puede exceder $LONGITUD_MAXIMA_LLAVE caracteres';
        }
        return null;
      },
    );
  }

  /// Botones para agregar/eliminar llaves
  Widget _buildAddRemoveButtons() {
    return Column(
      children: [
        const SizedBox(height: 10),
        if (_numeroLlaves < MAX_LLAVES)
          ElevatedButton.icon(
            onPressed: _agregarLlave,
            icon: const Icon(Icons.add, size: 16),
            label: Text('Agregar llave ${_numeroLlaves + 1}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
          ),
        const SizedBox(height: 5),
        if (_numeroLlaves > MIN_LLAVES)
          TextButton.icon(
            onPressed: () => _eliminarLlave(_numeroLlaves - 1),
            icon: const Icon(Icons.remove, size: 16),
            label: Text('Eliminar llave ${_numeroLlaves}'),
          ),
      ],
    );
  }

  /// Acciones del diálogo (cancelar y guardar)
  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () {
          if (_validarLlaves()) {
            widget.onGuardar();
          }
        },
        child: const Text('Guardar'),
      ),
    ];
  }

  /// Calcula el padding adecuado según el tamaño de pantalla
  EdgeInsets _calculateInsetPadding() {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.size.width > 600) {
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0);
    } else if (mediaQuery.size.height < 600) {
      // Pantallas pequeñas: menos padding vertical
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
    } else {
      return const EdgeInsets.all(12.0);
    }
  }

  /// Agrega una nueva llave si no se ha alcanzado el máximo
  void _agregarLlave() {
    if (_numeroLlaves < MAX_LLAVES) {
      setState(() {
        _numeroLlaves++;
      });
    }
  }

  /// Elimina una llave específica
  void _eliminarLlave(int index) {
    if (_numeroLlaves > MIN_LLAVES) {
      // Limpiar el controlador
      widget.controladores[index].clear();

      // Mover los valores de las llaves superiores
      for (int i = index; i < _numeroLlaves - 1; i++) {
        widget.controladores[i].text = widget.controladores[i + 1].text;
        widget.controladores[i + 1].clear();
      }

      setState(() {
        _numeroLlaves--;
      });
    }
  }

  /// Valida todas las llaves antes de guardar
  bool _validarLlaves() {
    bool isValid = true;
    final newErrors = List.filled(MAX_LLAVES, '');

    for (int i = 0; i < _numeroLlaves; i++) {
      final value = widget.controladores[i].text;
      if (value.isEmpty) {
        newErrors[i] = 'La llave es obligatoria';
        isValid = false;
      } else if (value.length < LONGITUD_MINIMA_LLAVE) {
        newErrors[i] =
            'La llave debe tener al menos $LONGITUD_MINIMA_LLAVE caracteres';
        isValid = false;
      } else if (LONGITUD_MAXIMA_LLAVE != null &&
          value.length > LONGITUD_MAXIMA_LLAVE!) {
        newErrors[i] =
            'La llave no puede exceder $LONGITUD_MAXIMA_LLAVE caracteres';
        isValid = false;
      }
    }

    setState(() {
      _errores = newErrors;
    });

    return isValid;
  }
}
