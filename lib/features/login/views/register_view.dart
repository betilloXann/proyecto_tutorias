import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for kIsWeb and Uint8List
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../../../data/repositories/auth_repository.dart';

class RegisterView extends StatefulWidget {
  final String boleta;
  final String foundName;
  final String docId;

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
  late final TextEditingController nameCtrl, emailCtrl, personalEmailCtrl, phoneCtrl, passCtrl;

  // --- UPDATED State for Web/Mobile file handling ---
  String? _fileName;
  // FIX: Renamed to camelCase
  File? _selectedFileMobile;
  Uint8List? _selectedFileWeb;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  // --- UPDATED file picking logic ---
  Future<void> _pickDictamen() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          _selectedFileWeb = result.files.single.bytes;
          _selectedFileMobile = null;
        } else {
          _selectedFileMobile = File(result.files.single.path!);
          _selectedFileWeb = null;
        }
      });
    }
  }

  // --- UPDATED submission logic ---
  Future<void> _submitActivation() async {
    // FIX: Added context.mounted check before showing snackbar
    if (emailCtrl.text.isEmpty || personalEmailCtrl.text.isEmpty || phoneCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor llena todos los campos"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // FIX: Updated validation to camelCase and added context.mounted check
    if (_selectedFileMobile == null && _selectedFileWeb == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes subir tu Dictamen escaneado"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // FIX: Updated activateAccount call to use camelCase parameters
      await context.read<AuthRepository>().activateAccount(
        docId: widget.docId,
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        personalEmail: personalEmailCtrl.text.trim(),
        dictamenFileName: _fileName!,
        dictamenFileMobile: _selectedFileMobile,
        dictamenFileWeb: _selectedFileWeb,
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

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

            TextInputField(label: "Nombre Completo", controller: nameCtrl, icon: Icons.person, readOnly: true),
            const SizedBox(height: 16),
            TextInputField(label: "Correo Institucional", controller: emailCtrl, icon: Icons.school_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextInputField(label: "Correo Personal", controller: personalEmailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextInputField(label: "Teléfono Celular", controller: phoneCtrl, icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextInputField(label: "Crear Contraseña", controller: passCtrl, icon: Icons.lock_outline, obscureText: true),
            const SizedBox(height: 24),

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
