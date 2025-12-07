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
  bool _isSuccess = false; // <-- NEW: Success state
  
  FilePickerResult? _pickedFile;

  bool get isLoading => _isLoading;
  String? get fileName => _fileName;
  String? get errorMessage => _errorMessage;
  String get progressMessage => _progressMessage;
  int get processedStudents => _processedStudents;
  bool get isSuccess => _isSuccess; // <-- NEW: Getter

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
    reset(); // Reset state when picking a new file
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

      _progressMessage = 'Leyendo y agrupando alumnos del Excel...';
      notifyListeners();

      final Map<String, Map<String, dynamic>> studentsData = {};

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        
        final boleta = row[0]?.value?.toString() ?? '';
        if (boleta.isEmpty) continue;

        final nombre = row[1]?.value?.toString() ?? '';
        final academia = row[3]?.value?.toString() ?? '';
        final unidad = row[4]?.value?.toString() ?? '';
        final correo = row[6]?.value?.toString() ?? '';

        studentsData.putIfAbsent(boleta, () => {
          'boleta': boleta,
          'name': nombre,
          'academies': <String>{academia},
          'subjects_to_take': <String>{unidad},
          'email_inst': correo,
        });

        studentsData[boleta]!['academies'].add(academia);
        studentsData[boleta]!['subjects_to_take'].add(unidad);
      }

      _progressMessage = '${studentsData.length} alumnos únicos encontrados. Subiendo a la base de datos...';
      _processedStudents = 0;
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
        _progressMessage = 'Procesando... $processed de ${uploadList.length} alumnos guardados.';
        notifyListeners();
      });

      _progressMessage = '¡Proceso completado! Se guardaron ${uploadList.length} alumnos.';
      _isSuccess = true; // <-- SET SUCCESS STATE

    } catch (e) {
      _errorMessage = "Error durante el proceso: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
