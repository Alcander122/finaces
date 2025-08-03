import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/presentations/screens/home/home_screen.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:finances/core/data/services/user_service.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  final User? user;
  final bool isNewUser;

  // Constructor por defecto para usuarios nuevos (por Google, por ejemplo)
  const TermsAcceptanceScreen({super.key})
      : user = null,
        isNewUser = true;

  // Constructor específico para usuarios existentes que aún no aceptaron términos
  const TermsAcceptanceScreen.forExistingUser(this.user, {super.key})
      : isNewUser = false;

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _agreePersonalData = false;
  bool _isLoading = false;

  /// Acepta los términos, crea o actualiza el documento del usuario según sea necesario
  void _acceptTerms() async {
    if (_isLoading) return;

    if (!_agreePersonalData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorStrings.termsNotAccepted),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = widget.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      final userService = UserService();

      if (widget.isNewUser) {
        // Crear el documento desde cero usando tu método de UserService
        await userService.registerGoogleUser(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
        );
      }

      // Asegurar que el documento esté creado (por si es usuario antiguo sin campos)
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userRef.set({
        'acceptedTerms': true,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Navegar a la pantalla principal
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al guardar aceptación de términos"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ErrorStrings.termsAndConditionsTitle,
            style: TextStyle(color: Themes.degradientLight)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Themes.degradientLight),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ErrorStrings.termsAndConditionsTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Themes.degradientLight,
                              ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      ErrorStrings.termsAndConditionsContent,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ErrorStrings.privacyPolicyTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Themes.degradientLight,
                              ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      ErrorStrings.privacyPolicyContent,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    // Checkbox de aceptación
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreePersonalData,
                          onChanged: (value) => setState(
                              () => _agreePersonalData = value ?? false),
                          activeColor: Themes.degradientLight,
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Acepto el procesamiento de ',
                                  style: TextStyle(color: Colors.black45),
                                ),
                                TextSpan(
                                  text: 'Datos personales.',
                                  style: TextStyle(
                                    color: Themes.degradientLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _acceptTerms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Themes.degradientLight,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Aceptar y Continuar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
