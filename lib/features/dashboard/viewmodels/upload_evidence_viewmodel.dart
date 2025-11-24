import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

class UploadEvidenceViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  UploadEvidenceViewModel({required AuthRepository authRepo}) : _authRepo = authRepo;

  // --- ESTADO (Variables) ---
  bool _isLoading = false;
  String? _selectedSubject;
  String? _selectedMonth;
  File? _selectedFile;
  String? _fileName;
  String? _errorMessage;

  // Listas (Simuladas por ahora)
  final List<String> subjects = [
    "Programación Orientada a Objetos - Prof. Alan Turing",
    "Circuitos Lógicos - Prof. Nikola Tesla",
  ];

  final List<String> months = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
  ];

  // Getters
  bool get isLoading => _isLoading;
  String? get selectedSubject => _selectedSubject;
  String? get selectedMonth => _selectedMonth;
  File? get selectedFile => _selectedFile;
  String? get fileName => _fileName;
  String? get errorMessage => _errorMessage;

  // --- MÉTODOS (Acciones) ---

  void setSubject(String? val) {
    _selectedSubject = val;
    notifyListeners();
  }

  void setMonth(String? val) {
    _selectedMonth = val;
    notifyListeners();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      _selectedFile = File(result.files.single.path!);
      _fileName = result.files.single.name;
      notifyListeners(); // Avisamos a la vista que ya hay archivo
    }
  }

  // Retorna TRUE si subió bien, FALSE si falló
  Future<bool> uploadEvidence() async {
    _errorMessage = null;

    if (_selectedSubject == null || _selectedMonth == null || _selectedFile == null) {
      _errorMessage = "Selecciona materia, mes y archivo";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners(); // Activar spinner

    try {
      await _authRepo.uploadEvidence(
        materia: _selectedSubject!,
        mes: _selectedMonth!,
        file: _selectedFile!,
      );

      _isLoading = false;
      notifyListeners();
      return true; // Éxito

    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false; // Error
    }
  }

  // Limpiar formulario al salir
  void clear() {
    _selectedSubject = null;
    _selectedMonth = null;
    _selectedFile = null;
    _fileName = null;
    _errorMessage = null;
    _isLoading = false;
    // No llamamos notifyListeners aquí porque usualmente se usa al desmontar
  }
}