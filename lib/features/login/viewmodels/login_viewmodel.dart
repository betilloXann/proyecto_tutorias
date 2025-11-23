// lib/features/login/viewmodels/login_viewmodel.dart
import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Método que llamará tu botón de Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Avisa a la vista que muestre el spinner

    try {
      await _authRepository.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true; // Éxito
    } catch (e) {
      _isLoading = false;
      // Limpiamos el mensaje de error feo de Dart
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false; // Falló
    }
  }
}