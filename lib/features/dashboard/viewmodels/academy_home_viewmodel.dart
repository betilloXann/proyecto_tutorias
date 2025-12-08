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

        if (studentSubjectsNormalized.contains(subjectNameNormalized)) {
          return true;
        }

        final upperCaseSubjectName = subject.name.toUpperCase();
        final abbreviation = _subjectAbbreviationMap[upperCaseSubjectName];
        if (abbreviation != null && studentSubjectsNormalized.contains(abbreviation.toLowerCase())) {
          return true;
        }

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

      // --- FIX: Clasificar basado en el estatus de LA ACADEMIA ACTUAL ---
      // Revisamos el estatus del alumno para cada academia que gestiona el usuario logueado.
      bool addedToPending = false;
      bool addedToAssigned = false;
      bool addedToAccredited = false;
      bool addedToNotAccredited = false;

      for (var academy in myAcademies) {
        // Obtenemos el estatus específico para esta academia
        // Si el alumno no tiene esa academia registrada (raro por el query), ignoramos.
        if (!student.academies.contains(academy)) continue;

        final statusForThisAcademy = student.getStatusForAcademy(academy);

        switch (statusForThisAcademy) {
          case 'PRE_REGISTRO':
          case 'PENDIENTE_ASIGNACION':
            if (!addedToPending) {
              _pendingStudents.add(student);
              addedToPending = true; // Evitar duplicados si gestiono 2 academias y en ambas es pendiente
            }
            break;
          case 'EN_CURSO':
            if (!addedToAssigned) {
              _assignedStudents.add(student);
              addedToAssigned = true;
            }
            break;
          case 'ACREDITADO':
            if (!addedToAccredited) {
              _accreditedStudents.add(student);
              addedToAccredited = true;
            }
            break;
          case 'NO_ACREDITADO':
            if (!addedToNotAccredited) {
              _notAccreditedStudents.add(student);
              addedToNotAccredited = true;
            }
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
      final targetAcademy = myAcademies.isNotEmpty ? myAcademies.first : 'SISTEMAS';

      // 1. Crear el registro de enrollment
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

      // 2. --- FIX: Actualizar SOLO el estatus de esta academia en el mapa ---
      // Usamos la notación de punto de Firestore para actualizar una clave específica del mapa
      await _db.collection('users').doc(studentId).update({
        'academy_status.$targetAcademy': 'EN_CURSO',
        // Opcional: Si queremos mantener el 'status' global como un "resumen",
        // podríamos dejarlo o actualizarlo a 'EN_CURSO' solo si estaba en 'PENDIENTE'.
        // Por seguridad, dejemos de depender del global para la lógica crítica.
        'status': 'EN_CURSO' // Se mantiene por compatibilidad visual global, pero la lógica real usa el mapa.
      });

      await loadInitialData();
      return true;
    } catch (e) {
      _errorMessage = "Error asignando: $e";
      notifyListeners();
      return false;
    }
  }
}