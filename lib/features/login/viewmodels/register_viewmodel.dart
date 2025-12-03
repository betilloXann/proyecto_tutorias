import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  RegisterViewModel({required AuthRepository authRepo}) : _authRepo = authRepo;

  // --- STATE ---
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 0: Search
  final boletaController = TextEditingController();
  UserModel? _foundStudent;

  // Step 1: Form
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final personalEmailController = TextEditingController();
  String? _dictamenFileName;
  // FIX: Renamed to camelCase
  File? _dictamenFileMobile;
  Uint8List? _dictamenFileWeb;

  // --- GETTERS ---
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get foundStudent => _foundStudent;
  String? get dictamenFileName => _dictamenFileName;

  // --- METHODS ---

  // STEP 0: Search for student by boleta
  Future<void> searchStudent() async {
    if (boletaController.text.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final student = await _authRepo.checkStudentStatus(boletaController.text.trim());
      if (student == null) {
        _errorMessage = "No se encontró ningún alumno con esa boleta.";
      } else if (student.status != 'PRE_REGISTRO') {
        _errorMessage = "Este alumno ya tiene una cuenta activa o está en proceso.";
      } else {
        _foundStudent = student;
        _currentStep = 1; // Move to the next step
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // STEP 1: Pick the dictamen file (Web & Mobile compatible)
  Future<void> pickDictamenFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      _dictamenFileName = result.files.single.name;
      if (kIsWeb) {
        _dictamenFileWeb = result.files.single.bytes;
        _dictamenFileMobile = null;
      } else {
        _dictamenFileMobile = File(result.files.single.path!);
        _dictamenFileWeb = null;
      }
      notifyListeners();
    }
  }

  // STEP 1: Activate the account (Web & Mobile compatible)
  Future<bool> activateAccount() async {
    // Validation
    if (emailController.text.isEmpty || passwordController.text.isEmpty || phoneController.text.isEmpty || personalEmailController.text.isEmpty || (_dictamenFileMobile == null && _dictamenFileWeb == null)) {
      _errorMessage = "Todos los campos, incluyendo el dictamen, son obligatorios.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.activateAccount(
        docId: _foundStudent!.id,
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        personalEmail: personalEmailController.text.trim(),
        dictamenFileName: _dictamenFileName!,
        dictamenFileMobile: _dictamenFileMobile,
        dictamenFileWeb: _dictamenFileWeb,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void backToSearch() {
    _currentStep = 0;
    _foundStudent = null;
    _errorMessage = null;
    boletaController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    boletaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    personalEmailController.dispose();
    super.dispose();
  }
}
