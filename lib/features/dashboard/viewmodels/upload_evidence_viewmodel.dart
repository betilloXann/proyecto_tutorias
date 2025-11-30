import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/auth_repository.dart';

class UploadEvidenceViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  //final FirebaseAuth _auth = FirebaseAuth.instance;

  UploadEvidenceViewModel({required AuthRepository authRepo}) : _authRepo = authRepo {
    // Al iniciar, cargamos las materias reales del alumno
    _loadStudentClasses();
  }

  // --- ESTADO ---
  bool _isLoading = false;
  bool _isLoadingClasses = true; // Nuevo estado para cargar materias

  // Guardamos el objeto completo de la clase (Materia + Profe)
  Map<String, dynamic>? _selectedClassData;

  String? _selectedMonth;
  File? _selectedFile;
  String? _fileName;
  String? _errorMessage;

  // Lista de materias traída de Firebase
  List<Map<String, dynamic>> _availableClasses = [];

  // Lista estática de meses
  final List<String> months = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingClasses => _isLoadingClasses;
  Map<String, dynamic>? get selectedClassData => _selectedClassData;
  String? get selectedMonth => _selectedMonth;
  File? get selectedFile => _selectedFile;
  String? get fileName => _fileName;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get availableClasses => _availableClasses;

  // --- MÉTODOS ---

// 1. Cargar Materias Reales (Corregido)
  Future<void> _loadStudentClasses() async {
    _isLoadingClasses = true;
    notifyListeners();

    try {
      // PASO CLAVE: Primero obtenemos el usuario completo para sacar su ID de documento
      // (No usamos _auth.currentUser.uid directamente porque difiere de tu BD)
      final userModel = await _authRepo.getCurrentUserData();

      if (userModel == null) {
        _errorMessage = "No se pudo identificar al alumno";
        return;
      }

      // Ahora buscamos usando userModel.id (El ID del documento, ej: 8Pd2VM4...)
      final snapshot = await _db
          .collection('enrollments')
          .where('uid', isEqualTo: userModel.id)
          .where('status', isEqualTo: 'EN_CURSO')
          .get();

      if (snapshot.docs.isEmpty) {
        // Opcional: Manejar caso vacío
        //print("No se encontraron materias para el ID: ${userModel.id}");
      }

      _availableClasses = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'subject': data['subject'] ?? 'Materia',
          'professor': data['professor'] ?? 'Profesor',
          'display': "${data['subject']} \n(Prof. ${data['professor']})"
        };
      }).toList();

    } catch (e) {
      _errorMessage = "No se pudieron cargar las materias: $e";
    } finally {
      _isLoadingClasses = false;
      notifyListeners();
    }
  }

  void setClass(Map<String, dynamic>? val) {
    _selectedClassData = val;
    notifyListeners();
  }

  void setMonth(String? val) {
    _selectedMonth = val;
    notifyListeners();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      _selectedFile = File(result.files.single.path!);
      _fileName = result.files.single.name;
      notifyListeners();
    }
  }

  Future<bool> uploadEvidence() async {
    _errorMessage = null;

    if (_selectedClassData == null || _selectedMonth == null || _selectedFile == null) {
      _errorMessage = "Por favor selecciona materia, mes y adjunta un archivo.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Usamos el repositorio, pasando la materia seleccionada
      await _authRepo.uploadEvidence(
        materia: _selectedClassData!['subject'], // Mandamos solo el nombre de la materia
        mes: _selectedMonth!,
        file: _selectedFile!,
      );

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _selectedClassData = null;
    _selectedMonth = null;
    _selectedFile = null;
    _fileName = null;
    _errorMessage = null;
    _isLoading = false;
  }
}