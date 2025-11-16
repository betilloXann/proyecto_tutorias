import 'package:flutter/material.dart';
import 'package:proyecto_tutorias/widgets/primary_button.dart';
import 'package:proyecto_tutorias/widgets/text_input_field.dart';

class LoginView extends StatelessWidget {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6EEF8),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logo.png", height: 80),
            SizedBox(height: 20),
            Text("Iniciar Sesión",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.email_outlined,
            ),
            SizedBox(height: 16),
            TextInputField(
              label: "Contraseña",
              controller: passwordCtrl,
              icon: Icons.lock_outline,
              obscure: true,
            ),
            SizedBox(height: 20),
            PrimaryButton(
              text: "Ingresar",
              onPressed: () {},
            ),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, "/register"),
                child: Text("¿No tienes cuenta? Regístrate")),
          ],
        ),
      ),
    );
  }
}
