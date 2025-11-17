import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// Widgets
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

// ViewModel
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatelessWidget {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<LoginViewModel>();

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

            /// LOGO SVG
            SvgPicture.asset(
              "assets/images/logo.svg",
              height: 120,
            ),

            const SizedBox(height: 24),

            /// TÍTULO
            Text(
              "Iniciar Sesión",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            /// EMAIL
            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 16),

            /// PASSWORD
            TextInputField(
              label: "Contraseña",
              controller: passwordCtrl,
              icon: Icons.lock_outline,
              obscure: true,
            ),

            /// OLVIDÉ MI CONTRASEÑA
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, "/recover"),
                child: Text(
                  "¿Olvidaste tu contraseña?",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// BOTÓN PRINCIPAL
            SizedBox(
              width: double.infinity,
              height: 56,
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                text: "Ingresar",
                onPressed: () async {
                  final error = await vm.login(
                    emailCtrl.text,
                    passwordCtrl.text,
                  );

                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            /// TEXTO SECUNDARIO
            TextButton(
              onPressed: () => Navigator.pushNamed(context, "/register"),
              child: Text(
                "¿No tienes cuenta? Regístrate",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
