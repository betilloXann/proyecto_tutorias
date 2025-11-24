import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

class RegisterView extends StatefulWidget {
  // VARIABLES QUE RECIBE DE LA PANTALLA ANTERIOR
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
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController personalEmailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController passCtrl;

  String? _fileName;

  @override
  void initState() {
    super.initState();
    // PRE-LLENAMOS EL NOMBRE CON EL DATO RECIBIDO
    nameCtrl = TextEditingController(text: widget.foundName);
    emailCtrl = TextEditingController();
    personalEmailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    passCtrl = TextEditingController();
  }

  // ... (El dispose y _pickDictamen quedan igual) ...
  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    personalEmailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _pickDictamen() async {
    setState(() {
      _fileName = "dictamen_${widget.boleta}.pdf";
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

            // SALUDO PERSONALIZADO
            Text(
              "Hola, ${widget.foundName.split(' ')[0]}", // Solo el primer nombre
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F5A93),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Confirma tus datos y completa tu registro",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // CAMPO NOMBRE (BLOQUEADO)
            TextInputField(
              label: "Nombre Completo (Verificado)",
              controller: nameCtrl,
              icon: Icons.person,
              readOnly: true, // <--- NO SE PUEDE EDITAR
            ),
            const SizedBox(height: 16),

            // ... (El resto de los campos quedan igual: Email, Phone, Pass) ...
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

            // SECCIÓN DICTAMEN (Igual que antes)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Dictamen Escaneado", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDictamen,
              child: Container(
                // ... (Estilo igual que antes) ...
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
                    Expanded(child: Text(_fileName ?? "Toca para subir...")),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            PrimaryButton(
              text: "Finalizar Activación",
              onPressed: () {
                // Aquí usamos widget.boleta para actualizar en Firebase
                print("Actualizando usuario: ${widget.boleta}");
              },
            ),
          ],
        ),
      ),
    );
  }
}