import 'dart:io'; // IMPORTANTE: Para manejar el archivo File
import 'package:file_picker/file_picker.dart'; // IMPORTANTE: Para seleccionar archivos
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../../../data/repositories/auth_repository.dart'; // Tu Repo

class RegisterView extends StatefulWidget {
  final String boleta;
  final String foundName;
  final String docId; // El ID del documento a actualizar

  const RegisterView({
    super.key,
    required this.boleta,
    required this.foundName,
    required this.docId,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController personalEmailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController passCtrl;

  // Variables para el archivo y carga
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenamos el nombre
    nameCtrl = TextEditingController(text: widget.foundName);
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

  // --- 1. LÓGICA PARA SELECCIONAR ARCHIVO ---
  Future<void> _pickDictamen() async {
    // Abre el selector de archivos (PDF, JPG, PNG)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  // --- 2. LÓGICA PARA ENVIAR TODO A FIREBASE ---
  Future<void> _submitActivation() async {
    // Validaciones básicas
    if (emailCtrl.text.isEmpty ||
        personalEmailCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor llena todos los campos"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes subir tu Dictamen escaneado"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Llamamos al repositorio
      await context.read<AuthRepository>().activateAccount(
        docId: widget.docId,
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        personalEmail: personalEmailCtrl.text.trim(),
        dictamenFile: _selectedFile!,
      );

      if (!mounted) return;

      // ¡ÉXITO!
      // Navegamos al Home y borramos todo el historial de login para que no pueda regresar
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Mostrar error amigable
      String message = e.toString().replaceAll("Exception: ", "");
      if (message.contains("email-already-in-use")) {
        message = "Este correo ya está registrado en otra cuenta.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SvgPicture.asset("assets/images/logo.svg", height: 80),
            const SizedBox(height: 20),

            Text(
              "Hola, ${widget.foundName.split(' ')[0]}",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F5A93),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Confirma tus datos y sube tu dictamen",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // CAMPO NOMBRE (BLOQUEADO)
            TextInputField(
              label: "Nombre Completo",
              controller: nameCtrl,
              icon: Icons.person,
              readOnly: true,
            ),
            const SizedBox(height: 16),

            TextInputField(
              label: "Correo Institucional",
              controller: emailCtrl,
              icon: Icons.school_outlined,
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

            // SECCIÓN DICTAMEN
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Dictamen Escaneado (PDF/Foto)",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F5A93))),
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
                        _fileName ?? "Toca para subir archivo...",
                        style: TextStyle(
                          color: _fileName != null ? Colors.black : Colors.grey,
                          fontWeight: _fileName != null ? FontWeight.bold : FontWeight.normal,
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

            // BOTÓN PRINCIPAL
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                text: "Finalizar Activación",
                onPressed: _submitActivation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}