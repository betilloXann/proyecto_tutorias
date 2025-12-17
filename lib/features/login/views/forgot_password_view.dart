import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

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
                width: 210,
                height: 220,
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
                  if (viewModel.errorMessage == null) {
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

                  FirebaseAuth tempAuth =
                      FirebaseAuth.instanceFor(app: tempApp);
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
                            'email_inst': userData['email'], // Ajustado a email_inst
                            'email_personal': 'personal.${userData['email'].split('@')[0]}@gmail.com', // Dummy personal email
                            'role': userData['role'],
                            'status': userData['status'],
                            'academies': userData['academies'],
                            'boleta': userData['boleta'] ?? '',
                            'subjects_to_take': [],
                            'created_at': FieldValue.serverTimestamp(),
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

              // ==========================================================
              // === BOTÓN: BORRADO DE LA BASE DE DATOS SOLO ALUMNOS    ===
              // ==========================================================
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("⚠️ ELIMINAR ALUMNOS"),
                      content: const Text(
                          "Se eliminarán SOLO los usuarios con rol 'student'.\n\n"
                          "• Jefes de Academia: SE CONSERVAN\n"
                          "• Admin Tutorías: SE CONSERVA\n"
                          "• Auth: Se intentará borrar la cuenta si la contraseña es 'alumno123'."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("CANCELAR")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("SÍ, BORRAR ALUMNOS",
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
                        content: Text("Iniciando limpieza de alumnos..."),
                        duration: Duration(seconds: 5)),
                  );

                  // Inicializamos contadores
                  int deletedFirestore = 0;
                  int deletedAuth = 0;
                  //int errors = 0;

                  try {
                    // 2. Configuración para Auth "Hack" (App Secundaria)
                    FirebaseApp tempApp = await Firebase.initializeApp(
                      name: 'DeleteWorkerApp',
                      options: Firebase.app().options,
                    );
                    FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
                    final firestore = FirebaseFirestore.instance;

                    // 3. CONSULTA SEGURA: Traer SOLO estudiantes
                    // Esto garantiza que Jefes y Tutorías ni siquiera se lean.
                    final snapshot = await firestore
                        .collection('users')
                        .where('role', isEqualTo: 'student') 
                        .get();

                    if (snapshot.docs.isEmpty) {
                      await tempApp.delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No hay alumnos para borrar.")));
                      }
                      return;
                    }

                    // Preparamos el batch para Firestore
                    WriteBatch batch = firestore.batch();
                    int batchCount = 0;

                    // 4. Iterar sobre cada alumno encontrado
                    for (var doc in snapshot.docs) {
                      final data = doc.data();
                      final email = data['email_inst'] as String?;

                      // --- A. Borrado de Auth (Intento) ---
                      if (email != null) {
                        try {
                          // Intentamos loguear con la contraseña por defecto de tus seeders
                          await tempAuth.signInWithEmailAndPassword(
                              email: email, password: 'alumno123');
                          
                          // Si entra, lo borramos
                          if (tempAuth.currentUser != null) {
                            await tempAuth.currentUser!.delete();
                            deletedAuth++;
                            debugPrint("Auth borrado: $email");
                          }
                        } catch (e) {
                          // Si falla (ej. contraseña cambiada o ya no existe en Auth), 
                          // solo lo logueamos y seguimos con Firestore.
                          debugPrint("No se pudo borrar Auth de $email: $e");
                        }
                      }

                      // --- B. Borrado de Firestore ---
                      batch.delete(doc.reference);
                      deletedFirestore++;
                      batchCount++;

                      // Commit cada 400 docs para no saturar
                      if (batchCount >= 400) {
                        await batch.commit();
                        batch = firestore.batch();
                        batchCount = 0;
                      }
                    }

                    // Commit final de los restantes
                    if (batchCount > 0) await batch.commit();

                    // Limpieza de la app secundaria
                    await tempApp.delete();

                    // 5. Resultado
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("🧹 Limpieza Finalizada"),
                          content: Text(
                              "Resultados:\n\n"
                              "✅ Alumnos en BD borrados: $deletedFirestore\n"
                              "✅ Cuentas Auth borradas: $deletedAuth\n"
                              "🛡️ Jefes y Admins: INTACTOS\n\n"
                              "Nota: Si 'Cuentas Auth' es menor, es porque esos alumnos cambiaron su contraseña o ya no existían."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Perfecto"))
                          ],
                        ),
                      );
                    }

                  } catch (e) {
                    debugPrint("Error fatal: $e");
                    // Intentar limpiar la app secundaria si falló algo crítico
                  try { await Firebase.app('DeleteWorkerApp').delete(); } catch (_) {}                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")));
                    }
                  }
                },
                child: const Text(
                  "BORRAR SOLO ALUMNOS",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================================
              // === BOTÓN CORREGIDO: GENERAR 40 ALUMNOS CON 5 ESTATUS ===
              // ==========================================================
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Generando 40 Alumnos... (Espera por favor)"),
                      duration: Duration(seconds: 4),
                    ),
                  );

                  // 1. Configuración de Academias y Profesores
                  final academiesList = [
                    'COMPUTACION',
                    'LAB. ELECT. Y CONTROL',
                    'INFORMATICA'
                  ];
                  // Correos de los jefes que fungirán como tutores
                  final professorsMap = {
                    'COMPUTACION': 'flores@computacion.ipn.mx',
                    'LAB. ELECT. Y CONTROL': 'marisol@electrica.ipn.mx',
                    'INFORMATICA': 'abdiel@informatica.ipn.mx',
                  };

                  // 2. Preparar datos en memoria
                  List<Map<String, dynamic>> studentsToCreate = [];
                  final random = Random();
                  
                  // LISTA DE LOS 5 ESTATUS
                  final statuses = [
                    'PRE_REGISTRO',
                    'PENDIENTE_ASIGNACION',
                    'EN_CURSO',
                    'ACREDITADO',
                    'NO_ACREDITADO'
                  ];

                  // Materias dummy para simular un registro real
                  final dummySubjects = [
                    'FUNDAMENTOS DE PROGRAMACIÓN',
                    'ESTRUCTURAS DE DATOS',
                    'BASES DE DATOS',
                    'INGENIERÍA DE SOFTWARE'
                  ];

                  for (int i = 1; i <= 40; i++) {
                    // Cíclico: 0, 1, 2 (Academias)
                    int academyIndex = (i - 1) % 3;
                    String academy = academiesList[academyIndex];
                    String assignedProfEmail = professorsMap[academy]!;

                    // Cíclico: 0, 1, 2, 3, 4 (Los 5 estatus)
                    // CORRECCIÓN AQUÍ: Se usa % 5 para incluir todos
                    String status = statuses[(i - 1) % 5];

                    // Calificación
                    double? grade;
                    if (status == 'ACREDITADO') {
                      grade = 6 + random.nextInt(5).toDouble(); // 6 a 10
                    } else if (status == 'NO_ACREDITADO') {
                      grade = random.nextInt(6).toDouble(); // 0 a 5
                    } else {
                      grade = null;
                    }

                    // Email único
                    String email = 'alumno$i@ipn.mx';

                    // Mapa de estatus (Nuevo requerimiento del UserModel)
                    Map<String, String> academyStatus = {
                      academy: status
                    };

                    studentsToCreate.add({
                      'email': email,
                      'pass': 'alumno123',
                      'name': 'Alumno Test $i',
                      'boleta': '202460${i.toString().padLeft(2, '0')}',
                      'role': 'student', 
                      'academy': academy,
                      'status': status,
                      'academy_status': academyStatus,
                      'final_grade': grade,
                      'tutorEmail': (status != 'PRE_REGISTRO' && status != 'PENDIENTE_ASIGNACION')
                          ? assignedProfEmail
                          : null,
                    });
                  }

                  // 3. Inicializar App Secundaria
                  FirebaseApp tempApp = await Firebase.initializeApp(
                    name: 'SecondaryAppAlumnos',
                    options: Firebase.app().options,
                  );
                  FirebaseAuth tempAuth =
                      FirebaseAuth.instanceFor(app: tempApp);
                  final firestore = FirebaseFirestore.instance;

                  int successCount = 0;
                  int failCount = 0;

                  try {
                    for (var student in studentsToCreate) {
                      try {
                        // Crear en Authentication
                        UserCredential cred =
                            await tempAuth.createUserWithEmailAndPassword(
                          email: student['email'],
                          password: student['pass'],
                        );

                        if (cred.user != null) {
                          // Crear en Firestore
                          await firestore
                              .collection('users')
                              .doc(cred.user!.uid)
                              .set({
                            'uid': cred.user!.uid,
                            'name': student['name'],
                            'email_inst': student['email'], 
                            'email_personal': 'personal.${student['email'].split('@')[0]}@gmail.com',
                            'role': student['role'],
                            'boleta': student['boleta'],
                            'academies': [student['academy']], 
                            'status': student['status'], 
                            'academy_status': student['academy_status'], 
                            'final_grade': student['final_grade'],
                            'assigned_tutor_email': student['tutorEmail'],
                            'created_at': FieldValue.serverTimestamp(),
                            'updated_at': FieldValue.serverTimestamp(),
                            'subjects_to_take': dummySubjects.sublist(0, 2),
                            'phone': '55${Random().nextInt(90000000) + 10000000}',
                            'dictamen_url': 'https://firebasestorage.googleapis.com/v0/b/dummy-bucket/o/dictamen.pdf?alt=media',
                          });
                          successCount++;
                          await tempAuth.signOut();
                        }
                      } catch (e) {
                        failCount++;
                        debugPrint("Error creando ${student['email']}: $e");
                      }
                    }

                    // 4. Limpieza final
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
                              "Se han creado 40 alumnos distribuidos en los 5 estados."
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
                    try {
                      await tempApp.delete();
                    } catch (_) {}
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error script: $e")));
                    }
                  }
                },
                child: const Column(
                  children: [
                    Icon(Icons.people_alt_outlined, color: Colors.blueAccent),
                    SizedBox(height: 5),
                    Text(
                      "GENERAR 40 ALUMNOS (5 ESTATUS)",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}