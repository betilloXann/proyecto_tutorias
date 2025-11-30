import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

// Este es tu VIEWMODEL
class StudentLookupViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  StudentLookupViewModel(this._authRepo);

  bool _isLoading = false;
  String? _errorMessage;

  // 1. VARIABLE PARA GUARDAR EL USUARIO ENCONTRADO
  UserModel? _foundUser;

  // Getters para que la vista consuma los datos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 2. GETTER PÚBLICO
  UserModel? get foundUser => _foundUser;

  Future<bool> searchStudent(String boleta) async {
    if (boleta.isEmpty) {
      _errorMessage = "Escribe una boleta";
      notifyListeners(); // Avisa a la vista que actualice
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _foundUser = null; // Reseteamos búsqueda anterior
    notifyListeners();

    try {
      final user = await _authRepo.checkStudentStatus(boleta);
      _isLoading = false;

      if (user == null) {
        _errorMessage = "Boleta no encontrada en el pre-registro.";
        notifyListeners();
        return false;
      } else if (user.status != 'PRE_REGISTRO') {
        _errorMessage = "Esta cuenta ya fue activada.";
        notifyListeners();
        return false;
      } else {
        // 3. ¡ÉXITO! GUARDAMOS EL USUARIO
        _foundUser = user;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Error de conexión: $e";
      notifyListeners();
      return false;
    }
  }
}