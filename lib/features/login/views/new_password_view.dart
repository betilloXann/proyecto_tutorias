import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

class NewPasswordView extends StatefulWidget {
  const NewPasswordView({super.key});

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  late final TextEditingController passwordCtrl;
  late final TextEditingController confirmCtrl;

  bool obscure1 = true;
  bool obscure2 = true;

  @override
  void initState() {
    super.initState();
    passwordCtrl = TextEditingController();
    confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    // IMPORTANTE: Limpiar memoria
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6EEF8),
        elevation: 0,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/logo.svg', height: 120),
            const SizedBox(height: 20),
            const Text(
              "Nueva contraseña",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Crea una nueva contraseña segura para tu cuenta.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            /// CAMPO: Nueva contraseña
            TextInputField(
              label: "Nueva contraseña",
              controller: passwordCtrl,
              obscureText: obscure1, // CORREGIDO AQUÍ
              suffixIcon: IconButton(
                icon: Icon(
                  obscure1 ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() => obscure1 = !obscure1);
                },
              ),
            ),

            const SizedBox(height: 20),

            /// CAMPO: Confirmar contraseña
            TextInputField(
              label: "Confirmar contraseña",
              controller: confirmCtrl,
              obscureText: obscure2, // CORREGIDO AQUÍ
              suffixIcon: IconButton(
                icon: Icon(
                  obscure2 ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() => obscure2 = !obscure2);
                },
              ),
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              text: "Guardar nueva contraseña",
              onPressed: () {
                // TODO: Lógica de validación y cambio
              },
            ),
          ],
        ),
      ),
    );
  }
}