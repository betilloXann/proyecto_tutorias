import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controladores
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;     // Institucional
  late final TextEditingController personalEmailCtrl; // NUEVO
  late final TextEditingController phoneCtrl;         // NUEVO
  late final TextEditingController passCtrl;

  // Variable para simular que seleccionaron un archivo
  String? _fileName;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    personalEmailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    personalEmailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  // Método simulado para seleccionar archivo (requiere file_picker más adelante)
  void _pickDictamen() async {
    // Aquí iría la lógica de FilePicker
    setState(() {
      _fileName = "dictamen_2025.pdf"; // Simulación visual
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
            const SizedBox(height: 10),
            // Logo más pequeño para que quepan todos los campos
            SvgPicture.asset("assets/images/logo.svg", height: 80),
            const SizedBox(height: 20),

            Text(
              "Activar Cuenta",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F5A93),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Completa tus datos para finalizar el registro",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // --- CAMPOS DE TEXTO ---

            TextInputField(
              label: "Nombre Completo",
              controller: nameCtrl,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.school_outlined, // Icono de escuela
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextInputField(
              label: "Correo Personal",
              controller: personalEmailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextInputField(
              label: "Teléfono Celular",
              controller: phoneCtrl,
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextInputField(
              label: "Crear Contraseña",
              controller: passCtrl,
              icon: Icons.lock_outline,
              obscureText: true,
            ),

            const SizedBox(height: 24),

            // --- SECCIÓN CARGA DE DICTAMEN (NUEVO) ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Dictamen Escaneado (PDF/Foto)",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F5A93))
              ),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _pickDictamen,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileName ?? "Toca para subir tu dictamen...",
                        style: TextStyle(
                          color: _fileName != null ? Colors.black : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_fileName != null)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            PrimaryButton(
              text: "Activar y Continuar",
              onPressed: () {
                // Aquí conectarás con la lógica de envío
              },
            ),
            const SizedBox(height: 20), // Espacio final
          ],
        ),
      ),
    );
  }
}