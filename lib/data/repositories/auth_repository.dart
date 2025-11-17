// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  // Constructor: Permite inyectar FirebaseAuth o usar la instancia por defecto.
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // ---
  // 1. Stream de Estado de Autenticación
  // ---
  // Este es el Stream que tu 'AuthGate' escuchará.
  // Emite un objeto 'User' si alguien inicia sesión, o 'null' si cierra sesión.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ---
  // 2. Iniciar Sesión (Email y Password)
  // ---
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Intenta iniciar sesión con Firebase
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(), // Usamos .trim() para quitar espacios
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Manejamos errores específicos de Firebase
      if (e.code == 'user-not-found') {
        throw Exception('No se encontró un usuario con ese correo.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta.');
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del correo no es válido.');
      } else {
        // Error genérico de Firebase
        throw Exception('Error: ${e.message}');
      }
    } catch (e) {
      // Otro error (ej. sin conexión a internet)
      throw Exception('Ocurrió un error inesperado.');
    }
  }

  // ---
  // 3. Registrarse (Crear Cuenta)
  // ---
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Intenta crear el usuario
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Nota: Después de esto, Firebase Auth inicia sesión automáticamente.
      // El Stream 'authStateChanges' se disparará con el nuevo usuario.

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('La contraseña es muy débil.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('El correo electrónico ya está en uso.');
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del correo no es válido.');
      } else {
        throw Exception('Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Ocurrió un error inesperado.');
    }
  }

  // ---
  // 4. Cerrar Sesión
  // ---
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // El Stream 'authStateChanges' se disparará automáticamente con 'null'.
    } catch (e) {
      throw Exception('Error al cerrar sesión.');
    }
  }

  // ---
  // 5. Obtener Usuario Actual (Opcional)
  // ---
  // Útil si necesitas síncronamente saber si alguien está logueado.
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}