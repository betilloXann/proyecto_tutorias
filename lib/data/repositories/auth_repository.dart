import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart'; // Asegúrate que esta ruta sea correcta

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  // CONSTRUCTOR: Aquí arreglamos el error 'firebaseAuth not defined'
  // Inicializamos Firestore y Storage aquí mismo
  AuthRepository({required FirebaseAuth firebaseAuth})
      : _auth = firebaseAuth,
        _db = FirebaseFirestore.instance,
        _storage = FirebaseStorage.instance;

  // Stream para escuchar cambios de sesión (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------
  // 1. MÉTODOS DE AUTENTICACIÓN BÁSICA (LOGIN)
  // ---------------------------------------------------

  // Aquí arreglamos el error 'signIn not defined'
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No se encontró usuario con ese correo.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta.');
      }
      throw Exception(e.message ?? 'Error de autenticación.');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------
  // 2. MÉTODOS DE ACTIVACIÓN (NUEVOS)
  // ---------------------------------------------------

  // Buscar si la boleta existe en el pre-registro
  Future<UserModel?> checkStudentStatus(String boleta) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('boleta', isEqualTo: boleta)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Convertimos el documento a nuestro Modelo
      return UserModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw Exception("Error al buscar estudiante: $e");
    }
  }

  // Activar la cuenta (Crear Auth + Subir Archivo + Actualizar BD)
  Future<void> activateAccount({
    required String docId,
    required String email,
    required String password,
    required String phone,
    required String personalEmail,
    required File dictamenFile,
  }) async {
    try {
      // A) Crear usuario en Firebase Authentication
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = cred.user!.uid;

      // B) Subir el Dictamen a Storage
      // (Ojo: requiere tener la regla de storage configurada en consola)
      String fileExt = dictamenFile.path.split('.').last;
      Reference ref = _storage.ref().child('dictamenes/$uid.$fileExt');
      UploadTask uploadTask = ref.putFile(dictamenFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // C) Actualizar el documento en Firestore
      await _db.collection('users').doc(docId).update({
        'uid': uid,
        'email_inst': email,
        'email_personal': personalEmail,
        'phone': phone,
        'dictamen_url': downloadUrl,
        'status': 'PENDIENTE_ASIGNACION',
        'updated_at': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception("Error al activar cuenta: $e");
    }
  }
}