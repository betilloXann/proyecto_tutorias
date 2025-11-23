import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

// AHORA ES STATEFULWIDGET
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controladores
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController passCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    // Limpiamos memoria
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparente para ver el fondo
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SvgPicture.asset("assets/images/logo.svg", height: 120),
            const SizedBox(height: 24),
            Text(
              "Crear Cuenta", // Nota: Esto será 'Activar Cuenta' según tu HU-03
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F5A93),
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
              keyboardType: TextInputType.emailAddress, // AGREGADO
            ),

            const SizedBox(height: 16),

            TextInputField(
              label: "Contraseña",
              controller: passCtrl,
              icon: Icons.lock_outline,
              obscureText: true, // CORREGIDO AQUÍ
            ),

            const SizedBox(height: 32),

            PrimaryButton(
              text: "Continuar",
              onPressed: () {
                // Aquí conectarás con la lógica de HU-03 (Activación)
                // Navigator.pushNamed(context, "/verify");
              },
            ),
          ],
        ),
      ),
    );
  }
}