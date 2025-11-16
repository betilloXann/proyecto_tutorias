import 'package:flutter/material.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/text_input_field.dart';

class RegisterView extends StatelessWidget {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6EEF8),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset("assets/logo.png", height: 80),
            Text("Crear Cuenta",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            TextInputField(
              label: "Nombre Completo",
              controller: nameCtrl,
              icon: Icons.person_outline,
            ),

            SizedBox(height: 16),
            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.email_outlined,
            ),

            SizedBox(height: 16),
            TextInputField(
              label: "Contraseña",
              controller: passCtrl,
              icon: Icons.lock_outline,
              obscure: true,
            ),

            SizedBox(height: 20),
            PrimaryButton(
              text: "Registrarme",
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
