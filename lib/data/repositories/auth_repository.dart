import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
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

  // --- LOGIN & LOGOUT ---
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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

  // --- ACCOUNT ACTIVATION ---
  Future<UserModel?> checkStudentStatus(String boleta) async {
    try {
      final snapshot = await _db.collection('users').where('boleta', isEqualTo: boleta).limit(1).get();
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
    required String dictamenFileName,
    // FIX: Renamed to camelCase
    File? dictamenFileMobile,
    Uint8List? dictamenFileWeb,
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
        'status': 'PENDIENTE_ASIGNACION',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Error al activar: $e");
    }
  }

  // --- GET USER DATA ---
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

  // --- UPLOAD EVIDENCE (Web-Compatible) ---
  Future<void> uploadEvidence({
    required String materia,
    required String mes,
    required String fileName,
    // FIX: Renamed to camelCase
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
        'status': 'EN_REVISION', // Default status
        'feedback': '', // Default empty feedback
        'uploaded_at': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception("Error al subir evidencia: $e");
    }
  }
  
  // --- NEW: REVIEW EVIDENCE ---
  Future<void> reviewEvidence({
    required String evidenceId,
    required String newStatus, // e.g., 'APROBADA' or 'RECHAZADA'
    String? feedback,
  }) async {
    try {
      final dataToUpdate = {
        'status': newStatus,
        'feedback': feedback ?? '',
      };

      await _db.collection('evidencias').doc(evidenceId).update(dataToUpdate);

    } catch (e) {
      throw Exception("Error al revisar la evidencia: $e");
    }
  }

  // --- PASSWORD RECOVERY ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No existe una cuenta con este correo.');
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del correo no es válido.');
      }
      throw Exception(e.message ?? 'Error al enviar correo de recuperación.');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }
}
