import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

// Este es tu VIEWMODEL
class StudentLookupViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  StudentLookupViewModel(this._authRepo);

  bool _isLoading = false;
  String? _errorMessage;

  // Getters para que la vista consuma los datos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> searchStudent(String boleta) async {
    if (boleta.isEmpty) {
      _errorMessage = "Escribe una boleta";
      notifyListeners(); // Avisa a la vista que actualice
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
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
        // Todo salió bien
        notifyListeners();
        return true; // Retornamos true para que la vista sepa que debe navegar
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Error de conexión: $e";
      notifyListeners();
      return false;
    }
  }
}