import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

class RegisterView extends StatelessWidget {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,

      appBar: AppBar(
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            SvgPicture.asset("assets/images/logo.svg", height: 120),

            const SizedBox(height: 24),

            Text(
              "Crear Cuenta",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            TextInputField(
              label: "Nombre Completo",
              controller: nameCtrl,
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 16),

            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 16),

            TextInputField(
              label: "Contraseña",
              controller: passCtrl,
              icon: Icons.lock_outline,
              obscure: true,
            ),

            const SizedBox(height: 32),

            PrimaryButton(
              text: "Registrarme",
              onPressed: () => Navigator.pushNamed(context, "/verify"),
            ),
          ],
        ),
      ),
    );
  }
}
