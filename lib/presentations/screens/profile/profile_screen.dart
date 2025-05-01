import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/routes/app_routes.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen>
 {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
     appBar: AppBarFinances(
    title: 'Editar Perfil',
    showBackButton: true, // Muestra el botón de regreso
    showProfileAction: false, // Oculta el botón de perfil
  ),
                          //backgroundColor: Colors.white,

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildProfileInfo(authState.user),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Por favor, ingresa un nombre'
                    : null,
                onSaved: (value) => _nameController.text = value ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() => _isSaving = true);
                          try {
                            await ref
                                .read(authProvider.notifier)
                                .updateDisplayName(_nameController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Perfil actualizado exitosamente'),
                              ),
                            );
                            Navigator.pop(context);
                          } finally {
                            setState(() => _isSaving = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3A57E8),
            Color(0xFF0C1F6F),
            Color(0xFF050A30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            

            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFF1B263B),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido, ${user?.displayName ?? 'Sin nombre'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                      

                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Sin email asociado',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9BAEC8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcome,
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
