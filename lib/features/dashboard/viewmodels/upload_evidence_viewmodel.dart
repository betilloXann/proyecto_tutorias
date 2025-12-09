import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/auth_repository.dart';

class UploadEvidenceViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UploadEvidenceViewModel({required AuthRepository authRepo}) : _authRepo = authRepo {
    _loadStudentClasses();
  }

  // --- STATE ---
  bool _isLoading = false;
  bool _isLoadingClasses = true;

  Map<String, dynamic>? _selectedClassData;
  String? _selectedMonth;
  String? _fileName;
  String? _errorMessage;

  // --- Platform-specific file data ---
  File? _selectedFileMobile;
  Uint8List? _selectedFileWeb;

  List<Map<String, dynamic>> _availableClasses = [];
  final List<String> months = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
  ];

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  bool get isLoadingClasses => _isLoadingClasses;
  Map<String, dynamic>? get selectedClassData => _selectedClassData;
  String? get selectedMonth => _selectedMonth;
  String? get fileName => _fileName;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get availableClasses => _availableClasses;

  // --- METHODS ---

  Future<void> _loadStudentClasses() async {
    _isLoadingClasses = true;
    notifyListeners();
    try {
      final userModel = await _authRepo.getCurrentUserData();
      if (userModel == null) {
        _errorMessage = "No se pudo identificar al alumno";
        return;
      }
      final snapshot = await _db
          .collection('enrollments')
          .where('uid', isEqualTo: userModel.id)
          .where('status', isEqualTo: 'EN_CURSO')
          .get();

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
      _fileName = result.files.single.name;
      if (kIsWeb) {
        _selectedFileWeb = result.files.single.bytes;
        _selectedFileMobile = null;
      } else {
        _selectedFileMobile = File(result.files.single.path!);
        _selectedFileWeb = null;
      }
      notifyListeners();
    }
  }

  Future<bool> uploadEvidence() async {
    _errorMessage = null;

    if (_selectedClassData == null || _selectedMonth == null || (_selectedFileMobile == null && _selectedFileWeb == null)) {
      _errorMessage = "Por favor selecciona materia, mes y adjunta un archivo.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepo.getCurrentUserData();
      if (user == null) throw Exception("Usuario no identificado");

      // 1. VALIDACIÓN: Verificar si ya existe evidencia
      final existingQuery = await _db.collection('evidence')
          .where('uid', isEqualTo: user.id)
          .where('materia', isEqualTo: _selectedClassData!['subject'])
          .where('mes', isEqualTo: _selectedMonth)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final existingDoc = existingQuery.docs.first;
        final status = existingDoc['status'];

        if (status == 'EN_REVISION' || status == 'APROBADA') {
          throw Exception("Ya existe una evidencia para $_selectedMonth en estatus: $status.");
        }
        //Borrar la anterior para que  sea un "reemplazo" limpio:
        await _db.collection('evidence').doc(existingDoc.id).delete();
        // O simplemente el AuthRepo.uploadEvidence creará una nueva y en el historial saldrá la nueva arriba.
      }

      // 2. SUBIDA
      await _authRepo.uploadEvidence(
        materia: _selectedClassData!['subject'],
        mes: _selectedMonth!,
        fileName: _fileName!,
        fileMobile: _selectedFileMobile,
        fileWeb: _selectedFileWeb,
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

  void clear() {
    _selectedClassData = null;
    _selectedMonth = null;
    _fileName = null;
    _errorMessage = null;
    _isLoading = false;
    _selectedFileMobile = null;
    _selectedFileWeb = null;
  }
}
