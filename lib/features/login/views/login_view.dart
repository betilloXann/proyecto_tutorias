import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// Widgets
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

// ViewModel
import '../viewmodels/login_viewmodel.dart';

// CAMBIO 1: Convertimos a StatefulWidget para manejar la memoria de los controllers
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controladores
  late final TextEditingController emailCtrl;
  late final TextEditingController passwordCtrl;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    // IMPORTANTE: Liberar memoria al salir
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Usamos watch para reconstruir si cambia isLoading o errorMessage
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      // AppBar personalizada (Botón atrás con sombra)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
              "assets/images/logo.svg", // Asegúrate que este archivo exista
              height: 120,
            ),

            const SizedBox(height: 24),

            /// TÍTULO
            Text(
              "Iniciar Sesión",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F5A93), // Color institucional sugerido
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            /// EMAIL
            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress, // Teclado @
            ),

            const SizedBox(height: 16),

            /// PASSWORD
            TextInputField(
              label: "Contraseña",
              controller: passwordCtrl,
              icon: Icons.lock_outline,
              obscureText: true, // Corregido: suele llamarse obscureText en widgets custom
            ),

            /// OLVIDÉ MI CONTRASEÑA
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implementar ruta de recuperación
                  // Navigator.pushNamed(context, "/recover");
                },
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

            /// BOTÓN PRINCIPAL CON LÓGICA CORREGIDA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                text: "Ingresar",
                onPressed: () async {
                  // Ocultar teclado al presionar
                  FocusScope.of(context).unfocus();

                  // CAMBIO 2: Lógica correcta con el ViewModel
                  final success = await vm.login(
                    emailCtrl.text.trim(), // trim() quita espacios accidentales
                    passwordCtrl.text.trim(),
                  );

                  // Si falló y el widget sigue vivo, mostramos error
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(vm.errorMessage ?? "Error desconocido"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  // NOTA: Si success == true, el AuthGate en main.dart
                  // detectará el cambio de usuario y redirigirá solo.
                },
              ),
            ),

            const SizedBox(height: 16),

            /// TEXTO SECUNDARIO (ACTIVACIÓN)
            TextButton(
              // Este lleva a la HU-03 Activación de Cuenta
              onPressed: () => Navigator.pushNamed(context, "/register"),
              child: Text(
                "¿Eres nuevo? Activa tu cuenta aquí",
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