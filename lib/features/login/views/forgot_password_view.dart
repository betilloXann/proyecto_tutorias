import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Necesario para la instancia secundaria
import 'package:firebase_auth/firebase_auth.dart'; // <--- FALTABA ESTE
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

              // Asegúrate de tener estos imports al inicio de tu archivo:
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

              TextButton(
                onPressed: () async {
                  // Definimos los datos a crear
                  final List<Map<String, dynamic>> usersToCreate = [
                    // --- ACADEMIAS ---
                    {
                      'email': 'flores@gmail.com', 'pass': 'flores', 'name': 'Jefe Computación',
                      'role': 'jefe_academia', 'academies': ['COMPUTACION'], 'status': 'ACTIVO'
                    },
                    {
                      'email': 'marisol@gmail.com', 'pass': 'marisol', 'name': 'Jefe Lab. Elect.',
                      'role': 'jefe_academia', 'academies': ['LAB. ELECT. Y CONTROL'], 'status': 'ACTIVO'
                    },
                    {
                      'email': 'abdiel@gmail.com', 'pass': 'abdiel', 'name': 'Jefe Informática',
                      'role': 'jefe_academia', 'academies': ['INFORMATICA'], 'status': 'ACTIVO'
                    },
                    // --- TUTORIAS (ADMIN) ---
                    {
                      'email': 'fernando@gmail.com', 'pass': 'fernando', 'name': 'Fernando Admin',
                      'role': 'tutorias', 'academies': [], 'status': 'ACTIVO'
                    },
                  ];

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Iniciando SEEDER en segundo plano... (La app NO parpadeará)"),
                      duration: Duration(seconds: 4),
                    ),
                  );

                  // 1. TRUCO: Creamos una instancia secundaria de Firebase
                  // Esto evita que FirebaseAuth.instance principal detecte el login y cambie la pantalla
                  FirebaseApp tempApp = await Firebase.initializeApp(
                    name: 'SecondaryApp',
                    options: Firebase.app().options,
                  );

                  // Obtenemos el Auth de esa instancia secundaria
                  FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
                  final firestore = FirebaseFirestore.instance; // Usamos el Firestore principal (está bien)

                  int createdCount = 0;
                  int errorCount = 0;

                  try {
                    for (var userData in usersToCreate) {
                      try {
                        debugPrint("Procesando: ${userData['email']}...");

                        // 2. Crear usuario en la instancia SECUNDARIA
                        // Esto loguea al usuario en 'tempAuth', pero NO en la app principal.
                        UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
                          email: userData['email'],
                          password: userData['pass'],
                        );

                        // 3. Crear documento en Firestore (Usando el UID generado)
                        if (cred.user != null) {
                          await firestore.collection('users').doc(cred.user!.uid).set({
                            'uid': cred.user!.uid,
                            'name': userData['name'],
                            'email': userData['email'],
                            'role': userData['role'],
                            'status': userData['status'],
                            'academies': userData['academies'],
                            'boleta': userData['boleta'] ?? '',
                            'subjectsToTake': [],
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          createdCount++;
                          debugPrint("--> ÉXITO: ${userData['email']}");

                          // Ya no necesitamos signOut() porque 'tempAuth' no afecta la UI
                          // Pero lo hacemos por limpieza interna de la instancia temporal
                          await tempAuth.signOut();
                        }

                      } catch (e) {
                        debugPrint("--> ERROR en ${userData['email']}: $e");
                        // Si el error es "email-already-in-use", podríamos intentar
                        // actualizar solo el Firestore buscando el UID por email,
                        // pero eso requiere Admin SDK. Aquí solo saltamos.
                        errorCount++;
                      }
                    }

                    // 4. Limpieza: Borramos la app temporal para liberar memoria
                    await tempApp.delete();

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("✅ Proceso Terminado"),
                          content: Text("Se crearon exitosamente: $createdCount\nFallaron/Ya existían: $errorCount\n\nIntenta hacer Login ahora."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context); // Regresar al Login
                              },
                              child: const Text("Ir al Login"),
                            )
                          ],
                        ),
                      );
                    }

                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fatal: $e")));
                    }
                  }
                },
                child: const Text("REGENERAR USUARIOS (SEED V2)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10), // Espacio opcional

              // --- BOTÓN PARA BORRAR TODO ---
              TextButton(
                onPressed: () async {
                  // 1. Confirmación de seguridad
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("⚠️ PELIGRO: BORRAR TODO"),
                      content: const Text(
                          "¿Estás seguro? Esto eliminará TODOS los usuarios de la base de datos de Firestore permanentemente. No se puede deshacer."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("CANCELAR")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("SÍ, BORRAR TODO",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Eliminando todos los usuarios..."),
                        duration: Duration(seconds: 5)),
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

                    // 3. Iterar y borrar en lotes
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
                          content: Text("Se eliminaron $deletedCount usuarios de la base de datos."),
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
                child: const Text(
                  "BORRAR BD (DELETE ALL)",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}