import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:finances/routes/app_routes.dart'; // Importa las rutas

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  final AuthStorage _authService = AuthStorage(); // Instancia de AuthService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Redirigir a la pantalla principal (Home)
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onSaved: (value) {
                  _name = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    // Aquí puedes guardar la información del perfil
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Eliminar el token antes de redirigir
                  await _authService.deleteToken();

                  // Redirigir a la pantalla de inicio de sesión
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.loginScreen, // Usa la nueva ruta directa
                    (Route<dynamic> route) =>
                        false, // Elimina todas las rutas anteriores
                  );
                },
                child: const Text('Salir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red, // Cambia el color del botón a rojo
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
