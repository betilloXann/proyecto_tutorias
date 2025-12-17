import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crea un usuario individual (Jefe o Admin) sin desloguear al actual
  Future<void> createUser({
    required String email,
    required String name,
    required String role,
    required List<String> academies,
    required String password,
    String? boleta,
  }) async {
    // Usamos una app secundaria para no desloguear al Admin actual
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
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
      deletedFirestore++;
    }

    await tempApp.delete();
    return {'db': deletedFirestore, 'auth': deletedAuth};
  }
}