import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import '../../../data/repositories/auth_repository.dart';

class BulkUploadViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  BulkUploadViewModel({required AuthRepository authRepo}) : _authRepo = authRepo;

  bool _isLoading = false;
  String? _fileName;
  String? _errorMessage;
  String _progressMessage = '';
  int _processedStudents = 0;
  bool _isSuccess = false;
  FilePickerResult? _pickedFile;

  final Map<String, String> _subjectMapping = {
    'LABORATORIO DE ELECTRICIDAD Y CONTROL': 'LAB ELECT Y CONTROL',
  };

  bool get isLoading => _isLoading;
  String? get fileName => _fileName;
  String? get errorMessage => _errorMessage;
  String get progressMessage => _progressMessage;
  int get processedStudents => _processedStudents;
  bool get isSuccess => _isSuccess;

  void reset() {
    _isLoading = false;
    _fileName = null;
    _errorMessage = null;
    _progressMessage = '';
    _processedStudents = 0;
    _isSuccess = false;
    _pickedFile = null;
    notifyListeners();
  }

  Future<void> pickFile() async {
    reset();
    try {
      _pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (_pickedFile != null) {
        _fileName = _pickedFile!.files.single.name;
      }
    } catch (e) {
      _errorMessage = "Error seleccionando el archivo: $e";
    } finally {
      notifyListeners();
    }
  }

  Future<void> processAndUpload() async {
    if (_pickedFile == null) {
      _errorMessage = "Por favor, selecciona un archivo de Excel primero.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _isSuccess = false;
    _errorMessage = null;
    _progressMessage = 'Iniciando proceso...';
    _processedStudents = 0;
    notifyListeners();

    try {
      final bytes = _pickedFile!.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first]!;

      _progressMessage = 'Leyendo y normalizando datos...';
      notifyListeners();

      final Map<String, Map<String, dynamic>> studentsData = {};
      int totalRowsProcessed = 0;

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        final rawBoleta = row[0]?.value?.toString() ?? '';
        final cleanBoleta = rawBoleta.trim();
        if (cleanBoleta.isEmpty) continue;

        totalRowsProcessed++;

        // --- FIX: Take the name directly from Excel, just trim whitespace ---
        final rawName = row[1]?.value?.toString() ?? '';
        final cleanName = rawName.trim();

        final rawAcademy = row[3]?.value?.toString() ?? '';
        String tempAcademy = rawAcademy.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

        String cleanAcademy = tempAcademy;
        if (_subjectMapping.containsKey(tempAcademy)) {
          cleanAcademy = _subjectMapping[tempAcademy]!;
        }

        final rawSubject = row[4]?.value?.toString() ?? '';
        String tempSubject = rawSubject.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

        String finalSubject = tempSubject;
        if (_subjectMapping.containsKey(tempSubject)) {
          finalSubject = _subjectMapping[tempSubject]!;
        }

        final rawEmail = row[6]?.value?.toString() ?? '';
        final cleanEmail = rawEmail.trim();

        studentsData.putIfAbsent(cleanBoleta, () => {
          'boleta': cleanBoleta,
          'name': cleanName,
          'status': 'PRE_REGISTRO',
          'academies': <String>{},
          'subjects_to_take': <String>{},
          'email_inst': cleanEmail,
        });

        if (cleanAcademy.isNotEmpty) {
          studentsData[cleanBoleta]!['academies'].add(cleanAcademy);
        }
        if (finalSubject.isNotEmpty) {
          studentsData[cleanBoleta]!['subjects_to_take'].add(finalSubject);
        }
      }

      _progressMessage = 'Procesando $totalRowsProcessed registros...';
      notifyListeners();

      final List<Map<String, dynamic>> uploadList = studentsData.values.map((data) {
        return {
          ...data,
          'academies': (data['academies'] as Set<String>).toList(),
          'subjects_to_take': (data['subjects_to_take'] as Set<String>).toList(),
        };
      }).toList();

      await _authRepo.bulkRegisterStudents(uploadList, (processed) {
        _processedStudents = processed;
        _progressMessage = 'Guardando alumno $processed de ${uploadList.length}...';
        notifyListeners();
      });

      _progressMessage = '¡Éxito!\n• Se procesaron $totalRowsProcessed filas.\n• Se actualizaron ${uploadList.length} alumnos.';
      _isSuccess = true;

    } catch (e) {
      _errorMessage = "Error: $e";
      debugPrint("Error BulkUpload: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
