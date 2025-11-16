import 'package:flutter/material.dart';
import '../../../widgets/primary_button.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6EEF8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logo.png", height: 120),
            SizedBox(height: 20),
            Text(
              "Bienvenido",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text("Inicia sesión o crea una cuenta para continuar."),
            SizedBox(height: 40),
            PrimaryButton(
              text: "Continuar",
              onPressed: () => Navigator.pushNamed(context, "/login"),
            ),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, "/login"),
                child: Text("¿Ya tienes cuenta? Inicia sesión"))
          ],
        ),
      ),
    );
  }
}
