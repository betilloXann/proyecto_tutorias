import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../core/widgets/responsive_container.dart';


class ForgotPasswordView extends StatelessWidget {
  final emailCtrl = TextEditingController();

  ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

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
      // 2. Envolvemos el cuerpo con ResponsiveContainer
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/image4.svg',
                width: 200,
                height: 210,
                //width: 200,
//                       height: 180,
              ),
              const SizedBox(height: 20),
              const Text(
                "Recuperar contraseña",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              TextInputField(
                label: "Correo electrónico",
                controller: emailCtrl,
                icon: Icons.email_outlined,
              ),

              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 30),

              viewModel.isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                text: "Enviar correo",
                onPressed: () async {
                  if (emailCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Por favor ingresa un correo")),
                    );
                    return;
                  }

                  final success = await viewModel.sendRecoveryEmail(emailCtrl.text);

                  if (success && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("¡Correo enviado!"),
                        content: const Text("Revisa tu bandeja de entrada (y spam) para restablecer tu contraseña."),
                        actions: [
    TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text("Aceptar"),
                          )
                        ],
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              TextButton(
                // --- SCRIPT DE DESTRUCCIÓN MASIVA ---
                onPressed: () async {
                  // 1. Confirmación de seguridad (Opcional, pero recomendada para no borrar por error)
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("⚠️ BORRAR TODO ⚠️"),
                      content: const Text(
                          "¿Estás seguro? Esto eliminará TODOS los usuarios de la base de datos permanentemente. No se puede deshacer."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("CANCELAR")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("SÍ, BORRAR TODO",
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Eliminando usuarios..."),
                        duration: Duration(seconds: 10)),
                  );

                  try {
                    final firestore = FirebaseFirestore.instance;
                    final usersRef = firestore.collection('users');

                    // 2. Obtener todos los documentos
                    final snapshot = await usersRef.get();
                    WriteBatch batch = firestore.batch();
                    int deletedCount = 0;
                    int batchCount = 0;

                    if (snapshot.docs.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("La base de datos ya está vacía.")),
                        );
                      }
                      return;
                    }

                    // 3. Iterar y borrar
                    for (var doc in snapshot.docs) {
                      batch.delete(doc.reference);
                      deletedCount++;
                      batchCount++;

                      // Límite de Batch es 500, usamos 450 por seguridad
                      if (batchCount >= 450) {
                        await batch.commit();
                        batch = firestore.batch(); // Crear nuevo batch
                        batchCount = 0;
                      }
                    }

                    // Commit final de los restantes
                    if (batchCount > 0) {
                      await batch.commit();
                    }

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("🗑️ Limpieza Terminada"),
                          content: Text("Se eliminaron $deletedCount usuarios."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"))
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Error al borrar: $e"),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                // --- FIN DEL SCRIPT ---
                child: const Text(
                  "¿No recibiste el correo? (BORRAR BD)",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}