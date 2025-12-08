import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/subject_model.dart';

class AcademyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> myAcademies;

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _pendingStudents = [];
  List<UserModel> _assignedStudents = [];
  List<UserModel> _accreditedStudents = [];
  List<UserModel> _notAccreditedStudents = [];
  List<SubjectModel> _subjects = [];
  List<SubjectModel> _availableSubjectsForStudent = [];

  final Map<String, String> _subjectAbbreviationMap = {
    'LABORATORIO DE ELECTRICIDAD Y CONTROL': 'LAB. ELECT. Y CONTROL',
    'ARQUITECTURA Y ORGANIZACIÓN DE LAS COMPUTADORAS': 'ARQ. Y ORG. COMP.',
    'APLICACIÓN DE SISTEMAS DIGITALES': 'APLIC. SIST. DIGITALES',
  };

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get assignedStudents => _assignedStudents;
  List<UserModel> get accreditedStudents => _accreditedStudents;
  List<UserModel> get notAccreditedStudents => _notAccreditedStudents;
  List<SubjectModel> get subjects => _subjects;
  List<SubjectModel> get availableSubjectsForStudent => _availableSubjectsForStudent;

  AcademyViewModel({required this.myAcademies}) {
    loadInitialData();
  }

  void filterSubjectsForStudent(UserModel student) {
    if (student.subjectsToTake.isEmpty) {
      _availableSubjectsForStudent = List.from(_subjects);
    } else {
      final studentSubjectsNormalized = student.subjectsToTake.map((s) => s.trim().toLowerCase()).toSet();

      _availableSubjectsForStudent = _subjects.where((subject) {
        final subjectNameNormalized = subject.name.trim().toLowerCase();
        if (studentSubjectsNormalized.contains(subjectNameNormalized)) return true;
        final upperCaseSubjectName = subject.name.toUpperCase();
        final abbreviation = _subjectAbbreviationMap[upperCaseSubjectName];
        if (abbreviation != null && studentSubjectsNormalized.contains(abbreviation.toLowerCase())) return true;
        return false;
      }).toList();
    }
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    if (myAcademies.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([_loadStudents(), _loadSubjects()]);
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStudents() async {
    if (myAcademies.isEmpty) return;

    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('academies', arrayContainsAny: myAcademies)
        .get();

    _pendingStudents = [];
    _assignedStudents = [];
    _accreditedStudents = [];
    _notAccreditedStudents = [];

    for (var doc in snapshot.docs) {
      final student = UserModel.fromMap(doc.data(), doc.id);

      // --- LÓGICA DE FILTRADO VISUAL POR ACADEMIA ---
      // Un alumno puede estar "PENDIENTE" para ti (Sistemas) pero "EN_CURSO" para otra academia.
      // Aquí lo clasificamos según cómo lo ve TU academia.
      bool addedToPending = false;
      bool addedToAssigned = false;

      for (var academy in myAcademies) {
        if (!student.academies.contains(academy)) continue;

        final statusForThisAcademy = student.getStatusForAcademy(academy);

        // Usamos banderas (addedTo...) para no duplicar al alumno visualmente
        // si el usuario gestiona 2 academias y en ambas tiene el mismo estatus.
        switch (statusForThisAcademy) {
          case 'PRE_REGISTRO':
          case 'PENDIENTE_ASIGNACION':
            if (!addedToPending) {
              _pendingStudents.add(student);
              addedToPending = true;
            }
            break;
          case 'EN_CURSO':
            if (!addedToAssigned) {
              _assignedStudents.add(student);
              addedToAssigned = true;
            }
            break;
          case 'ACREDITADO':
            if (!_accreditedStudents.contains(student)) _accreditedStudents.add(student);
            break;
          case 'NO_ACREDITADO':
            if (!_notAccreditedStudents.contains(student)) _notAccreditedStudents.add(student);
            break;
        }
      }
    }
  }

  Future<void> _loadSubjects() async {
    final Set<String> searchTerms = {};
    for (var academy in myAcademies) {
      searchTerms.add(academy);
      final abbreviation = _subjectAbbreviationMap.entries.firstWhere((entry) => entry.key == academy, orElse: () => const MapEntry('', '')).value;
      if (abbreviation.isNotEmpty) {
        searchTerms.add(abbreviation);
      }
    }

    if (searchTerms.isEmpty) {
      _subjects = [];
      return;
    }

    final snapshot = await _db
        .collection('subjects')
        .where('academy', whereIn: searchTerms.toList())
        .get();

    _subjects = snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList();
    _subjects.sort((a, b) => a.name.compareTo(b.name));
  }

  Future<bool> assignSubject({
    required String studentId,
    required String subjectName,
    required String professorName,
    required String schedule,
    required String salon,
  }) async {
    try {
      // Determinamos qué academia está realizando la acción
      // Si la materia pertenece a una lista de Subjects cargados, podríamos buscar su academia.
      // Por simplicidad, usamos la primera academia del usuario logueado o un default.
      String targetAcademy = 'SISTEMAS';
      if (myAcademies.isNotEmpty) {
        // Intentar encontrar la academia que corresponde a la materia seleccionada
        final subjectMatch = _subjects.firstWhere(
                (s) => s.name == subjectName,
            orElse: () => SubjectModel(id: '', name: '', academy: myAcademies.first, professors: [])
        );
        targetAcademy = subjectMatch.academy;
      }

      // 1. Crear el enrollment
      await _db.collection('enrollments').add({
        'uid': studentId,
        'subject': subjectName,
        'professor': professorName,
        'schedule': schedule,
        'salon': salon,
        'status': 'EN_CURSO',
        'academy': targetAcademy,
        'assigned_at': FieldValue.serverTimestamp(),
      });

      // 2. Actualizar el estatus ESPECÍFICO de esa academia
      // Usamos notación de punto para no sobrescribir todo el mapa.
      await _db.collection('users').doc(studentId).update({
        'academy_status.$targetAcademy': 'EN_CURSO',
      });

      // 3. --- VERIFICACIÓN GLOBAL ---
      // Obtenemos el alumno actualizado para ver sus otros estatus
      final studentDoc = await _db.collection('users').doc(studentId).get();
      final updatedStudent = UserModel.fromMap(studentDoc.data()!, studentId);

      // Verificamos si TODAS las academias que debe cursar ya están en 'EN_CURSO' (o superior)
      bool allAcademiesReady = true;
      for (var academy in updatedStudent.academies) {
        final status = updatedStudent.getStatusForAcademy(academy);
        // Si alguna academia sigue en pendiente, NO actualizamos el global
        if (status == 'PENDIENTE_ASIGNACION' || status == 'PRE_REGISTRO') {
          allAcademiesReady = false;
          break;
        }
      }

      // Solo si todas están listas, cambiamos el estatus global visual
      if (allAcademiesReady) {
        await _db.collection('users').doc(studentId).update({
          'status': 'EN_CURSO'
        });
      }

      await loadInitialData();
      return true;
    } catch (e) {
      _errorMessage = "Error asignando: $e";
      notifyListeners();
      return false;
    }
  }
}