import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  ForgotPasswordViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  bool _emailSent = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get emailSent => _emailSent;

  Future<bool> sendRecoveryEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _emailSent = false;
    notifyListeners();

    try {
      await _authRepository.sendPasswordResetEmail(email.trim());
      _emailSent = true;
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
}