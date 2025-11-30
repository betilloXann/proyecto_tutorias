import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class HomeMenuViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  HomeMenuViewModel(this._authRepo) {
    // En cuanto se crea el ViewModel, cargamos los datos
    _loadUserData();
  }

  // ESTADO
  bool _isLoading = true;
  UserModel? _currentUser;
  String? _errorMessage;

  // GETTERS
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  /// Carga los datos del usuario desde Firebase
  Future<void> _loadUserData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepo.getCurrentUserData();
    } catch (e) {
      _errorMessage = "Error cargando perfil: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cierra la sesión
  Future<void> logout() async {
    await _authRepo.signOut();
    // No necesitamos notifyListeners aquí porque la vista navegará fuera
  }
}