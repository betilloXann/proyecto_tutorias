import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  // 1. Inicializamos el AuthRepository que ya tienes creado
  final AuthRepository _authRepo = AuthRepository(firebaseAuth: FirebaseAuth.instance);

  bool _isLoading = false;
  String? _errorMessage;
  User? _user;           // Usuario básico de Firebase (Auth)
  UserModel? _currentUser; // Usuario con datos de Firestore (Tu modelo personalizado)

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  UserModel? get currentUser => _currentUser; // Getter para acceder a los datos del alumno/profesor

  // Constructor
  AuthProvider() {
    _checkAuthState();
  }

  void _checkAuthState() {
    _authRepo.authStateChanges.listen((User? user) {
      _user = user;
      if (_user != null) {
        // Si hay sesión, intentamos cargar los datos completos del usuario
        loadCurrentUser();
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  // --- AQUÍ ESTÁ LA SOLUCIÓN ---
  // Esta función ahora está DENTRO de la clase y usa el nombre correcto del método
  Future<UserModel?> loadCurrentUser() async {
    try {
      // Usamos _authRepo.getCurrentUserData() como está definido en tu repositorio
      final userModel = await _authRepo.getCurrentUserData();
      _currentUser = userModel;
      notifyListeners();
      return userModel;
    } catch (e) {
      debugPrint("Error cargando datos del usuario: $e");
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Usamos el método signIn de tu repositorio
      await _authRepo.signIn(email: email, password: password);
      
      // Opcional: Forzar la carga de datos inmediatamente tras el login
      await loadCurrentUser();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepo.signOut();
    _currentUser = null;
    notifyListeners();
  }
}