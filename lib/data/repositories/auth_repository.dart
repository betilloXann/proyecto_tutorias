// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  // Stream para escuchar si el usuario entró o salió (Para el AuthGate)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Método para Iniciar Sesión
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de Firebase
      if (e.code == 'user-not-found') {
        throw Exception('No se encontró usuario con ese correo.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta.');
      }
      throw Exception(e.message ?? 'Error de autenticación.');
    } catch (e) {
      throw Exception('Ocurrió un error desconocido: $e');
    }
  }

  // Método para Cerrar Sesión
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}