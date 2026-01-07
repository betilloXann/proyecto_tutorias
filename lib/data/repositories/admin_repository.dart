import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crea un usuario individual (Jefe o Admin) sin desloguear al actual
  Future<String?> createUser({
    required String email,
    required String name,
    required String role,
    required List<String> academies,
    required String password,
    String? boleta,
  }) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    String? newUserId;

    try {
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        newUserId = cred.user!.uid;

        await _firestore.collection('users').doc(newUserId).set({
          'uid': newUserId,
          'name': name,
          'email_inst': email,
          'email_personal': 'personal.${email.split('@')[0]}@gmail.com',
          'role': role,
          'status': 'ACTIVO',
          'academies': academies,
          'boleta': boleta ?? '',
          'subjects_to_take': [],
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } finally {
      await tempApp.delete();
    }

    return newUserId; // Lo retornamos para usarlo en el ViewModel
  }

  Stream<List<Map<String, dynamic>>> getStaffStream() {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['jefe_academia', 'tutorias'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  //Función para insertar materias rápidamente
  Future<void> createStudentEnrollment(Map<String, dynamic> enrollmentData) async {
    await _firestore.collection('enrollments').add(enrollmentData);
  }

  // Borrado masivo de alumnos
  Future<Map<String, int>> deleteStudents() async {
    int deletedFirestore = 0;
    int deletedAuth = 0;

    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'DeleteApp', options: Firebase.app().options);
    FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

    final snapshot = await _firestore.collection('users')
        .where('role', isEqualTo: 'student').get();

    for (var doc in snapshot.docs) {
      final email = doc.data()['email_inst'] as String?;
      if (email != null) {
        try {
          await tempAuth.signInWithEmailAndPassword(email: email, password: 'alumno123');
          await tempAuth.currentUser?.delete();
          deletedAuth++;
        } catch (_) {}
      }
      await doc.reference.delete();

      //Borrar enrollments asociados también para limpiar basura
      final enrollments = await _firestore.collection('enrollments').where('uid', isEqualTo: doc.id).get();
      for (var e in enrollments.docs) {
        e.reference.delete();
      }
        deletedFirestore++;
    }

    await tempApp.delete();
    return {'db': deletedFirestore, 'auth': deletedAuth};
  }

  Future<void> closeSemesterCycle(String oldPeriod, String newPeriod) async {
    // 1. NO borramos los datos (enrollments/evidences).

    // 2. Opción A (Más simple):
    // Actualizamos una configuración global que dice cuál es el periodo "Activo".
    // Esto hace que la app, al iniciar, sepa que ahora debe buscar datos de '26-2'.

    await _firestore.collection('config').doc('system_settings').update({
      'currentPeriod': newPeriod,
      'previousPeriod': oldPeriod,
      'archivedAt': DateTime.now(),
    });

    // 3. Opción B (Si necesitas marcar registros):
    // Marcar a los alumnos como "inactivos" temporalmente hasta que se reinscriban
    // pero NO borrarlos de la colección de usuarios.

    /* final students = await _firestore.collection('users')
      .where('role', isEqualTo: 'student').get();

  final batch = _firestore.batch();
  for (var doc in students.docs) {
    batch.update(doc.reference, {'status': 'archived_pending_enrollment'});
  }
  await batch.commit();
  */
  }
}