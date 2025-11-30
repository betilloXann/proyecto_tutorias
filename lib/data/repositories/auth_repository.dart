import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import 'dart:developer';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  AuthRepository({required FirebaseAuth firebaseAuth})
      : _auth = firebaseAuth,
        _db = FirebaseFirestore.instance,
        _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------
  // 1. LOGIN Y LOGOUT
  // ---------------------------------------------------

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
  // 2. ACTIVACIÓN (TU FLUJO DE ONBOARDING)
  // ---------------------------------------------------

  Future<UserModel?> checkStudentStatus(String boleta) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('boleta', isEqualTo: boleta)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return UserModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw Exception("Error al buscar estudiante: $e");
    }
  }

  Future<void> activateAccount({
    required String docId,
    required String email,
    required String password,
    required String phone,
    required String personalEmail,
    required File dictamenFile,
  }) async {
    try {
      // A) Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = cred.user!.uid;

      // B) Storage
      String fileExt = dictamenFile.path.split('.').last;
      Reference ref = _storage.ref().child('dictamenes/$uid.$fileExt');
      await ref.putFile(dictamenFile);
      String downloadUrl = await ref.getDownloadURL();

      // C) Firestore
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
      throw Exception("Error al activar: $e");
    }
  }

  // ---------------------------------------------------
  // 3. OBTENER DATOS (ESTA ES LA QUE FALTABA)
  // ---------------------------------------------------
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Buscamos al usuario por su UID de Auth
      final snapshot = await _db
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      log("Error obteniendo datos", error: e);
      return null;
    }
  }

  // ---------------------------------------------------
  // 4. SUBIR EVIDENCIA MENSUAL
  // ---------------------------------------------------
  Future<void> uploadEvidence({
    required String materia,
    required String mes,
    required File file,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No hay usuario logueado");

      // 1. Subir Archivo a Storage
      // Ruta: evidencias/UID_DEL_ALUMNO/NOMBRE_MATERIA/mes_nombre.pdf
      // Usamos Timestamp para que no se sobrescriban si sube 2 veces
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileExt = file.path.split('.').last;

      Reference ref = _storage.ref().child('evidencias/${user.uid}/$timestamp.$fileExt');
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      // 2. Guardar Registro en Firestore (Colección 'evidencias')
      await _db.collection('evidencias').add({
        'uid': user.uid,
        'materia': materia,
        'mes': mes,
        'file_url': downloadUrl,
        'status': 'EN_REVISION', // Inicialmente está en revisión
        'feedback': '',          // Retroalimentación vacía
        'created_at': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception("Error al subir evidencia: $e");
    }
  }
}