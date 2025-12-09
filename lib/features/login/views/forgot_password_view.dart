import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Necesario para random

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../core/widgets/responsive_container.dart';

class ForgotPasswordView extends StatelessWidget {
  final emailCtrl = TextEditingController();

  ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8),
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        backgroundColor: const Color(0xFFE6EEF8),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xFFDDE6F3), offset: Offset(4, 4), blurRadius: 10),
              BoxShadow(
                  color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/recuperar.webp',
                width: 200,
                height: 210,
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
              Consumer<ForgotPasswordViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.errorMessage == null){
                    return const SizedBox.shrink();
                    }
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              Consumer<ForgotPasswordViewModel>(
                builder: (context, viewModel, _) {
                  return viewModel.isLoading
                      ? const CircularProgressIndicator()
                      : PrimaryButton(
                    text: "Enviar correo",
                    onPressed: () async {
                      if (emailCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text("Por favor ingresa un correo")),
                        );
                        return;
                      }
                      final success = await viewModel
                          .sendRecoveryEmail(emailCtrl.text);
                      if (success && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("¡Correo enviado!"),
                            content: const Text(
                                "Revisa tu bandeja de entrada..."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Cierra dialogo
                                  Navigator.pop(context); // Cierra pantalla
                                },
                                child: const Text("Aceptar"),
                              )
                            ],
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- BOTÓN ORIGINAL: REGENERAR JEFES/ADMIN ---
              TextButton(
                onPressed: () async {
                  // Definimos los datos a crear
                  final List<Map<String, dynamic>> usersToCreate = [
                    // --- ACADEMIAS ---
                    {
                      'email': 'flores@computacion.ipn.mx',
                      'pass': 'flores',
                      'name': 'Jefe Computación',
                      'role': 'jefe_academia',
                      'academies': ['COMPUTACION'],
                      'status': 'ACTIVO'
                    },
                    {
                      'email': 'marisol@electrica.ipn.mx',
                      'pass': 'marisol',
                      'name': 'Jefe Lab. Elect.',
                      'role': 'jefe_academia',
                      'academies': ['LAB. ELECT. Y CONTROL'],
                      'status': 'ACTIVO'
                    },
                    {
                      'email': 'abdiel@informatica.ipn.mx',
                      'pass': 'abdiel',
                      'name': 'Jefe Informática',
                      'role': 'jefe_academia',
                      'academies': ['INFORMATICA'],
                      'status': 'ACTIVO'
                    },
                    // --- TUTORIAS (ADMIN) ---
                    {
                      'email': 'fernando@tutorias.ipn.mx',
                      'pass': 'fernando',
                      'name': 'Fernando Admin',
                      'role': 'tutorias',
                      'academies': [],
                      'status': 'ACTIVO'
                    },
                  ];

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Iniciando SEEDER JEFES... (La app NO parpadeará)"),
                      duration: Duration(seconds: 4),
                    ),
                  );

                  FirebaseApp tempApp = await Firebase.initializeApp(
                    name: 'SecondaryApp',
                    options: Firebase.app().options,
                  );

                  FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
                  final firestore = FirebaseFirestore.instance;

                  int createdCount = 0;
                  int errorCount = 0;

                  try {
                    for (var userData in usersToCreate) {
                      try {
                        debugPrint("Procesando: ${userData['email']}...");
                        UserCredential cred =
                        await tempAuth.createUserWithEmailAndPassword(
                          email: userData['email'],
                          password: userData['pass'],
                        );

                        if (cred.user != null) {
                          await firestore
                              .collection('users')
                              .doc(cred.user!.uid)
                              .set({
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
                          await tempAuth.signOut();
                        }
                      } catch (e) {
                        errorCount++;
                      }
                    }

                    await tempApp.delete();

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("✅ Jefes Creados"),
                          content: Text(
                              "Se crearon: $createdCount\nFallaron/Existían: $errorCount"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            )
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                },
                child: const Text("REGENERAR JEFES (V2)",
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 10),

              // --- BOTÓN PARA BORRAR ALL
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("⚠️ PELIGRO: BORRAR TODO"),
                      content: const Text(
                          "¿Estás seguro? Esto eliminará TODOS los usuarios permanentemente."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("CANCELAR")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("SÍ, BORRAR TODO",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold))),
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
                    final snapshot = await usersRef.get();
                    WriteBatch batch = firestore.batch();
                    int batchCount = 0;

                    if (snapshot.docs.isEmpty) return;

                    for (var doc in snapshot.docs) {
                      batch.delete(doc.reference);
                      batchCount++;
                      if (batchCount >= 450) {
                        await batch.commit();
                        batch = firestore.batch();
                        batchCount = 0;
                      }
                    }
                    if (batchCount > 0) await batch.commit();

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("🗑️ Limpieza Terminada"),
                          content: const Text("Se eliminaron todos los usuarios."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"))
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                child: const Text(
                  "BORRAR BD (DELETE ALL)",
                  style:
                  TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================================
              // === NUEVO BOTÓN: GENERAR 37 ALUMNOS DEL EXCEL ===
              // ==========================================================
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[50], // Fondo suave para destacar
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Generando 37 Alumnos del Excel..."),
                      duration: Duration(seconds: 4),
                    ),
                  );

                  // 1. Configuración de Academias y Profesores (Hardcodeados para coincidir con los Jefes)
                  // Indice 0: Computación, 1: Eléctrica, 2: Informática
                  final academiesList = ['COMPUTACION', 'LAB. ELECT. Y CONTROL', 'INFORMATICA'];
                  final professorsMap = {
                    'COMPUTACION': 'flores@computacion.ipn.mx',
                    'LAB. ELECT. Y CONTROL': 'marisol@electrica.ipn.mx',
                    'INFORMATICA': 'abdiel@informatica.ipn.mx',
                  };

                  // 2. Generar lista de 37 estudiantes en memoria
                  List<Map<String, dynamic>> studentsToCreate = [];
                  final random = Random();

                  // Estados posibles
                  final statuses = ['PRE_REGISTRO', 'EN_CURSO', 'ACREDITADO', 'NO_ACREDITADO'];

                  for (int i = 1; i <= 37; i++) {
                    // Distribuir academias equitativamente (ciclo 0, 1, 2)
                    int academyIndex = (i - 1) % 3;
                    String academy = academiesList[academyIndex];
                    String assignedProfEmail = professorsMap[academy]!;

                    // Distribuir estados cíclicamente
                    String status = statuses[(i - 1) % 4];

                    // Determinar calificación según estado
                    double? grade;
                    if (status == 'ACREDITADO') {
                      grade = 6 + random.nextInt(5).toDouble(); // 6 a 10
                    } else if (status == 'NO_ACREDITADO') {
                      grade = random.nextInt(6).toDouble(); // 0 a 5
                    } else {
                      grade = null; // Pre-registro o en curso no tienen calif final
                    }

                    studentsToCreate.add({
                      'email': 'alumno$i@ipn.mx',
                      'pass': 'alumno123', // Contraseña genérica
                      'name': 'Alumno Excel $i',
                      'boleta': '202460${i.toString().padLeft(2, '0')}', // Genera boletas 20246001...
                      'role': 'alumno',
                      'academies': [academy],
                      'status': status,
                      'grade': grade,
                      'tutorEmail': (status != 'PRE_REGISTRO') ? assignedProfEmail : null, // Asigna profe si ya está en trámite
                    });
                  }

                  // 3. Inicializar Auth Secundaria
                  FirebaseApp tempApp = await Firebase.initializeApp(
                    name: 'SecondaryAppAlumnos', // Nombre distinto por seguridad
                    options: Firebase.app().options,
                  );
                  FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
                  final firestore = FirebaseFirestore.instance;

                  int successCount = 0;
                  int failCount = 0;

                  try {
                    for (var student in studentsToCreate) {
                      try {
                        // Crear usuario en Auth
                        UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
                          email: student['email'],
                          password: student['pass'],
                        );

                        if (cred.user != null) {
                          // Crear documento en Firestore
                          await firestore.collection('users').doc(cred.user!.uid).set({
                            'uid': cred.user!.uid,
                            'name': student['name'],
                            'email': student['email'],
                            'role': 'alumno',
                            'boleta': student['boleta'],
                            'academies': student['academies'], // Array como en el modelo original
                            'status': student['status'],
                            // Campos extra para simular el excel y asignación
                            'currentGrade': student['grade'],
                            'assignedTutorEmail': student['tutorEmail'],
                            'createdAt': FieldValue.serverTimestamp(),
                            'subjectsToTake': [], // Campo requerido en algunos modelos
                          });
                          successCount++;

                          // Limpieza sesión temporal
                          await tempAuth.signOut();
                        }
                      } catch (e) {
                        failCount++;
                        debugPrint("Error creando ${student['email']}: $e");
                      }
                    }

                    // 4. Limpiar App secundaria
                    await tempApp.delete();

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("🎓 Alumnos Generados"),
                          content: SingleChildScrollView(
                            child: Text(
                                "Proceso finalizado.\n\n"
                                    "✅ Creados: $successCount\n"
                                    "❌ Fallidos/Duplicados: $failCount\n\n"
                                    "Detalles:\n"
                                    "- Se asignaron profesores según academia.\n"
                                    "- Se distribuyeron estados (Pre, En curso, Acreditado, No Acred).\n"
                                    "- Se generaron calificaciones aleatorias."
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Aceptar"),
                            )
                          ],
                        ),
                      );
                    }

                  } catch (e) {
                    // Limpieza de emergencia
                    try { await tempApp.delete(); } catch (_) {}
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error script: $e")));
                    }
                  }
                },
                child: const Column(
                  children: [
                    Icon(Icons.people_alt_outlined, color: Colors.blueAccent),
                    SizedBox(height: 5),
                    Text(
                      "GENERAR 37 ALUMNOS (Excel)",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40), // Espacio final
            ],
          ),
        ),
      ),
    );
  }
}