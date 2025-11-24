import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener usuario actual (si ya está logueado)
  User? get currentUser => _auth.currentUser;

  // Stream para detectar cambios de auth (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión con Email y Password
  Future<User?> signIn({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Aquí puedes manejar códigos de error específicos de Firebase
      if (e.code == 'user-not-found') {
        throw Exception('No existe usuario con ese correo.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta.');
      }
      throw Exception(e.message ?? 'Ocurrió un error al iniciar sesión.');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}