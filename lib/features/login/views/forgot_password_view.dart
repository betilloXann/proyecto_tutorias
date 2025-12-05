import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart'; // IMPORTANTE: Agregar Provider

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../viewmodels/forgot_password_viewmodel.dart'; // Importar el VM

class ForgotPasswordView extends StatelessWidget {
  final emailCtrl = TextEditingController();

  ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el ViewModel
    final viewModel = context.watch<ForgotPasswordViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8),
      appBar: AppBar(
        // ... (Tu código existente del AppBar se mantiene igual) ...
        backgroundColor: const Color(0xFFE6EEF8),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xFFDDE6F3),
                  offset: Offset(4, 4),
                  blurRadius: 10),
              BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 10),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              "Recuperar contraseña",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            TextInputField(
              label: "Correo electrónico",
              controller: emailCtrl,
              icon: Icons.email_outlined,
            ),

            // Mostrar error si existe
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 30),

            // Botón con estado de carga
            viewModel.isLoading
                ? const CircularProgressIndicator()
                : PrimaryButton(
                    text: "Enviar correo",
                    onPressed: () async {
                      if (emailCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Por favor ingresa un correo")),
                        );
                        return;
                      }

                      final success =
                          await viewModel.sendRecoveryEmail(emailCtrl.text);

                      if (success && context.mounted) {
                        // Mostrar éxito y regresar al Login
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("¡Correo enviado!"),
                            content: const Text(
                                "Revisa tu bandeja de entrada (y spam) para restablecer tu contraseña."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Cerrar diálogo
                                  Navigator.pop(context); // Volver al Login
                                },
                                child: const Text("Aceptar"),
                              )
                            ],
                          ),
                        );
                      }
                    },
                  ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                 // Opcional: Reenviar o ayuda
              },
              child: const Text(
                "¿No recibiste el correo?",
                style: TextStyle(color: Color(0xFF0D47A1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}