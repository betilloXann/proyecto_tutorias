import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../core/widgets/responsive_container.dart';

class ForgotPasswordView extends StatelessWidget {
  final emailCtrl = TextEditingController();

  ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

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
              BoxShadow(color: Color(0xFFDDE6F3), offset: Offset(4, 4), blurRadius: 10),
              BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      // 2. Envolvemos el cuerpo con ResponsiveContainer
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/image4.svg',
                width: 200,
                height: 210,
                //width: 200,
//                       height: 180,
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

              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 30),

              viewModel.isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                text: "Enviar correo",
                onPressed: () async {
                  if (emailCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Por favor ingresa un correo")),
                    );
                    return;
                  }

                  final success = await viewModel.sendRecoveryEmail(emailCtrl.text);

                  if (success && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("¡Correo enviado!"),
                        content: const Text("Revisa tu bandeja de entrada (y spam) para restablecer tu contraseña."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
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
                onPressed: () {},
                child: const Text(
                  "¿No recibiste el correo?",
                  style: TextStyle(color: Color(0xFF0D47A1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}