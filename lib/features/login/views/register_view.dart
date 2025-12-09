import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/widgets/responsive_container.dart';

class RegisterView extends StatefulWidget {
  final String boleta;
  final String foundName;
  final String docId;
  final String email;

  const RegisterView({
    super.key,
    required this.boleta,
    required this.foundName,
    required this.docId,
    required this.email,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController nameCtrl,
      emailCtrl,
      personalEmailCtrl,
      phoneCtrl,
      passCtrl,
      confirmPassCtrl;
  String? _fileName;
  File? _selectedFileMobile;
  Uint8List? _selectedFileWeb;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.foundName);
    emailCtrl = TextEditingController();
    personalEmailCtrl = TextEditingController(text: widget.email);
    phoneCtrl = TextEditingController();
    passCtrl = TextEditingController();
    confirmPassCtrl = TextEditingController(); // Inicializar
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    personalEmailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _submitActivation() async {
    if (passCtrl.text != confirmPassCtrl.text) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Las contraseñas no coinciden"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (emailCtrl.text.isEmpty ||
        personalEmailCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor llena todos los campos"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_selectedFileMobile == null && _selectedFileWeb == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes subir tu Dictamen escaneado"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
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

      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    // --- FIX: Get the LAST word of the name ---
    final nameParts = widget.foundName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.last : widget.foundName;

    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 40 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/registro.webp',
                height: 180,
                width: 200,
              ),
              const SizedBox(height: 24),

              Text(
                "Hola, $firstName",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: const Color(0xFF2F5A93),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Confirma tus datos y sube tu dictamen",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),

              const SizedBox(height: 32),

              TextInputField(
                label: "Nombre Completo",
                controller: nameCtrl,
                icon: Icons.person,
                readOnly: true,
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
                label: "Correo Institucional",
                controller: emailCtrl,
                icon: Icons.school_outlined,
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
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // NUEVO CAMPO: Confirmar Contraseña
              TextInputField(
                label: "Confirmar Contraseña",
                controller: confirmPassCtrl,
                icon: Icons.lock_outline,
                obscureText:
                    !_isPasswordVisible, // Usa la misma visibilidad o crea una variable nueva
              ),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Dictamen Escaneado (PDF o Imagen)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F5A93),
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              InkWell(
                onTap: _pickDictamen,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
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
                          _fileName ?? "Toca para seleccionar archivo",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _fileName != null
                                ? Colors.black
                                : Colors.grey,
                            fontWeight: _fileName != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_fileName != null)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

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
      ),
    );
  }
}
