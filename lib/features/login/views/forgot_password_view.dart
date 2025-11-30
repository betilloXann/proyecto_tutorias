import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

class ForgotPasswordView extends StatelessWidget {
  final emailCtrl = TextEditingController();

  ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8),

      appBar: AppBar(
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
                blurRadius: 10,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 10,
              ),
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
              "Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            /// 🔵 Ya usa tu TextInputField
            TextInputField(
              label: "Correo electrónico",
              controller: emailCtrl,
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              text: "Enviar código",
              onPressed: () => Navigator.pushNamed(context, "/new_password"),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {},
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
