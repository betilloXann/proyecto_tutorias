import 'package:flutter/material.dart';

// --- Imports (Tus widgets de UI) ---
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

// <-- 1. Imports añadidos
import 'package:provider/provider.dart';
import '../../../features/login/viewmodels/login_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          TextInputField(
            label: "Correo Institucional",
            controller: emailCtrl,
            icon: Icons.email_outlined,
          ),
          TextInputField(
            label: "Contraseña",
            controller: passwordCtrl,
            icon: Icons.lock_outline,
            obscure: true,
          ),

          SizedBox(
            height: 56,
            width: double.infinity,
            child: vm.isLoading
                ? Center(child: CircularProgressIndicator())
                : PrimaryButton(
              text: "Ingresar",
              onPressed: () async {
                final error = await vm.login(
                  emailCtrl.text,
                  passwordCtrl.text,
                );

                if (error != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
