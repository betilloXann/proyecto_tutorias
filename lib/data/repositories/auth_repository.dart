import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer';
import '../../../data/models/enrollment_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  AuthRepository({required FirebaseAuth firebaseAuth})
      : _auth = firebaseAuth,
        _db = FirebaseFirestore.instance,
        _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') throw Exception('No se encontró usuario con ese correo.');
      if (e.code == 'wrong-password') throw Exception('Contraseña incorrecta.');
      throw Exception(e.message ?? 'Error de autenticación.');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> checkStudentStatus(String boleta) async {
    try {
      final snapshot = await _db.collection('users').where('boleta', isEqualTo: boleta).limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return UserModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw Exception("Error al buscar estudiante: $e");
    }
  }

  Future<bool> checkCurpExists(String curp) async {
    try {
      // Buscamos si hay algún usuario con ese CURP
      final snapshot = await _db
          .collection('users')
          .where('curp', isEqualTo: curp)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception("Error al verificar CURP: $e");
    }
  }

  Future<void> activateAccount({
    required String docId,
    required String email,
    required String password,
    required String phone,
    required String personalEmail,
    required String dictamenFileName,
    File? dictamenFileMobile,
    Uint8List? dictamenFileWeb,
    required String curp,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      String uid = cred.user!.uid;

      String fileExt = dictamenFileName.split('.').last;
      Reference ref = _storage.ref().child('dictamenes/$uid.$fileExt');

      if (kIsWeb) {
        if (dictamenFileWeb == null) throw Exception("El archivo del dictamen es requerido para la web.");
        await ref.putData(dictamenFileWeb);
      } else {
        if (dictamenFileMobile == null) throw Exception("El archivo del dictamen es requerido para móvil.");
        await ref.putFile(dictamenFileMobile);
      }
      
      String downloadUrl = await ref.getDownloadURL();

      await _db.collection('users').doc(docId).update({
        'uid': uid,
        'email_inst': email,
        'email_personal': personalEmail,
        'phone': phone,
        'dictamen_url': downloadUrl,
        'curp': curp,
        'status': 'PENDIENTE_ASIGNACION',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Error al activar: $e");
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final snapshot = await _db.collection('users').where('uid', isEqualTo: user.uid).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      log("Error obteniendo datos de usuario", error: e);
      return null;
    }
  }

  // --- FIX: Make student upload additive ---
  Future<void> bulkRegisterStudents(List<Map<String, dynamic>> students, Function(int) onProgress) async {
    // Usamos batches, pero con control de límite (Firestore permite max 500 ops por batch)
    WriteBatch batch = _db.batch();
    int operationCount = 0;
    int processedCount = 0;

    for (final studentData in students) {
      final String boleta = studentData['boleta'];
      DocumentReference userRef;
      bool isNewUser = false;

      // 1. Verificar si el alumno ya existe
      final querySnapshot = await _db.collection('users').where('boleta', isEqualTo: boleta).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        userRef = _db.collection('users').doc();
        isNewUser = true;
      } else {
        userRef = querySnapshot.docs.first.reference;
      }

      // 2. Crear o Actualizar el documento del Usuario (User Model)
      if (isNewUser) {
        batch.set(userRef, {
          'uid': userRef.id, // Es buena práctica guardar el ID dentro del doc
          'boleta': boleta,
          'name': studentData['name'],
          'email_inst': studentData['email_inst'],
          'academies': studentData['academies'],
          'subjects_to_take': studentData['subjects_to_take'],
          'status': 'PRE_REGISTRO',
          'role': 'student',
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(userRef, {
          'academies': FieldValue.arrayUnion(studentData['academies'] ?? []),
          'subjects_to_take': FieldValue.arrayUnion(studentData['subjects_to_take'] ?? []),
        });
      }
      operationCount++;

      // 3. CREAR INSCRIPCIONES (ENROLLMENTS)
      // Esto es vital para que el "Reporte Semestral" detecte las materias en el periodo seleccionado

      final String targetPeriod = studentData['target_period'] ?? EnrollmentModel.getPeriodId(DateTime.now());
      final List<String> subjects = List<String>.from(studentData['subjects_to_take'] ?? []);

      // Nota: Asignamos la primera academia disponible como default.
      final String defaultAcademy = (studentData['academies'] as List).isNotEmpty
          ? (studentData['academies'] as List).first
          : 'GENERAL';

      for (final subject in subjects) {
        // Creamos una referencia nueva para la inscripción
        final enrollmentRef = _db.collection('enrollments').doc();

        batch.set(enrollmentRef, {
          'uid': userRef.id,          // Enlace al alumno
          'subject': subject,         // Nombre de la materia
          'periodId': targetPeriod,   // <--- AQUÍ SE APLICA EL PERIODO SELECCIONADO
          'status': 'PRE_REGISTRO',
          'academy': defaultAcademy,
          'professor': '',            // Se asignará después
          'schedule': '',
          'salon': '',
          'final_grade': null,
          'assigned_at': FieldValue.serverTimestamp(),
        });
        operationCount++;
      }

      processedCount++;
      onProgress(processedCount);

      // 4. Seguridad: Si el batch se acerca al límite de 500, guardar y limpiar
      if (operationCount >= 450) {
        await batch.commit();
        batch = _db.batch();
        operationCount = 0;
      }
    }

    // Guardar los restantes
    if (operationCount > 0) {
      await batch.commit();
    }
  }

  Future<void> uploadEvidence({
    required String materia,
    required String mes,
    required String fileName,
    File? fileMobile,
    Uint8List? fileWeb,
  }) async {
    try {
      final userModel = await getCurrentUserData();
      if (userModel == null) throw Exception("No se pudo identificar al usuario.");

      String fileExt = fileName.split('.').last;
      String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      Reference ref = _storage.ref().child('evidencias/${userModel.id}/$mes/$uniqueFileName');

      if (kIsWeb) {
        if (fileWeb == null) throw Exception("El archivo es requerido para la web.");
        await ref.putData(fileWeb);
      } else {
        if (fileMobile == null) throw Exception("El archivo es requerido para móvil.");
        await ref.putFile(fileMobile);
      }
      
      String downloadUrl = await ref.getDownloadURL();

      await _db.collection('evidencias').add({
        'uid': userModel.id,
        'materia': materia,
        'mes': mes,
        'file_name': fileName,
        'file_url': downloadUrl,
        'status': 'EN_REVISION',
        'feedback': '',
        'uploaded_at': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception("Error al subir evidencia: $e");
    }
  }
  
  Future<void> reviewEvidence({
    required String evidenceId,
    required String newStatus,
    String? feedback,
  }) async {
    try {
      await _db.collection('evidencias').doc(evidenceId).update({
        'status': newStatus,
        'feedback': feedback ?? '',
      });
    } catch (e) {
      throw Exception("Error al revisar la evidencia: $e");
    }
  }

  Future<void> assignFinalGrade({
    required String studentId,
    required double finalGrade,
    required String finalStatus,
  }) async {
    try {
      await _db.collection('users').doc(studentId).update({
        'status': finalStatus,
        'final_grade': finalGrade,
      });
    } catch (e) {
      throw Exception("Error al asignar la calificación final: $e");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') throw Exception('No existe una cuenta con este correo.');
      if (e.code == 'invalid-email') throw Exception('El formato del correo no es válido.');
      throw Exception(e.message ?? 'Error al enviar correo de recuperación.');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // 1. Calificar una inscripción específica (Materia)
  Future<void> assignSubjectGrade({
    required String studentId,
    required String enrollmentId, // ID de la inscripción, NO del alumno
    required double finalGrade,
    required String status, // 'ACREDITADO' o 'NO_ACREDITADO'
  }) async {
    try {
      // A. Actualizamos SOLO esa materia
      await _db.collection('enrollments').doc(enrollmentId).update({
        'final_grade': finalGrade,
        'status': status,
        'graded_at': FieldValue.serverTimestamp(),
      });

      // B. Calculamos el estatus global del alumno
      await _recalculateStudentGlobalStatus(studentId);

    } catch (e) {
      throw Exception("Error al asignar calificación: $e");
    }
  }

  // 2. Función inteligente que decide el estatus del alumno
  Future<void> _recalculateStudentGlobalStatus(String studentId) async {
    try {
      // Obtenemos al alumno para saber cuántas debe cursar
      final userDoc = await _db.collection('users').doc(studentId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final List<dynamic> subjectsToTake = userData['subjects_to_take'] ?? [];
      final int totalRequired = subjectsToTake.length;

      // Obtenemos TODAS sus inscripciones
      final enrollmentsSnapshot = await _db.collection('enrollments')
          .where('uid', isEqualTo: studentId)
          .get();

      final docs = enrollmentsSnapshot.docs;

      // Variables de control
      int passedCount = 0;
      int failedCount = 0;
      int pendingCount = 0;

      for (var doc in docs) {
        final data = doc.data();
        final status = data['status']; // EN_CURSO, ACREDITADO, NO_ACREDITADO

        if (status == 'ACREDITADO') {
          passedCount++;
        } else if (status == 'NO_ACREDITADO') {
          failedCount++;
        } else {
          // EN_CURSO o cualquier otro
          pendingCount++;
        }
      }

      // LÓGICA DE DECISIÓN ("LA REGLA DE ORO")
      String newGlobalStatus = 'EN_CURSO';
      double? finalAverage;

      // Caso 1: Todavía le faltan materias por inscribir o terminar
      // Si inscritas < requeridas O hay pendientes de calificar -> EN CURSO
      if (docs.length < totalRequired || pendingCount > 0) {
        newGlobalStatus = 'EN_CURSO';
      }
      // Caso 2: Ya terminó todo, pero reprobó alguna -> NO ACREDITADO
      else if (failedCount > 0) {
        newGlobalStatus = 'NO_ACREDITADO';
      }
      // Caso 3: Ya terminó todo y aprobó todo -> ACREDITADO
      else if (passedCount == docs.length && docs.isNotEmpty) {
        newGlobalStatus = 'ACREDITADO';

        // Opcional: Calcular promedio global si quieres guardarlo
        double sumGrades = 0;
        for (var doc in docs) {
          sumGrades += (doc.data()['final_grade'] ?? 0.0);
        }
        finalAverage = sumGrades / docs.length;
      }

      // Guardamos el veredicto en el alumno
      await _db.collection('users').doc(studentId).update({
        'status': newGlobalStatus,
        if (finalAverage != null) 'final_grade': finalAverage, // Solo si acreditó todo
      });

    } catch (e) {
      debugPrint("Error recalculando estatus global: $e");
    }
  }

  Future<void> createProfessorUser({
    required String email,
    required String password,
    required String name,
    required String academy,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Inicializamos una instancia secundaria de la app para no cerrar sesión al Admin
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 2. Creamos el usuario en Auth
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Guardamos los datos en Firestore (usando la instancia principal _db)
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email_inst': email,
        'role': 'profesor', // <--- ROL IMPORTANTE
        'status': 'ACTIVO',
        'academies': [academy], // Asignamos la academia del jefe
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. Cerramos la sesión de la app secundaria para limpiar
      await secondaryAuth.signOut();

    } catch (e) {
      throw Exception("Error creando profesor: $e");
    } finally {
      // Eliminamos la app secundaria para liberar memoria
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  /// Obtener lista de profesores de una academia específica
  Future<List<UserModel>> getProfessorsByAcademy(String academy) async {
    final snapshot = await _db.collection('users')
        .where('role', isEqualTo: 'profesor')
        .where('academies', arrayContains: academy)
        .get();

    return snapshot.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }
}
