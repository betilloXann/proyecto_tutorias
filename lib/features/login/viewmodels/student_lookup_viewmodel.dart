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
  bool _isBoletaVerified = false;


  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get foundUser => _foundUser;
  bool get isBoletaVerified => _isBoletaVerified;

  final RegExp _curpRegex = RegExp(
    r'^[A-Z][AEIOUX][A-Z]{2}\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])[HM](?:AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z]\d$',
  );

  bool isCurpValid(String curp) {
    return _curpRegex.hasMatch(curp.toUpperCase());
  }

  // PASO 1: Buscar Boleta
  Future<bool> searchStudent(String boleta) async {
    if (boleta.isEmpty) {
      _errorMessage = "Escribe una boleta";
      notifyListeners(); // Avisa a la vista que actualice
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _foundUser = null; // Reseteamos búsqueda anterior
    _isBoletaVerified = false;
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
        _isBoletaVerified = true;
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

  Future<bool> validateCurp(String curp) async {
    _errorMessage = null;

    // 1. Validar Regex
    if (curp.isEmpty || !_curpRegex.hasMatch(curp.toUpperCase())) {
      _errorMessage = "El formato del CURP es inválido.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 2. Validar duplicado en BD
      final bool exists = await _authRepo.checkCurpExists(curp.toUpperCase());
      _isLoading = false;

      if (exists) {
        _errorMessage = "Este CURP ya está registrado en otra cuenta.";
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Error al validar CURP: $e";
      notifyListeners();
      return false;
    }
  }

  // Método para "resetear" si el usuario se equivocó de boleta
  void resetSearch() {
    _foundUser = null;
    _isBoletaVerified = false;
    _errorMessage = null;
    notifyListeners();
  }
}