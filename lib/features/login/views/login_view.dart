import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// --- Imports (Tus widgets de UI) ---
import '../../../theme/primary_button.dart';
import '../../../theme/text_input_field.dart';

// <-- 1. Imports añadidos
import 'package:provider/provider.dart';
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart'; // Ajusta esta ruta si es necesario

// <-- 2. Convertido a StatefulWidget
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // <-- 3. Controladores movidos aquí
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // <-- 4. Variable de estado de carga
  bool _isLoading = false;

  // <-- 5. Método para manejar el login
  Future<void> _handleLogin() async {
    // Evita doble tap
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Obtenemos el repositorio
      final authRepo = context.read<AuthRepository>();

      // 2. Llamamos al método de login
      await authRepo.signInWithEmailAndPassword(
        email: emailCtrl.text,
        password: passwordCtrl.text,
      );

      // 3. ¡LISTO! No necesitas hacer Navigator.push.
      // El AuthGate en tu main.dart detectará el nuevo usuario
      // y automáticamente te llevará al HomeMenuView.

    } catch (e) {
      // 4. Si hay un error (del 'throw Exception' en el repositorio)
      // Lo mostramos en un SnackBar
      if (mounted) { // Verificamos que el widget aún esté en pantalla
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // Limpiamos el "Exception: " del mensaje
              e.toString().replaceAll("Exception: ", ""),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 5. Siempre quitamos el loading, incluso si hay error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // <-- 6. Añadimos dispose() para limpiar los controladores
  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

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
            SvgPicture.asset(
              "assets/images/logo.svg",
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              "Iniciar Sesión",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            TextInputField(
              label: "Contraseña",
              controller: passwordCtrl,
              icon: Icons.lock_outline,
              obscure: true,
            ),
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

            // <-- 7. Lógica de carga en el botón
            SizedBox(
              height: 56, // Damos una altura fija para que no "salte"
              width: double.infinity,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator()) // Muestra loading
                  : PrimaryButton(
                text: "Ingresar",
                onPressed: _handleLogin, // <-- Llama a nuestro método
              ),
            ),
            // Fin del cambio

            const SizedBox(height: 16),
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