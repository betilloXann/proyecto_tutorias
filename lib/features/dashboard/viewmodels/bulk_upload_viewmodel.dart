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

  // --- NUEVO: DICCIONARIO DE TRADUCCIÓN ---
  // Izquierda: Como viene en el Excel (Normalizado a mayúsculas)
  // Derecha: Como DEBE guardarse en la BD
  final Map<String, String> _subjectMapping = {
    'LABORATORIO DE ELECTRICIDAD Y CONTROL': 'LAB. ELECT. Y CONTROL',

    'ARQUITECTURA Y ORGANIZACIÓN DE LAS COMPUTADORAS': 'ARQ. Y ORG. COMP.',
    'ARQUITECTURA Y ORGANIZACION DE LAS COMPUTADORAS': 'ARQ. Y ORG. COMP.', // Por si viene sin acento
    'APLICACIÓN DE SISTEMAS DIGITALES': 'APLIC. SIST. DIGITALES',
    'APLICACION DE SISTEMAS DIGITALES': 'APLIC. SIST. DIGITALES',
    'COMUNICACIÓN DE DATOS': 'COM. DATOS',
    'COMUNICACION DE DATOS': 'COM. DATOS',
    'CONSTRUCCION DE BASES DE DATOS': 'CONST. BASE DATOS',
    'FUNDAMENTOS DE ANALITICA DE DATOS': 'FUND. ANALITICA DATOS',
    'INGENIERIA DE DISEÑO': 'ING. DISEÑO',
    'ALGORITMOS COMPUTACIONALES': 'ALGORITMOS COMP.',
    // ... Agrega aquí todas las variaciones que detectes ...
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

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // 1. LIMPIEZA BÁSICA
        final rawBoleta = row[0]?.value?.toString() ?? '';
        final cleanBoleta = rawBoleta.trim();
        if (cleanBoleta.isEmpty) continue;

        final rawName = row[1]?.value?.toString() ?? '';
        final cleanName = rawName.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

        final rawAcademy = row[3]?.value?.toString() ?? '';
        final cleanAcademy = rawAcademy.trim().toUpperCase();

        // 2. NORMALIZACIÓN DE MATERIA (Aquí ocurre la magia)
        final rawSubject = row[4]?.value?.toString() ?? '';
        // Primero convertimos a mayúscula limpia
        String tempSubject = rawSubject.trim().toUpperCase();

        // Luego buscamos si existe una traducción oficial en el mapa
        String finalSubject = tempSubject;
        if (_subjectMapping.containsKey(tempSubject)) {
          finalSubject = _subjectMapping[tempSubject]!;
        }

        final rawEmail = row[6]?.value?.toString() ?? '';
        final cleanEmail = rawEmail.trim();

        // 3. AGRUPACIÓN
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
        // Usamos finalSubject (ya traducido)
        if (finalSubject.isNotEmpty) {
          studentsData[cleanBoleta]!['subjects_to_take'].add(finalSubject);
        }
      }

      _progressMessage = 'Subiendo ${studentsData.length} alumnos procesados...';
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
        _progressMessage = 'Guardando... $processed / ${uploadList.length}';
        notifyListeners();
      });

      _progressMessage = '¡Éxito! Se procesaron ${uploadList.length} alumnos.';
      _isSuccess = true;

    } catch (e) {
      _errorMessage = "Error: $e";
      print("Error BulkUpload: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}